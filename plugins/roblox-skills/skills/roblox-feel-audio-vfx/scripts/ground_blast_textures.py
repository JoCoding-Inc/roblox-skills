#!/usr/bin/env python3
"""Textures for ground_blast.luau (roblox-feel-audio-vfx section 3g): 15 PNG files, all procedural.

  python3 -I ground_blast_textures.py <outDir> [name ...] [--preview]

Upload the files to your own account or group as Images and put the ids into fx_own_textures.luau.
Every file is white on alpha (greyscale): the effect's colour tints it. The fire pieces have a wide luminance
range, about 0.08 at the cool rim and 1 in the hottest part: in the engine one deep red-orange tint with
ParticleEmitter.Brightness 3-6 clips the bright texels to yellow, leaves the middle orange and the rim red, so one
sprite carries the three bands of a fire. --preview also writes <outDir>/preview.jpg, the banded sheets drawn the
way the engine draws them (clip(tint x luminance x Brightness) added over a dark floor colour).

  hot_fire_a, hot_fire_b  4x4 flipbooks (256 px frames) of a fire lump from a small 2D fluid simulation: it rolls,
                          splits into lobes and is eaten from its cool parts. Grid4x4, played once over the life.
  sim_smoke               4x4 flipbook of a smoke puff from the same simulation (tinted red behind the fire, near
                          black for the smoke bits).
  lick                    4x4 of 16 different single flame tongues. One random cell per particle; a flame is 5-8
                          of them alive at once, never one.
  crackle                 2x2 of 4 webs of thin broken lines (512 px each): the hot cracks over a reddening fire.
  flecks                  2x2 of 4 scatters of small chips (512 px each): what is left when the fire breaks up.
  blades                  one fan of 6 fat bent blades, root at the bottom centre (512 px): the flash.
  cracks                  forked cracks running out from the middle (1024 px): the glowing floor afterwards.
  streaks                 a sheet of thin streaks (512 px): the swirl when the place has no swirl mesh, and the
                          thin floor lines after the burst.
  swirl_disc              thin spiral streaks on a disc (1024 px): the spinning floor disc.
  trail                   a soft comet trail (256 px): ejecta arcs and the streak that climbs out of the top.
  scorch, shock_ring, spark   the dark patch, the thin grey ring, the spark streak.
  swirl_streaks           streaks for the swirl MESH (512 x 1024, tail at the top, head at the bottom). Its RGB
                          carries the pattern too and never goes below 0.5: a SurfaceAppearance emissive mask reads
                          the colour channels, not alpha, and a near-black colour map draws as a black band.

Seeded: the same call gives the same files (checked with Python 3.14, numpy 2.5, scipy, Pillow 12).
Needs numpy, scipy and Pillow. The whole set took about 8 seconds on a laptop.
"""
import sys
import warnings
import numpy as np
from PIL import Image, ImageDraw, ImageFilter
from scipy import ndimage


def sstep(e0, e1, x):
    t = np.clip((x - e0) / (e1 - e0), 0, 1)
    return t * t * (3 - 2 * t)


def pack(cells, grid):
    """cells: (luminance, alpha) float arrays of one size -> an RGBA sheet of grid x grid cells, each with a clear
    2 px border so neighbours never bleed."""
    n = cells[0][0].shape[0]
    img = np.zeros((n * grid, n * grid, 4), np.uint8)
    for i, (lum, alpha) in enumerate(cells):
        y, x = (i // grid) * n, (i % grid) * n
        a = alpha.copy()
        a[:2, :] = 0; a[-2:, :] = 0; a[:, :2] = 0; a[:, -2:] = 0
        c = np.clip(lum * 255, 0, 255).astype(np.uint8)
        for ch in range(3):
            img[y : y + n, x : x + n, ch] = c
        img[y : y + n, x : x + n, 3] = np.clip(a * 255, 0, 255).astype(np.uint8)
    return Image.fromarray(img, "RGBA")


def single(lum, alpha):
    c = np.clip(lum * 255, 0, 255).astype(np.uint8)
    a = np.clip(alpha * 255, 0, 255).astype(np.uint8)
    return Image.fromarray(np.dstack([c, c, c, a]), "RGBA")


# ---------------------------------------------------------------------------------------------------------------
# Fire and smoke flipbooks: stable fluids with an FFT projection and vorticity confinement, 256 px, wrapped.
# Why a simulation: drawn or noise-built puffs keep one outline that only swells; a simulated lump rolls, splits
# and tears.
N = 256
GRID = 4
T = GRID * GRID
# scipy suggests another edge mode for the wrapped noise below; that would change the sheets
warnings.filterwarnings("ignore", message="It is recommended to use mode")


def wrap_noise(seed, base, octaves=4, gain=0.5):
    rng = np.random.default_rng(seed)
    out = np.zeros((N, N), np.float32)
    amp, tot = 1.0, 0.0
    for o in range(octaves):
        g = base * 2 ** o
        grid = rng.random((g, g)).astype(np.float32)
        out += amp * ndimage.zoom(grid, N / g, order=3, mode="wrap", grid_mode=True)[:N, :N]
        tot += amp
        amp *= gain
    out /= tot
    lo, hi = np.percentile(out, 1), np.percentile(out, 99)
    return np.clip((out - lo) / (hi - lo), 0, 1)


class Fluid:
    def __init__(self):
        self.u = np.zeros((N, N), np.float32)  # x velocity, cells per step
        self.v = np.zeros((N, N), np.float32)  # y velocity (y grows downward in the image)
        k = np.fft.fftfreq(N) * 2 * np.pi
        self.kx, self.ky = np.meshgrid(k, k)
        self.k2 = self.kx ** 2 + self.ky ** 2
        self.k2[0, 0] = 1
        self.yy, self.xx = np.mgrid[0:N, 0:N].astype(np.float32)

    def advect(self, f, u, v):
        return ndimage.map_coordinates(f, [self.yy - v, self.xx - u], order=1, mode="wrap")

    def project(self, source):
        """Gives the velocity the divergence `source` (hot gas that expands) and removes the rest."""
        U, V = np.fft.fft2(self.u), np.fft.fft2(self.v)
        div = 1j * self.kx * U + 1j * self.ky * V - np.fft.fft2(source)
        p = div / (-self.k2)
        p[0, 0] = 0
        self.u = np.real(np.fft.ifft2(U - 1j * self.kx * p)).astype(np.float32)
        self.v = np.real(np.fft.ifft2(V - 1j * self.ky * p)).astype(np.float32)

    def confine(self, eps):
        w = np.gradient(self.v, axis=1) - np.gradient(self.u, axis=0)
        a = np.abs(w)
        gy, gx = np.gradient(a)
        m = np.sqrt(gx * gx + gy * gy) + 1e-5
        self.u += eps * (gy / m) * w
        self.v += -eps * (gx / m) * w


def curl_field(seed, base, speed):
    """A divergence-free random field whose 99th percentile speed is `speed` cells per step."""
    psi = wrap_noise(seed, base, 3) - 0.5
    gy, gx = np.gradient(psi)
    m = np.percentile(np.sqrt(gx * gx + gy * gy), 99) + 1e-9
    return (gy / m * speed).astype(np.float32), (-gx / m * speed).astype(np.float32)


def shade(den):
    """A soft light from the upper left on the density, 0..1: gives smoke lumps a lit side and a dark side."""
    b = ndimage.gaussian_filter(den, 2.5)
    gy, gx = np.gradient(b)
    return np.clip(0.5 - (gx * 0.6 + gy * 0.8) * 9, 0, 1)


PARAMS = {
    #         blobs  r0     expand tau  buoy   conf  cool0  cool1  fade   curl0 curlN
    "smoke": (5,     0.095, 0.17,  11,  0.018, 0.8,  0.03,   0.03,  0.0010, 2.2, 0.9),
    "hot":   (7,     0.07,  0.30,  7,   0.016, 1.1,  0.0060, 0.030, 0.0016, 3.4, 1.5),
}


def burst(seed, kind, tear=0.0):
    """kind "hot": a fire lump whose luminance runs from about 0.07 at the cool rim to 1 in the hottest patches;
    kind "smoke": cooler, slower, lit from the upper left. tear: how much more of a hot lump is eaten by the end."""
    nblob, r0, expand, tau, buoy, conf, cool0, cool1, fade, curl0, curln = PARAMS[kind]
    f = Fluid()
    rng = np.random.default_rng(seed)
    cx, cy = N / 2, N * 0.52
    den = np.zeros((N, N), np.float32)
    for bi in range(nblob):
        ang, rad = rng.uniform(0, 2 * np.pi), (0 if bi == 0 else rng.uniform(0.06, 0.13) * N)
        bx, by = cx + np.cos(ang) * rad, cy + np.sin(ang) * rad * 0.8
        rr = np.sqrt((f.xx - bx) ** 2 + (f.yy - by) ** 2) / (r0 * N * rng.uniform(0.75, 1.15))
        den = np.maximum(den, sstep(1.0, 0.45, rr + (wrap_noise(seed + 20 + bi, 6, 3) - 0.5) * 0.7))
    heat = den * (0.5 + 0.5 * wrap_noise(seed + 3, 5, 3))
    if kind == "hot":  # hot patches from the first frame, not one even ball
        heat = den * (0.42 + 0.58 * wrap_noise(seed + 3, 7, 3) ** 1.3)
    cu, cv = curl_field(seed + 2, 4, curl0)
    f.u += cu * den
    f.v += cv * den
    sub = 7
    # hot: the first frames of a burst are smooth round blobs (they read as bubbles in the engine): start recording
    # two frames in, when the surface has already broken up
    pre = 16 if kind == "hot" else 0
    frames = []
    edge_fade = sstep(N * 0.5, N * 0.43, np.maximum(np.abs(f.xx - N / 2), np.abs(f.yy - N / 2)))
    step_i = 0
    for i in range(-1, T):
        t = max(i, 0) / (T - 1)
        for _ in range(sub if i >= 0 else pre):
            ts = max(step_i - pre, 0) / (T * sub)
            f.v -= buoy * heat
            f.confine(conf)
            if step_i % 6 == 0:  # fresh swirls on the surface keep it breaking up
                su, sv = curl_field(seed + 100 + step_i, 9 if step_i % 12 else 4, curln * (1.8 if step_i < 24 else 1))
                skin = np.clip(den * 2, 0, 1)
                f.u += su * skin
                f.v += sv * skin
            f.project(expand * np.exp(-step_i / tau) * heat * heat * 1.6)
            f.u, f.v = f.advect(f.u, f.u, f.v), f.advect(f.v, f.u, f.v)
            den = f.advect(den, f.u, f.v)
            heat = f.advect(heat, f.u, f.v)
            cool = cool0 + cool1 * ts
            late = sstep(0.45, 1.0, ts)
            heat = np.clip(heat - cool * (1.25 - np.clip(den, 0, 1)), 0, 1)
            den = np.clip(den - (fade + 0.02 * late) * (1.15 - heat) - 0.012 * late * late, 0, 1.5) * edge_fade
            f.u *= 0.994
            f.v *= 0.994
            step_i += 1
        if i < 0:
            continue
        d = np.clip(den, 0, 1.5)
        if kind == "smoke":
            alpha = (1 - np.exp(-d * 3.4)) * edge_fade * (1 - 0.75 * sstep(0.75, 1.0, t))
            lum = 0.3 + 0.7 * np.clip(0.55 * shade(d) + 0.45 * sstep(0.0, 0.6, heat) + 0.15 * (d - 0.5), 0, 1)
        else:
            fine = ndimage.gaussian_filter(heat, 0.8) - ndimage.gaussian_filter(heat, 5)  # the hot veins inside
            hl = ndimage.gaussian_filter(heat, 0.6)
            lum = 0.07 + 0.93 * np.clip(sstep(0.14, 0.82, hl) ** 1.4 + fine * 1.6, 0, 1)
            # a crisper rim than a soft sheet, and the lump is eaten from its cool parts instead of fading as a
            # whole: late frames are shreds
            grain = wrap_noise(seed + 77, 10, 3)
            eat = -0.25 + (0.62 + tear) * t ** 1.4
            alpha = sstep(0.07, 0.36, d) * sstep(eat, eat + 0.16, hl * 0.75 + grain * 0.45) * edge_fade
        frames.append((lum, np.clip(alpha, 0, 1)))
    return pack(frames, GRID)


# ---------------------------------------------------------------------------------------------------------------
# Piece sheets: many different pieces in one grid, one random cell per particle.
def vnoise(rng, n, base, octaves=3, gain=0.5):
    out = np.zeros((n, n), np.float32)
    amp, tot = 1.0, 0.0
    for o in range(octaves):
        g = base * 2 ** o
        grid = rng.random((g + 1, g + 1)).astype(np.float32)
        out += amp * ndimage.zoom(grid, n / (g + 1), order=3)[:n, :n]
        tot += amp
        amp *= gain
    out /= tot
    lo, hi = np.percentile(out, 1), np.percentile(out, 99)
    return np.clip((out - lo) / (hi - lo), 0, 1)


def tongue(rng, n, yy, xx, root_y, tip_y, w0, lean, grain):
    s = (root_y - yy) / (root_y - tip_y)
    amp, ph, fr = rng.uniform(0.03, 0.09), rng.uniform(0, 6.28), rng.uniform(3, 6)
    cx = 0.5 + lean * s + amp * np.sin(ph + s * fr) * np.clip(s, 0, 1)
    pw = rng.uniform(0.8, 1.35)
    w = w0 * np.clip(s / 0.16, 0, 1) ** 0.6 * np.clip(1 - s, 0, 1) ** pw + 1e-4
    dx = np.abs(xx - cx) / w + (grain - 0.5) * 0.55
    inside = (s > 0) & (s < 1)
    alpha = sstep(1.0, 0.68, dx) * sstep(0.0, 0.05, s) * inside
    lum = 0.08 + 0.92 * np.clip(np.clip(1 - dx, 0, 1) ** 1.1 * (1 - 0.72 * np.clip(s, 0, 1)) * 1.3, 0, 1)
    return lum * (alpha > 0), alpha


def lick(seed=5):
    """16 single tongues: thin, curved, tapering, hottest at the root."""
    n, grid = 256, 4
    rng = np.random.default_rng(seed)
    yy, xx = np.mgrid[0:n, 0:n].astype(np.float32) / n
    cells = []
    for i in range(grid * grid):
        grain = vnoise(rng, n, 9, 3)
        tip = rng.uniform(0.07, 0.32)
        lean = rng.uniform(-0.13, 0.13)
        lum, alpha = tongue(rng, n, yy, xx, 0.94, tip, rng.uniform(0.10, 0.17), lean, grain)
        if i % 3 == 1:  # a second, shorter tongue beside the first
            side = rng.choice([-1, 1])
            xs = xx - side * rng.uniform(0.08, 0.13)
            l2, a2 = tongue(rng, n, yy, xs, 0.94, tip + rng.uniform(0.2, 0.36), rng.uniform(0.07, 0.11), lean * 0.5, grain[::-1])
            lum, alpha = np.maximum(lum, l2), np.maximum(alpha, a2)
        if i % 4 == 2:  # a drop that has left the tip
            dy, dxo = tip - rng.uniform(0.02, 0.05), 0.5 + lean * 1.1 + rng.uniform(-0.03, 0.03)
            rr = np.sqrt(((xx - dxo) / 0.035) ** 2 + ((yy - dy) / 0.05) ** 2) + (grain - 0.5) * 0.5
            a2 = sstep(1.0, 0.6, rr)
            lum, alpha = np.maximum(lum, 0.3 * (a2 > 0)), np.maximum(alpha, a2)
        cells.append((lum, np.clip(alpha, 0, 1)))
    return pack(cells, grid)


def crackle_cell(rng, n):
    yy, xx = np.mgrid[0:n, 0:n].astype(np.float32) / n
    # jagged, not wavy: the warp is a coarse random grid sampled without smoothing
    jag = 28
    wx = ndimage.zoom(rng.random((jag, jag)).astype(np.float32), n / jag, order=1)[:n, :n] - 0.5
    wy = ndimage.zoom(rng.random((jag, jag)).astype(np.float32), n / jag, order=1)[:n, :n] - 0.5
    px, py = xx + wx * 0.05, yy + wy * 0.05
    k = 22
    sites = rng.uniform(0.08, 0.92, (k, 2)).astype(np.float32)
    d = np.sqrt((px[..., None] - sites[:, 0]) ** 2 + (py[..., None] - sites[:, 1]) ** 2)
    order = np.argsort(d, axis=-1)[..., :3]
    ds = np.take_along_axis(d, order, axis=-1)
    e = ds[..., 1] - ds[..., 0]  # 0 on the border between two cells: the lines are cell borders
    a, b = np.minimum(order[..., 0], order[..., 1]), np.maximum(order[..., 0], order[..., 1])
    keep = (rng.random((k, k)) < 0.62)[a, b].astype(np.float32)
    breaks = sstep(0.16, 0.34, vnoise(rng, n, 6, 2))  # lines come and go along their length
    core = sstep(0.0075, 0.0015, e) * keep * breaks
    halo = sstep(0.022, 0.0, e) * keep * breaks
    node = sstep(0.03, 0.0, ds[..., 2] - ds[..., 0]) * keep * (rng.random((k,))[order[..., 0]] < 0.5)
    r = np.sqrt((xx - 0.5) ** 2 + (yy - 0.5) ** 2)
    patch = sstep(0.47, 0.26, r + (vnoise(rng, n, 4, 2) - 0.5) * 0.3)
    alpha = ndimage.gaussian_filter(np.clip(np.maximum(np.maximum(core, halo * 0.4), node * 0.9), 0, 1), 0.7) * patch
    lum = np.clip(np.maximum(core, node) + 0.28 * halo, 0.1, 1)
    return lum, alpha


def crackle(seed=19):
    rng = np.random.default_rng(seed)
    return pack([crackle_cell(rng, 512) for _ in range(4)], 2)


def flecks_cell(rng, n):
    ss = 2
    im = Image.new("L", (n * ss, n * ss), 0)
    dr = ImageDraw.Draw(im)
    flow = rng.uniform(0, np.pi)
    for _ in range(int(rng.integers(38, 54))):
        r, a = abs(rng.normal(0, 0.17)), rng.uniform(0, 2 * np.pi)
        if r > 0.42:
            continue
        cx, cy = (0.5 + r * np.cos(a)) * n * ss, (0.5 + r * np.sin(a)) * n * ss
        ln, wd = rng.uniform(7, 30) * ss, rng.uniform(3.5, 10) * ss
        th = flow + rng.normal(0, 0.7)
        ux, uy = np.cos(th), np.sin(th)
        pts = []
        for sx, sy in ((-1, -0.2), (-0.3, -1), (1, -0.5), (0.7, 0.8), (-0.4, 1)):  # an uneven five-sided chip
            jx, jy = rng.uniform(0.35, 1.0), rng.uniform(0.3, 1.0)
            pts.append((cx + sx * ln / 2 * jx * ux - sy * wd / 2 * jy * uy, cy + sx * ln / 2 * jx * uy + sy * wd / 2 * jy * ux))
        dr.polygon(pts, fill=int(rng.uniform(150, 255)))
    chips = np.asarray(im.filter(ImageFilter.GaussianBlur(ss * 0.8)).resize((n, n), Image.LANCZOS), np.float32) / 255
    gy, gx = np.mgrid[0:n, 0:n].astype(np.float32)
    chips = ndimage.map_coordinates(chips, [gy + (vnoise(rng, n, 24, 2) - 0.5) * 14, gx + (vnoise(rng, n, 24, 2) - 0.5) * 14], order=1)
    halo = ndimage.gaussian_filter(chips, 5)
    alpha = np.clip(np.maximum(chips * 1.15, halo * 1.6), 0, 1)
    lum = np.clip(0.1 + chips * 1.1 + halo * 0.5, 0, 1)
    return lum, alpha


def flecks(seed=43):
    rng = np.random.default_rng(seed)
    return pack([flecks_cell(rng, 512) for _ in range(4)], 2)


def blades(seed=71, n=512):
    """Hot down the middle of each blade, cooler at its edge."""
    rng = np.random.default_rng(seed)
    yy, xx = np.mgrid[0:n, 0:n].astype(np.float32) / n
    px, py = xx - 0.5, 0.95 - yy  # root at the bottom centre, +y up
    lum, alpha = np.zeros_like(xx), np.zeros_like(xx)
    k = 6
    for th in np.linspace(-1.15, 1.15, k) + rng.uniform(-0.12, 0.12, k):
        ln = rng.uniform(0.5, 0.92) * (0.6 + 0.4 * np.cos(th))
        w0 = rng.uniform(0.045, 0.08)
        bend = rng.uniform(-0.5, 0.5)
        dx, dy = np.sin(th), np.cos(th)
        sl = px * dx + py * dy
        q = (-px * dy + py * dx) + bend * sl * sl
        u = np.clip(sl / ln, 0, 1)
        w = w0 * (1 - u) ** 0.75 * np.clip(sl / 0.05 + 0.45, 0, 1) + 1e-4
        d = np.abs(q) / w
        a = sstep(1.0, 0.8, d) * (sl > 0) * (sl < ln)
        l = (0.22 + 0.78 * np.clip(1 - d, 0, 1) ** 0.8 * (1 - 0.45 * u)) * (a > 0)
        lum, alpha = np.maximum(lum, l), np.maximum(alpha, a)
    root = sstep(0.07, 0.03, np.sqrt(px * px + py * py))
    lum, alpha = np.maximum(lum, root), np.maximum(alpha, root)
    return pack([(lum, alpha)], 1)


def cracks(seed=83, n=1024):
    rng = np.random.default_rng(seed)
    ss = 2
    core, wide = Image.new("L", (n * ss, n * ss), 0), Image.new("L", (n * ss, n * ss), 0)
    dc, dw = ImageDraw.Draw(core), ImageDraw.Draw(wide)

    def walk(x, y, a, length, w, depth):
        steps = int(rng.integers(5, 9))
        for i in range(steps):
            a += rng.uniform(-0.55, 0.55)
            st = length / steps * rng.uniform(0.7, 1.3)
            nx, ny = x + np.cos(a) * st, y + np.sin(a) * st
            wi = max(w * (1 - i / steps) ** 0.8, 2.4)
            dc.line([(x * ss, y * ss), (nx * ss, ny * ss)], fill=255, width=max(int(wi * ss), 1))
            dw.line([(x * ss, y * ss), (nx * ss, ny * ss)], fill=255, width=max(int(wi * ss * 3.2), 2))
            if depth < 1 and rng.random() < 0.34:
                walk(nx, ny, a + rng.choice([-1, 1]) * rng.uniform(0.5, 1.1), length * (1 - i / steps) * 0.55 + 0.03 * n, wi * 0.75, depth + 1)
            x, y = nx, ny

    k = 11
    for th in np.linspace(0, 2 * np.pi, k, endpoint=False) + rng.uniform(-0.2, 0.2, k):
        r0 = rng.uniform(0.0, 0.03) * n
        walk(n / 2 + np.cos(th) * r0, n / 2 + np.sin(th) * r0, th, rng.uniform(0.2, 0.42) * n, rng.uniform(8, 15), 0)
    c = np.asarray(core.filter(ImageFilter.GaussianBlur(ss * 0.6)).resize((n, n), Image.LANCZOS), np.float32) / 255
    w = np.asarray(wide.filter(ImageFilter.GaussianBlur(ss * 2.5)).resize((n, n), Image.LANCZOS), np.float32) / 255
    alpha = np.clip(np.maximum(c, w * 0.75), 0, 1)
    lum = np.clip(0.16 + 0.84 * c + 0.12 * w, 0, 1)
    return pack([(lum, alpha)], 1)


def swirl_streaks(seed=97, w=512, h=1024):
    rng = np.random.default_rng(seed)
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
    v, u = 1 - yy / h, xx / w          # v = 0 at the head (bottom of the image), 1 at the tail (top)
    wob = (ndimage.zoom(rng.random((9, 4)).astype(np.float32), (h / 9, w / 4), order=3)[:h, :w] - 0.5) * 0.05
    lum, alpha = np.zeros((h, w), np.float32), np.zeros((h, w), np.float32)
    for i in range(46):
        broad = i < 7
        u0 = rng.uniform(0.04, 0.96)
        wd = rng.uniform(0.05, 0.11) if broad else rng.uniform(0.006, 0.028)
        v0 = rng.uniform(0.0, 0.3)                       # where the streak's head sits
        ln = rng.uniform(0.35, 0.7) if broad else rng.uniform(0.2, 0.75)
        t = (v - v0) / ln                                # 0 at the streak's head, 1 at its tail
        inside = (t > 0) & (t < 1)
        taper = np.clip(1 - t, 0, 1) ** 0.7 * np.clip(t / 0.04, 0, 1)
        d = np.abs(u + wob - u0) / (wd * (0.35 + 0.65 * taper) + 1e-4)
        a = sstep(1.0, 0.72, d) * inside * np.clip(taper * 3, 0, 1)
        # never dark: the mesh is also drawn with the scene's light, and a streak whose colour map is near black
        # shows as a black band. The tail leaves through alpha.
        l = (0.5 + 0.5 * np.clip(1 - t, 0, 1) ** 1.6) * (0.8 + 0.2 * np.clip(1 - d, 0, 1)) * (0.8 if broad else 1.0)
        lum, alpha = np.maximum(lum, l * (a > 0.02)), np.maximum(alpha, a)
    edge = sstep(0.0, 0.03, u) * sstep(1.0, 0.97, u) * sstep(0.0, 0.02, v) * sstep(1.0, 0.94, v)
    alpha *= edge
    img = np.zeros((h, w, 4), np.uint8)
    for ch in range(3):
        img[..., ch] = np.clip(lum * 255, 0, 255)
    img[..., 3] = np.clip(alpha * 255, 0, 255)
    return Image.fromarray(img, "RGBA")


# ---------------------------------------------------------------------------------------------------------------
# Single shapes.
def fbm2(shape, seed, base=3, octaves=5, gain=0.5):
    """Smooth value noise in 0..1 over (H, W)."""
    shape3, base3 = (1,) + tuple(shape), (1, base, base)
    rng = np.random.default_rng(seed)
    out = np.zeros(shape3, np.float32)
    amp, tot = 1.0, 0.0
    for o in range(octaves):
        g = tuple(min(s, b * 2 ** o) + 3 for s, b in zip(shape3, base3))
        grid = rng.random(g).astype(np.float32)
        z = ndimage.zoom(grid, [s / (gg - 3) for s, gg in zip(shape3, g)], order=3, mode="nearest", grid_mode=False)
        out += amp * z[: shape3[0], : shape3[1], : shape3[2]]
        tot += amp
        amp *= gain
    out /= tot
    lo, hi = np.percentile(out, 1), np.percentile(out, 99)
    return np.clip((out - lo) / (hi - lo), 0, 1)[0]


def uv(n):
    y, x = np.mgrid[0:n, 0:n].astype(np.float32)
    return (x + 0.5) / n * 2 - 1, 1 - (y + 0.5) / n  # u: -1 left .. 1 right, v: 0 bottom .. 1 top


def ang_noise(th, seed, lo=2, hi=14, falloff=0.75):
    """Periodic noise over an angle, 0..1."""
    rng = np.random.default_rng(seed)
    out = np.zeros_like(th)
    tot = 0.0
    for m in range(lo, hi + 1):
        a = 1.0 / (m - lo + 1) ** falloff
        out += a * np.sin(m * th + rng.uniform(0, 2 * np.pi))
        tot += a
    return np.clip(0.5 + out / tot * 1.4, 0, 1)


def scorch(seed=3, n=512):
    y, x = np.mgrid[0:n, 0:n].astype(np.float32)
    u, v = (x + 0.5) / n * 2 - 1, (y + 0.5) / n * 2 - 1
    r = np.sqrt(u * u + v * v)
    streak = ang_noise(np.arctan2(v, u), seed, 2, 12)
    blot = fbm2((n, n), seed + 1, base=4, octaves=5)
    d = 1 - r / (0.62 + 0.34 * streak) + (blot - 0.5) * 0.55
    alpha = sstep(0.0, 0.5, d) * (0.65 + 0.35 * blot) * sstep(1.0, 0.9, r)
    return single(np.ones_like(alpha), alpha)


def shock_ring(seed=5, n=512):
    """A thin broken ring with a soft trailing edge."""
    y, x = np.mgrid[0:n, 0:n].astype(np.float32)
    u, v = (x + 0.5) / n * 2 - 1, (y + 0.5) / n * 2 - 1
    r = np.sqrt(u * u + v * v)
    brk = ang_noise(np.arctan2(v, u), seed, 5, 40, 0.4)
    lead = sstep(0.93, 0.9, r) * sstep(0.84, 0.9, r)  # the bright front
    trail_ = sstep(0.5, 0.9, r) ** 3 * sstep(0.93, 0.9, r) * 0.45  # dust behind it
    alpha = np.clip(lead * (0.45 + 0.75 * brk) + trail_ * (0.4 + 0.9 * brk), 0, 1)
    return single(np.clip(0.6 + 0.4 * lead, 0, 1), alpha)


def spark(n=256):
    u, v = uv(n)
    width = 0.012 + 0.06 * v ** 2.2
    d = 1 - np.abs(u) / width
    alpha = sstep(0.0, 0.6, d) * sstep(0.0, 0.25, v) * sstep(1.0, 0.94, v)
    return single(0.6 + 0.4 * sstep(0.6, 0.95, v), alpha)


def streaks(seed=31, n=512):
    """72 thin streaks crowded toward one edge of a tapered sheet, on a faint fill."""
    rng = np.random.default_rng(seed)
    u, v = uv(n)
    y = 1 - v
    taper = np.sin(np.pi * np.clip(y, 0, 1)) ** 0.5
    acc = np.zeros_like(u)
    for _ in range(72):
        u0 = 0.9 - 1.7 * rng.random() ** 1.5  # crowded toward the outer edge
        y1 = rng.uniform(0.45, 0.98)
        ln = rng.uniform(0.25, 0.9)
        w = rng.uniform(0.008, 0.035) * (1.6 if rng.random() < 0.2 else 1)
        k = rng.uniform(0.5, 1.0)
        uc = u0 * (0.35 + 0.65 * taper) + 0.03 * np.sin(y * rng.uniform(4, 9) + rng.uniform(0, 6))
        along = sstep(y1 - ln, y1 - ln * 0.25, y) * sstep(y1, y1 - 0.07, y)
        acc += k * np.exp(-(((u - uc) / w) ** 2)) * along
    fill = sstep(-0.9, 0.7, u / np.maximum(taper, 0.05)) * sstep(0.95, 0.8, u / np.maximum(taper, 0.05))
    fill = fill * sstep(0.05, 0.5, y) * sstep(1.0, 0.85, y) * 0.5
    return single(np.clip(0.55 + 0.5 * acc, 0, 1), np.clip(acc * 0.9 + fill, 0, 1))


def trail(seed=27, n=256):
    """A soft comet: round head near the bottom of the image, a long tail fading toward the top."""
    u, v = uv(n)
    y = 1 - v
    noise = fbm2((256, 256), seed, base=5, octaves=4)
    m = noise.shape[0]
    grain = ndimage.map_coordinates(noise, [(1 - (y * 0.1 + 0.3)) % 1 * (m - 1), (u * 0.4 + 0.5) % 1 * (m - 1)], order=1, mode="wrap")
    hv = 0.95
    w = np.where(y < hv, 0.34 * (y / hv) ** 0.45, 0.34 * np.sqrt(np.clip(1 - ((y - hv) / (0.995 - hv)) ** 2, 0, 1)))
    core = np.exp(-(np.abs(u) / np.maximum(w, 1e-3) * 1.7) ** 2)
    halo = np.exp(-(np.abs(u) / np.maximum(w * 2.6, 1e-3)) ** 2) * 0.3
    alpha = np.clip((core + halo) * sstep(0.0, 0.5, y) ** 0.8 * (0.8 + 0.2 * grain) * sstep(1.0, 0.985, y), 0, 1)
    return single(np.clip(0.6 + 0.4 * core, 0, 1), alpha)


def swirl_disc(seed=37, n=1024):
    rng = np.random.default_rng(seed)
    y, x = np.mgrid[0:n, 0:n].astype(np.float32)
    u, v = (x + 0.5) / n * 2 - 1, (y + 0.5) / n * 2 - 1
    r = np.sqrt(u * u + v * v)
    th = np.arctan2(v, u)
    acc = np.zeros_like(r)
    for _ in range(90):
        th0 = rng.uniform(0, 2 * np.pi)
        r0 = 0.25 + 0.68 * rng.random() ** 0.7
        span = rng.uniform(0.7, 3.2)
        pitch = rng.uniform(0.01, 0.05)
        w = rng.uniform(0.004, 0.016) * (2 if rng.random() < 0.15 else 1)
        k = rng.uniform(0.5, 1.0)
        dth = np.mod(th - th0, 2 * np.pi)
        along = sstep(0.0, span * 0.7, dth) * sstep(span, span - 0.06, dth)
        acc += k * np.exp(-(((r - (r0 + pitch * dth)) / w) ** 2)) * along
    haze = sstep(0.3, 0.7, r) * sstep(0.97, 0.8, r) * 0.12
    alpha = np.clip(acc * 0.95 + haze, 0, 1) * sstep(0.99, 0.94, r)
    return single(np.clip(0.55 + 0.5 * acc, 0, 1), alpha)


JOBS = {
    "lick": lick, "crackle": crackle, "flecks": flecks, "blades": blades, "cracks": cracks,
    "streaks": streaks, "swirl_disc": swirl_disc, "trail": trail, "scorch": scorch, "shock_ring": shock_ring,
    "spark": spark, "swirl_streaks": swirl_streaks,
    "hot_fire_a": lambda: burst(311, "hot"),
    "hot_fire_b": lambda: burst(523, "hot", 0.04),
    "sim_smoke": lambda: burst(57, "smoke"),
}


def preview(out_dir, names=("hot_fire_a", "lick", "crackle", "flecks", "blades", "cracks"), tint=(1.0, 0.22, 0.03), bright=4.0):
    """The banded sheets as the engine draws them at LightEmission 1: clip(tint x luminance x Brightness), added
    over a dark floor colour. Look here before uploading: yellow only in the hottest parts, red at the rims."""
    floor = np.array([30, 36, 52], np.float32)
    cells = []
    for name in names:
        im = np.asarray(Image.open(f"{out_dir}/{name}.png").convert("RGBA").resize((768, 768), Image.LANCZOS), np.float32) / 255
        col = np.clip(np.array(tint, np.float32) * im[..., 0:1] * bright, 0, 1) * 255
        cells.append(Image.fromarray(np.clip(floor + col * im[..., 3:4], 0, 255).astype(np.uint8)))
    sheet = Image.new("RGB", (768 * 3, 768 * 2))
    for i, c in enumerate(cells):
        sheet.paste(c, ((i % 3) * 768, (i // 3) * 768))
    sheet.save(f"{out_dir}/preview.jpg", quality=88)
    print("preview", sheet.size)


if __name__ == "__main__":
    args = [a for a in sys.argv[1:] if a != "--preview"]
    out, only = args[0], args[1:]
    for name, fn in JOBS.items():
        if only and name not in only:
            continue
        img = fn()
        img.save(f"{out}/{name}.png")
        print(name, img.size)
    if "--preview" in sys.argv:
        preview(out)
