#!/usr/bin/env python3
"""ground_slam_textures: the five smoke flipbooks of ground_slam (roblox-feel-audio-vfx section 3h).

  python3 ground_slam_textures.py <outDir> [name ...] [--preview]

Cartoon smoke that erodes: one cloud silhouette with soft shading, eaten away along a ridged noise mask. The
erosion is baked into the frames because a ParticleEmitter can only fade a whole sprite (Transparency); it cannot
open holes in it. A puff that keeps its place and breaks into C-curls and rings is a flipbook played once over the
particle's life. How each frame is made:
  silhouette  a smooth union of 10-14 round lobes (p-norm of radial falloffs): one cloud outline, no inner outlines
  shading     the union's height field lit from the upper left, darker toward the bottom and at eroding edges
              (so no frame is one flat tone); greyscale, the emitter's Color tints it
  erosion     survival = a ridged smooth noise (high along closed curves) mixed with a little of the height,
              rank-normalised inside the silhouette; alpha = step(threshold(t), survival), and the threshold
              sweeps from 0 to 1 between frame 3 and the last: what is left at the end are the ridges, which are
              curls and rings
  edge        alpha fades to 0 before the cell border (a sheet that reaches it draws hard rectangle edges)
White on alpha: 4x4 frames of 256 px (FlipbookLayout Grid4x4, FlipbookMode OneShot). Seeded: the same files
every run.
  slam_puff_a, slam_puff_b   round dark puffs
  slam_plume                 taller, small lobes on its rim, thins from the top
  slam_wisp_a, slam_wisp_b   pale swirling haze (soft edges, eroded from the first frames)
--preview writes preview.jpg: every sheet over a sky and floor colour in the tint the effect uses. Look at it
before uploading: the first frames are whole clouds, the middle ones have holes, the last are thin curls.
Upload the PNG files as Images to your own account or group (uploads are permanent) and put the ids into
fx_own_textures. Needs numpy, scipy, Pillow.
"""
import sys
import numpy as np
from PIL import Image
from scipy.ndimage import gaussian_filter

N, GRID = 256, 4
T = GRID * GRID
yy, xx = np.mgrid[0:N, 0:N].astype(np.float32) / N


def sstep(e0, e1, x):
    t = np.clip((x - e0) / (e1 - e0 + 1e-9), 0, 1)
    return t * t * (3 - 2 * t)


def noise(rng, sigma, size=N * 2):
    """Smooth noise in 0..1 (flat histogram), on a field twice the frame so it can be scrolled and warped."""
    f = gaussian_filter(rng.standard_normal((size, size)).astype(np.float32), sigma, mode="wrap")
    r = np.argsort(np.argsort(f.ravel())).reshape(f.shape).astype(np.float32)
    return r / (r.size - 1)


def sample(field, x, y):
    """Bilinear lookup of a wrapping field at frame coordinates (0..1 spans half the field)."""
    s = field.shape[0]
    fx, fy = (x * N) % s, (y * N) % s
    x0, y0 = np.floor(fx).astype(int), np.floor(fy).astype(int)
    tx, ty = fx - x0, fy - y0
    x1, y1 = (x0 + 1) % s, (y0 + 1) % s
    return (field[y0, x0] * (1 - tx) + field[y0, x1] * tx) * (1 - ty) + (field[y1, x0] * (1 - tx) + field[y1, x1] * tx) * ty


def flat(v, inside):
    """Rank-normalise inside the silhouette to 0..1, so a threshold at x removes the share x of the puff."""
    out = np.zeros_like(v)
    vals = v[inside]
    if vals.size > 1:
        out[inside] = np.argsort(np.argsort(vals)).astype(np.float32) / (vals.size - 1)
    return out


def pack(cells):
    img = np.zeros((N * GRID, N * GRID, 4), np.uint8)
    for i, (lum, alpha) in enumerate(cells):
        y, x = (i // GRID) * N, (i % GRID) * N
        a = alpha.copy()
        a[:3, :] = 0; a[-3:, :] = 0; a[:, :3] = 0; a[:, -3:] = 0
        c = np.clip(lum * 255, 0, 255).astype(np.uint8)
        for ch in range(3):
            img[y : y + N, x : x + N, ch] = c
        img[y : y + N, x : x + N, 3] = np.clip(a * 255, 0, 255).astype(np.uint8)
    return Image.fromarray(img, "RGBA")


def smoke(seed, kind="puff"):
    rng = np.random.default_rng(seed)
    tall = 1.5 if kind == "plume" else 1.0
    wisp = kind == "wisp"
    c0 = np.array([0.5, 0.52 if tall == 1.0 else 0.56], np.float32)
    L = int(rng.integers(10, 15)) if not wisp else int(rng.integers(5, 8))
    lobes = []
    for i in range(L):
        ang = rng.uniform(0, 2 * np.pi)
        dist = 0.0 if i == 0 else rng.uniform(0.08, 0.22 if not wisp else 0.15) * (0.6 if i < 4 else 1.0) * (0.85 if tall > 1 else 1.0)
        off = np.array([np.cos(ang) * dist / tall, np.sin(ang) * dist * tall], np.float32)
        r = (0.21 if i == 0 else rng.uniform(0.085, 0.155)) * (1.6 if wisp else 1.0)
        if tall > 1 and off[1] < 0:
            r *= 1 - 0.35 * min(1.0, -off[1] / 0.25)      # a plume narrows toward the top
        lobes.append((off, r, rng.uniform(0.0, 0.1) if i > 3 else 0.0))
    if tall > 1:
        # small lobes on the rims of the big ones: without them a plume's first frames are two or three plain balls
        rng2 = np.random.default_rng(seed + 1000)
        for off, r, birth in list(lobes):
            for _ in range(3):
                ang = rng2.uniform(0, 2 * np.pi)
                o2 = off + np.array([np.cos(ang), np.sin(ang)], np.float32) * r * rng2.uniform(0.6, 0.9)
                lobes.append((o2, r * rng2.uniform(0.38, 0.6), birth))
    n_lo = noise(rng, 14)      # the erosion pattern: 2-3 features across the frame
    n_hi = noise(rng, 6)       # its small breakup
    n_warp = noise(rng, 22)
    swirl = rng.choice([-1.0, 1.0]) * (2.4 if wisp else 0.9)
    ph = rng.uniform(0, 1, 4)
    cells = []
    for f in range(T):
        t = f / (T - 1)
        pop = 1 - (1 - min(t / 0.22, 1.0)) ** 3
        scale = (0.72 + 0.28 * pop) * (1 + 0.12 * t)
        spread = 0.8 + 0.2 * pop + 0.1 * t
        # silhouette and height: p-norm union of the lobes
        acc = np.zeros((N, N), np.float32)
        for off, r, birth in lobes:
            g = sstep(birth - 0.06, birth + 0.1, t)
            cx, cy = c0 + off * spread
            d = np.sqrt((xx - cx) ** 2 + (yy - cy) ** 2) / (r * scale * (0.55 + 0.45 * g))
            acc += np.clip(1 - d, 0, 1) ** 3
        F = np.clip(acc, 0, None) ** (1 / 3)
        F = np.clip(F, 0, 1.25)
        # erosion mask in the puff's own frame, warped into a slow swirl and scrolled up a little
        dx, dy = xx - c0[0], yy - c0[1]
        rr = np.sqrt(dx * dx + dy * dy)
        a = swirl * (0.45 - rr) * (0.6 + 0.8 * t)
        ca, sa = np.cos(a), np.sin(a)
        wx, wy = c0[0] + dx * ca - dy * sa, c0[1] + dx * sa + dy * ca
        w1 = sample(n_warp, wx + ph[0], wy + ph[1]) - 0.5
        u, v = wx + 0.10 * w1, wy + 0.10 * w1 + 0.10 * t
        m = 0.72 * sample(n_lo, u + ph[2], v + ph[3]) + 0.28 * sample(n_hi, u * 1.0 + ph[0], v + ph[2] + 0.05 * t)
        ridge = 1 - np.abs(2 * m - 1)                    # high along the noise's mid contour: closed curves
        core = np.clip(F, 0, 1)
        if wisp:
            V = flat(0.9 * ridge + 0.1 * core, F > 0)
            th = 0.12 + 0.95 * t                         # already open in the first frames
            wdt = 0.14
            edge = 0.5
        else:
            V = 0.9 * ridge + 0.1 * core
            if tall > 1:
                V = V - 0.3 * np.clip((c0[1] - yy) / 0.35, -0.3, 1)          # the top goes first
            V = flat(V, F > 0)
            th = -0.06 + 1.04 * np.clip((t - 0.18) / 0.78, 0, 1) ** 0.9       # even loss of area from frame 3 on
            wdt = 0.03
            edge = 0.1
        sil = sstep(0.0, edge, F)
        keep = sstep(th - wdt, th + wdt, V)
        alpha = sil * keep
        # shading: the height lit from the upper left, darker low down and at eroding edges
        H = gaussian_filter(F, 5.0)
        gy, gx = np.gradient(H)
        light = np.clip(0.5 + (-gx * 0.6 - gy * 0.8) * 34, 0, 1)
        lum = 0.6 + 0.4 * light
        lum *= 0.80 + 0.20 * np.clip(1 - (yy - (c0[1] - 0.22)) / 0.5, 0, 1)
        lum *= 0.86 + 0.14 * sstep(0.0, 0.2, V - th)                         # a darker lip where it is being eaten
        lum *= 0.88 + 0.12 * sample(n_hi, xx + ph[1], yy + ph[3])            # faint mottling
        if wisp:
            lum = 0.72 + 0.28 * lum
            alpha = alpha * (0.95 * (1 - 0.3 * t))
        alpha = alpha * (1 - sstep(0.9, 1.0, t))
        alpha = alpha * (1 - sstep(0.38, 0.485, np.maximum(np.abs(xx - 0.5), np.abs(yy - 0.5))))   # never reach the cell edge
        alpha = gaussian_filter(alpha, 0.8 if not wisp else 2.0)
        cells.append((np.clip(lum, 0, 1), np.clip(alpha, 0, 1)))
    return pack(cells)


JOBS = {
    "slam_puff_a": lambda: smoke(7),
    "slam_puff_b": lambda: smoke(23),
    "slam_plume": lambda: smoke(41, "plume"),
    "slam_wisp_a": lambda: smoke(5, "wisp"),
    "slam_wisp_b": lambda: smoke(19, "wisp"),
}
TINT = {"puff": (150, 152, 160), "plume": (118, 120, 128), "wisp": (238, 240, 245)}


def preview(out_dir, names):
    """Frames over a sky and floor colour, tinted the way the emitter draws them."""
    rows = []
    for name in names:
        im = np.asarray(Image.open(f"{out_dir}/{name}.png").convert("RGBA"), np.float32) / 255
        bg = np.zeros((N * GRID, N * GRID, 3), np.float32)
        bg[:] = np.array([120, 160, 215], np.float32)
        for gy in range(GRID):
            bg[gy * N + int(N * 0.62) : (gy + 1) * N] = np.array([118, 124, 138], np.float32)
        col = im[..., 0:1] * np.array(TINT[name.split("_")[1]], np.float32)
        a = im[..., 3:4] * (0.8 if not "wisp" in name else 0.6)
        rows.append(Image.fromarray(np.clip(bg * (1 - a) + col * a, 0, 255).astype(np.uint8)))
    sheet = Image.new("RGB", (N * GRID * len(rows), N * GRID))
    for i, r in enumerate(rows):
        sheet.paste(r, (i * N * GRID, 0))
    sheet.save(f"{out_dir}/preview.jpg", quality=88)
    print("preview", sheet.size)


if __name__ == "__main__":
    args = [a for a in sys.argv[1:] if a != "--preview"]
    out, only = args[0], args[1:]
    for name, fn in JOBS.items():
        if only and name not in only:
            continue
        fn().save(f"{out}/{name}.png")
        print(name)
    if "--preview" in sys.argv:
        preview(out, [n for n in JOBS if not only or n in only])
