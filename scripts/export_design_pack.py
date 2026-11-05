#!/usr/bin/env python3
"""Build the design pack: design data files, their JSON Schemas, the design-related
skill sections as markdown, their images and a manifest.

  python3 -I scripts/export_design_pack.py --check
  python3 -I scripts/export_design_pack.py --out dist --version 1.0.0 --tgz

Writes <out>/design-pack/ (and <out>/design-pack.tgz plus <out>/manifest.json with --tgz).
styles.json is generated from ui_style_mock.luau PRESETS and the ui-styles README, so the
Lua file stays the single source. Stdlib only; uses the jsonschema package too when present.
"""
import argparse
import hashlib
import json
import re
import shutil
import subprocess
import sys
import tarfile
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SKILLS = ROOT / "plugins" / "roblox-skills" / "skills"
DESIGN = ROOT / "design"
MOCK = SKILLS / "roblox-game-pipeline" / "scripts" / "ui_style_mock.luau"
UI_STYLES = SKILLS / "roblox-game-pipeline" / "assets" / "ui-styles"
SCHEMA_VERSION = "1.0.0"
REPO = "https://github.com/JoCoding-Inc/roblox-skills"

PROVENANCE = {
    "measured": "we measured it: engine source, pixels on reference frames, store API reads, tested in Studio",
    "documented": "Roblox docs, staff posts or filings",
    "field": "observed while shipping a game (dated when known)",
    "opinion": "judgment, house style, owner rule or a community starting value",
}
KINDS = {
    "data": "design values, one provenance tag per value; validate with the schema named in the entry",
    "schema": "JSON Schema (draft 2020-12) for one data type",
    "guide": "design-related skill text as markdown (whole skill or the listed sections)",
    "image": "reference image used by a guide (ours or the owner's own, never third-party screenshots)",
    "license": "license and source credits of the repository",
}
# (skill, sections or None for the whole skill, topic)
GUIDES = [
    ("roblox-ui-layout", None, "layout"),
    ("roblox-ui-genre-studs", None, "stud-style"),
    ("roblox-ui-typography", None, "typography"),
    ("roblox-fun-effects", None, "effects"),
    ("roblox-store-art-pack", None, "store-art"),
    ("roblox-feel-audio-vfx", ["1", "3", "4", "5"], "vfx"),
    ("roblox-engine-2026", ["2"], "ui-engine"),
    ("roblox-game-pipeline", ["3", "6a"], "art-direction"),
    ("roblox-blender-export", ["3", "4", "6"], "mesh-art"),
]
# (folder under SKILLS, topic, section_ref): README.md becomes a guide, images become images
ASSET_DIRS = [
    ("roblox-ui-genre-studs/references", "stud-style", "roblox-ui-genre-studs/SKILL.md#9"),
    ("roblox-game-pipeline/assets/lanes", "art-direction", "roblox-game-pipeline/assets/lanes/README.md"),
    ("roblox-game-pipeline/assets/ui-styles", "ui-styles", "roblox-game-pipeline/assets/ui-styles/README.md"),
    ("roblox-game-pipeline/assets/ui-styles/icons", "ui-styles", "roblox-game-pipeline/assets/ui-styles/README.md"),
    ("roblox-game-pipeline/assets/part-looks", "art-direction", "roblox-game-pipeline/assets/part-looks/README.md"),
    ("roblox-game-pipeline/assets/examples", "store-art", "roblox-store-art-pack/SKILL.md#7"),
]
IMAGE_EXT = {".jpg", ".jpeg", ".png", ".webp"}
HEADING = re.compile(r"^## ([0-9]+[a-z]?)\. ")


# ---------- validation (subset of JSON Schema used by design/schema) ----------

def _type_ok(x, t):
    if isinstance(t, list):
        return any(_type_ok(x, i) for i in t)
    if t == "object":
        return isinstance(x, dict)
    if t == "array":
        return isinstance(x, list)
    if t == "string":
        return isinstance(x, str)
    if t == "boolean":
        return isinstance(x, bool)
    if t == "null":
        return x is None
    if isinstance(x, bool):
        return False
    if t == "integer":
        return isinstance(x, int) or (isinstance(x, float) and x.is_integer())
    if t == "number":
        return isinstance(x, (int, float))
    raise ValueError("unsupported type " + t)


def validate(x, s, root, path="$"):
    errs = []
    if "$ref" in s:
        errs += validate(x, root["$defs"][s["$ref"].rsplit("/", 1)[1]], root, path)
    for sub in s.get("allOf", []):
        errs += validate(x, sub, root, path)
    if "anyOf" in s and all(validate(x, sub, root, path) for sub in s["anyOf"]):
        errs.append(path + ": matches no allowed shape")
    if "const" in s and x != s["const"]:
        errs.append("%s: must be %r" % (path, s["const"]))
    if "enum" in s and x not in s["enum"]:
        errs.append("%s: %r not in %r" % (path, x, s["enum"]))
    if "type" in s and not _type_ok(x, s["type"]):
        return errs + ["%s: expected %s" % (path, s["type"])]
    if isinstance(x, dict):
        errs += ["%s: missing %s" % (path, r) for r in s.get("required", []) if r not in x]
        if len(x) < s.get("minProperties", 0):
            errs.append(path + ": too few properties")
        props, extra = s.get("properties", {}), s.get("additionalProperties", True)
        for k, v in x.items():
            if k in props:
                errs += validate(v, props[k], root, path + "." + k)
            elif extra is False:
                errs.append("%s: unexpected key %s" % (path, k))
            elif isinstance(extra, dict):
                errs += validate(v, extra, root, path + "." + k)
    elif isinstance(x, list):
        if len(x) < s.get("minItems", 0) or len(x) > s.get("maxItems", len(x)):
            errs.append(path + ": wrong number of items")
        if "items" in s:
            for i, v in enumerate(x):
                errs += validate(v, s["items"], root, "%s[%d]" % (path, i))
    elif isinstance(x, (int, float)) and not isinstance(x, bool):
        if x < s.get("minimum", x) or x > s.get("maximum", x):
            errs.append("%s: %r out of range" % (path, x))
    elif isinstance(x, str) and "pattern" in s and not re.search(s["pattern"], x):
        errs.append("%s: %r does not match %s" % (path, x, s["pattern"]))
    return errs


def validate_all(x, schema, label):
    errs = ["%s %s" % (label, e) for e in validate(x, schema, schema)]
    try:
        import jsonschema
    except ImportError:
        return errs
    v = jsonschema.Draft202012Validator(schema)
    return errs + ["%s (jsonschema) %s: %s" % (label, "/".join(map(str, e.absolute_path)), e.message)
                   for e in v.iter_errors(x)]


# ---------- ui_style_mock.luau PRESETS ----------

TOKEN = re.compile(r'\s*(?:(--[^\n]*)|("[^"]*")|(-?\d+(?:\.\d+)?)|([A-Za-z_][\w.]*)|(.))', re.S)


def _tokens(src):
    out, pos = [], 0
    while pos < len(src):
        m = TOKEN.match(src, pos)
        if not m or m.end() == pos:
            break
        pos = m.end()
        comment, string, number, ident, punct = m.groups()
        if comment:
            continue
        if string:
            out.append(("str", string[1:-1]))
        elif number:
            out.append(("num", float(number) if "." in number else int(number)))
        elif ident:
            out.append(("id", ident))
        elif punct and punct.strip():
            out.append(("p", punct))
    return out


class _Lua:
    def __init__(self, toks, names):
        self.t, self.i, self.names = toks, 0, names

    def next(self):
        tok = self.t[self.i]
        self.i += 1
        return tok

    def expect(self, p):
        tok = self.next()
        if tok != ("p", p):
            raise ValueError("expected %s, got %r" % (p, tok))

    def args(self):
        self.expect("(")
        out = []
        while self.t[self.i] != ("p", ")"):
            out.append(self.value())
            if self.t[self.i] == ("p", ","):
                self.i += 1
        self.expect(")")
        return out

    def value(self):
        kind, v = self.next()
        if (kind, v) == ("p", "{"):
            return self.table()
        if kind in ("str", "num"):
            return v
        if kind == "id":
            if v in ("true", "false"):
                return v == "true"
            if v == "nil":
                return None
            if v.startswith("Enum."):
                return v.rsplit(".", 1)[1]
            if v == "rgb":
                return self.args()
            if v == "Font.fromName":
                return {"family": self.args()[0]}
            if v == "Font.new":
                a = self.args()
                fam = {"family": a[0].rsplit("/", 1)[-1].replace(".json", "")}
                if len(a) > 1:
                    fam["weight"] = a[1]
                return fam
            if v in self.names:
                return self.names[v]
        raise ValueError("unsupported Lua value %r" % (v,))

    def table(self):
        keyed, items = {}, []
        while self.t[self.i] != ("p", "}"):
            if self.t[self.i] == ("p", "["):
                self.i += 1
                key = self.next()[1]
                self.expect("]")
                self.expect("=")
                keyed[key] = self.value()
            elif self.t[self.i][0] == "id" and self.t[self.i + 1] == ("p", "="):
                key = self.next()[1]
                self.i += 1
                keyed[key] = self.value()
            else:
                items.append(self.value())
            if self.t[self.i] in (("p", ","), ("p", ";")):
                self.i += 1
        self.i += 1
        return keyed if keyed else items


def parse_presets(src):
    names = {}
    for m in re.finditer(r'^local (\w+) = (Font\.fromName\("[^"]*"\))', src, re.M):
        names[m.group(1)] = _Lua(_tokens(m.group(2)), {}).value()
    start = src.index("local PRESETS = {") + len("local PRESETS = ")
    return _Lua(_tokens(src[start:]), names).value()


def style_cards():
    cards = {}
    for line in (UI_STYLES / "README.md").read_text().splitlines():
        cols = [c.strip() for c in line.split("|")]
        if len(cols) >= 9 and re.fullmatch(r"`[a-z-]+\.jpg`", cols[3]):
            cards[cols[3].strip("`")[:-4]] = {"name": cols[2], "look": cols[4], "fits": cols[5], "font_row": cols[7]}
    return cards


def build_styles():
    presets, cards = parse_presets(MOCK.read_text()), style_cards()
    out = {}
    for key, values in presets.items():
        card = cards.get(key)
        if not card:
            raise ValueError("preset %s has no row in ui-styles/README.md" % key)
        leaf = lambda v, p="opinion", src=None: dict({"v": v, "p": p}, **({"src": src} if src else {}))
        out[key] = {
            "name": leaf(card["name"]),
            "card_image": leaf("skills/roblox-game-pipeline/assets/ui-styles/%s.jpg" % key, "measured",
                               "redrawn screen of a 2025-26 hit, UI kept, content new"),
            "look": leaf(card["look"]),
            "fits": leaf(card["fits"]),
            "font_row": leaf(card["font_row"], src="roblox-ui-typography section 2"),
            "values": {k: leaf(v, src="ui_style_mock.luau, drawn to match the card") for k, v in values.items()},
        }
    return {
        "type": "styles",
        "schema_version": SCHEMA_VERSION,
        "title": "UI style presets (keys of ui_style_mock.luau PRESETS) with their style card",
        "scope": "every genre; a simulator/tycoon uses stud-chunky (tokens.json rules)",
        "sources": ["roblox-game-pipeline/scripts/ui_style_mock.luau", "roblox-game-pipeline/assets/ui-styles/README.md"],
        "data": {"presets": out},
    }


# ---------- guides ----------

def sections(text, wanted):
    lines, found, cur = text.splitlines(), {}, None
    for line in lines:
        if line.startswith("## "):
            m = HEADING.match(line)
            cur = m.group(1) if m and m.group(1) in wanted else None
            if cur:
                found[cur] = []
        if cur:
            found[cur].append(line)
    missing = [w for w in wanted if w not in found]
    if missing:
        raise ValueError("missing sections " + ", ".join(missing))
    return ["\n".join(found[w]).rstrip() for w in wanted]


def guide_text(skill, wanted):
    text = (SKILLS / skill / "SKILL.md").read_text()
    if wanted is None:
        return text
    head = "# %s (sections %s)\n\n<!-- Extracted from plugins/roblox-skills/skills/%s/SKILL.md; the other sections are not design-related. -->\n\n" % (
        skill, ", ".join(wanted), skill)
    return head + "\n\n".join(sections(text, wanted)) + "\n"


# ---------- pack ----------

def collect():
    """Return (files, errors). files: list of (pack path, bytes, manifest entry)."""
    files, errs = [], []
    schemas = {p.name[:-len(".schema.json")]: json.loads(p.read_text()) for p in sorted((DESIGN / "schema").glob("*.schema.json"))}
    common = schemas["zones"]["$defs"]
    for kind, schema in schemas.items():
        for name in ("provenance", "leaf", "node", "num", "range", "rgb", "text", "textList"):
            if schema["$defs"].get(name) != common[name]:
                errs.append("schema %s: $defs.%s differs from zones.schema.json" % (kind, name))
        files.append(("schema/%s.schema.json" % kind, (DESIGN / "schema" / ("%s.schema.json" % kind)).read_bytes(),
                      {"kind": "schema", "topic": kind, "section_ref": None}))
    data = {p.stem: (p.read_bytes(), json.loads(p.read_text())) for p in sorted((DESIGN / "data").glob("*.json"))}
    try:
        styles = build_styles()
        data["styles"] = ((json.dumps(styles, indent=2) + "\n").encode(), styles)
    except (ValueError, IndexError, KeyError) as e:
        errs.append("styles: %s" % e)
    for kind, (raw, doc) in sorted(data.items()):
        if kind not in schemas:
            errs.append("data %s: no schema/%s.schema.json" % (kind, kind))
            continue
        if doc.get("type") != kind or doc.get("schema_version") != SCHEMA_VERSION:
            errs.append("data %s: type must be %s and schema_version %s" % (kind, kind, SCHEMA_VERSION))
        errs += validate_all(doc, schemas[kind], "data " + kind)
        files.append(("data/%s.json" % kind, raw, {"kind": "data", "topic": kind, "section_ref": ", ".join(doc.get("sources", [])),
                                                   "schema": "schema/%s.schema.json" % kind}))
    for kind in schemas:
        if kind not in data:
            errs.append("schema %s: no data file" % kind)
    for skill, wanted, topic in GUIDES:
        try:
            text = guide_text(skill, wanted)
        except (OSError, ValueError) as e:
            errs.append("guide %s: %s" % (skill, e))
            continue
        ref = "%s/SKILL.md" % skill + ("#" + ",".join(wanted) if wanted else "")
        files.append(("skills/%s/SKILL.md" % skill, text.encode(), {"kind": "guide", "topic": topic, "section_ref": ref}))
    for folder, topic, ref in ASSET_DIRS:
        d = SKILLS / folder
        if not d.is_dir():
            errs.append("assets: missing " + folder)
            continue
        for p in sorted(d.iterdir()):
            if p.name == "README.md":
                files.append(("skills/%s/README.md" % folder, p.read_bytes(),
                              {"kind": "guide", "topic": topic, "section_ref": "%s/README.md" % folder}))
            elif p.suffix.lower() in IMAGE_EXT:
                files.append(("skills/%s/%s" % (folder, p.name), p.read_bytes(), {"kind": "image", "topic": topic, "section_ref": ref}))
    for name in ("LICENSE", "NOTICE.md"):
        files.append((name, (ROOT / name).read_bytes(), {"kind": "license", "topic": "license", "section_ref": None}))
    for path, raw, entry in files:
        if entry["kind"] != "image" and any(b > 127 for b in raw):
            errs.append("%s: non-ASCII bytes" % path)
    return files, errs


def git(*args):
    return subprocess.run(["git", "-C", str(ROOT)] + list(args), capture_output=True, text=True, check=True).stdout.strip()


def build(out, version, tgz):
    files, errs = collect()
    if errs:
        return errs
    pack = out / "design-pack"
    if pack.exists():
        shutil.rmtree(pack)
    entries = []
    for path, raw, entry in files:
        dest = pack / path
        dest.parent.mkdir(parents=True, exist_ok=True)
        dest.write_bytes(raw)
        entries.append(dict({"path": path, "sha256": hashlib.sha256(raw).hexdigest(), "bytes": len(raw)}, **entry))
    manifest = {
        "name": "roblox-skills-design-pack",
        "schema_version": SCHEMA_VERSION,
        "pack_version": version,
        "source_repo": REPO,
        "source_commit": git("rev-parse", "HEAD"),
        "source_dirty": bool(git("status", "--porcelain")),
        "built_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "license": "MIT (LICENSE); source credits in NOTICE.md",
        "provenance": PROVENANCE,
        "kinds": KINDS,
        "skills": [{"name": s, "sections": w or "all", "topic": t} for s, w, t in GUIDES],
        "files": entries,
    }
    text = json.dumps(manifest, indent=2) + "\n"
    (pack / "manifest.json").write_text(text)
    if tgz:
        (out / "manifest.json").write_text(text)

        def clean(info):
            info.mtime, info.uid, info.gid, info.uname, info.gname = 0, 0, 0, "", ""
            return info
        with tarfile.open(out / "design-pack.tgz", "w:gz") as tar:
            for p in sorted(pack.rglob("*")):
                tar.add(p, arcname=str(p.relative_to(out)), recursive=False, filter=clean)
    print("wrote %s (%d files)%s" % (pack, len(entries) + 1, " and design-pack.tgz" if tgz else ""))
    return []


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--check", action="store_true", help="validate only, write nothing")
    ap.add_argument("--out", default="dist", help="output folder (default dist)")
    ap.add_argument("--version", default="0.0.0-dev", help="pack version, the release tag without design-pack-v")
    ap.add_argument("--tgz", action="store_true", help="also write design-pack.tgz and manifest.json next to the folder")
    a = ap.parse_args()
    if a.check:
        files, errs = collect()
        if not errs:
            print("ok: %d files" % len(files))
    else:
        errs = build(Path(a.out).resolve(), a.version, a.tgz)
    for e in errs:
        print("error: " + e, file=sys.stderr)
    sys.exit(1 if errs else 0)


if __name__ == "__main__":
    main()
