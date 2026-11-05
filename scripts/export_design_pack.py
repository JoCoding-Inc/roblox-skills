#!/usr/bin/env python3
"""Build the design pack: design data files, their JSON Schemas, the design-related
skill sections as markdown, their images and a manifest.

  python3 -I scripts/export_design_pack.py --check
  python3 -I scripts/export_design_pack.py --write-schemas
  python3 -I scripts/export_design_pack.py --out dist --version 1.0.0 --tgz

Writes <out>/design-pack/ (with --tgz also <out>/design-pack.tgz, <out>/manifest.json and
<out>/SHA256SUMS). styles.json is generated from ui_style_mock.luau PRESETS and the ui-styles
README, so the Lua file stays the single source. Schemas are derived from the data: every
current key is required and typed, unit suffixes add ranges. Stdlib only; uses the jsonschema
package too when present.
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
SEMVER = re.compile(r"^[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?$")

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
TOPICS = {
    "layout": "placement, reserved zones, sizes and floors",
    "stud-style": "simulator/tycoon stud house style",
    "ui-styles": "UI style cards and presets",
    "motion": "UI motion",
    "typography": "fonts and text",
    "icons": "UI icons and icon packs",
    "effects": "rarity tiers, reveals, VFX and feel",
    "ui-engine": "engine UI features and rules",
    "art-direction": "style lanes, part looks, art sources, image generation",
    "mesh-art": "Blender mesh art",
    "store-art": "world props, game icon, thumbnails, logo, loading screen",
    "license": "license and credits",
}
DATA_TOPIC = {"zones": "layout", "tokens": "stud-style", "motion": "motion", "typography": "typography",
              "icons": "icons", "vfx": "effects", "styles": "ui-styles"}
# (skill, sections or None for the whole skill, topic)
GUIDES = [
    ("roblox-ui-layout", None, "layout"),
    ("roblox-ui-genre-studs", None, "stud-style"),
    ("roblox-ui-typography", None, "typography"),
    ("roblox-fun-effects", None, "effects"),
    ("roblox-store-art-pack", None, "store-art"),
    ("roblox-feel-audio-vfx", ["1", "3", "4", "5"], "effects"),
    ("roblox-engine-2026", ["2"], "ui-engine"),
    ("roblox-game-pipeline", ["3", "6a", "10"], "art-direction"),
    ("roblox-blender-export", ["2", "3", "4", "6"], "mesh-art"),
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
# styles.json keeps the Lua keys of PRESETS; units are given here
STYLE_KEYS = {
    "font": "display font as {family, weight?}", "text": "text color [r, g, b]", "stroke": "text stroke color [r, g, b]",
    "strokeW": "text stroke width in px, 0 for none", "panel": "panel body color [r, g, b]",
    "panelT": "panel BackgroundTransparency, 0 to 1", "panelStroke": "panel outline color [r, g, b]",
    "panelStrokeW": "panel outline width in px", "panelStrokeT": "panel outline transparency, 0 to 1",
    "radius": "panel corner radius in px", "lip": "color of the lip under the panel [r, g, b], null for none",
    "header": "header band gradient [[r, g, b] top, [r, g, b] bottom], null for no band",
    "headerTab": "header drawn as a tab holding the title", "sheen": "two light diagonal stripes across the header band",
    "accent": "color of a 2 px line under the header [r, g, b]", "pills": "colors of the small pills next to the title",
    "card": "item card color [r, g, b]", "cardT": "card BackgroundTransparency, 0 to 1", "cardStroke": "card outline color [r, g, b]",
    "cardStrokeW": "card outline width in px", "cardStrokeT": "card outline transparency, 0 to 1", "cardRadius": "card corner radius in px",
    "rarity": "one color per item card", "rarityMode": "how rarity is drawn: fill (card color, diagonal shade), line (bar over the price), tag (pill top-left)",
    "chip": "price chip color [r, g, b]", "chipLip": "price chip outline color [r, g, b], null for none",
    "chipWide": "price chip spans the card width", "chipText": "price text color [r, g, b]; null means white with a stroke",
    "close": "close button color [r, g, b]", "closeRadius": "close button corner radius in px (default 10)",
    "btn": "HUD menu button color [r, g, b]", "btnT": "menu button BackgroundTransparency, 0 to 1",
    "btnGrad": "menu button gradient [[r, g, b] top, [r, g, b] bottom], null for flat", "btnStroke": "menu button outline color [r, g, b]",
    "btnStrokeW": "menu button outline width in px", "btnStrokeT": "menu button outline transparency, 0 to 1",
    "btnRadius": "menu button corner radius in px",
}


# ---------- schemas derived from the data ----------

UNIT = re.compile(r"_(px|s|scale|studs|deg)(_|$)")
LIMIT = re.compile(r"(^|_)(max|min)(_|$)")
DEFS = {
    "provenance": {"enum": sorted(PROVENANCE), "description": "; ".join("%s: %s" % kv for kv in sorted(PROVENANCE.items()))},
    "leaf": {"type": "object", "required": ["v", "p"],
             "properties": {
                 "v": {"description": "the value; units are in the key name (_px, _s, _share, _scale, _rgb, _studs, _deg); [a, b] under a unit key is a range or a width-height size"},
                 "p": {"$ref": "#/$defs/provenance"},
                 "src": {"type": "string", "description": "source or qualifier (for example 'about')"},
                 "date": {"type": "string", "pattern": "^[0-9]{4}(-[0-9]{2}(-[0-9]{2})?)?$"}},
             "additionalProperties": True},
    "node": {"type": "object", "minProperties": 1, "additionalProperties": {"anyOf": [{"$ref": "#/$defs/leaf"}, {"$ref": "#/$defs/node"}]}},
    "rgb": {"type": "array", "items": {"type": "integer", "minimum": 0, "maximum": 255}, "minItems": 3, "maxItems": 3},
}
ANY = {"anyOf": [{"$ref": "#/$defs/leaf"}, {"$ref": "#/$defs/node"}]}


def is_leaf(x):
    return isinstance(x, dict) and "v" in x and "p" in x


def is_rgb(x):
    return isinstance(x, list) and len(x) == 3 and all(isinstance(i, int) and not isinstance(i, bool) and 0 <= i <= 255 for i in x)


def value_schema(key, x):
    if x is None:
        return {"type": "null"}
    if isinstance(x, bool):
        return {"type": "boolean"}
    if isinstance(x, (int, float)):
        s = {"type": "number"}
        if key.endswith("_share") or key.endswith("_of_height") or key.endswith("_of_face"):
            s.update(minimum=0, maximum=1)
        elif UNIT.search(key) or LIMIT.search(key):
            s["minimum"] = 0
        return s
    if isinstance(x, str):
        return {"type": "string"}
    if isinstance(x, dict):
        return {"type": "object"}
    if key.endswith("_rgb") or is_rgb(x):
        return {"$ref": "#/$defs/rgb"}
    if x and all(is_rgb(i) for i in x):
        return {"type": "array", "items": {"$ref": "#/$defs/rgb"}}
    if x and all(isinstance(i, str) for i in x):
        return {"type": "array", "items": {"type": "string"}}
    if x and all(isinstance(i, (int, float)) and not isinstance(i, bool) for i in x):
        item = value_schema(key, x[0])
        s = {"type": "array", "items": item}
        if len(x) == 2:
            s.update(minItems=2, maxItems=2)
        return s
    return {"type": "array"}


def typed(key):
    return bool(re.search(r"_(share|of_height|of_face|rgb)$", key) or UNIT.search(key) or LIMIT.search(key))


def derive(x, key="", docs=None, tkey=""):
    """tkey: the key whose unit types the value; a unitless child inherits its parent's."""
    tkey = key if typed(key) or not typed(tkey) else tkey
    if is_leaf(x):
        s = {"allOf": [{"$ref": "#/$defs/leaf"}, {"properties": {"v": value_schema(tkey, x["v"])}}]}
        if docs and key in docs:
            s["description"] = docs[key]
        return s
    if isinstance(x, dict):
        sub = STYLE_KEYS if key == "values" else None
        return {"type": "object", "required": list(x), "properties": {k: derive(v, k, sub, tkey) for k, v in x.items()},
                "additionalProperties": ANY}
    if isinstance(x, list):
        merged = {}
        for item in x:
            for k, v in item.items():
                merged.setdefault(k, []).append(v)
        props = {}
        for k, vs in merged.items():
            kinds = []
            for v in vs:
                s = value_schema(k, v["v"])
                if s not in kinds:
                    kinds.append(s)
            props[k] = {"allOf": [{"$ref": "#/$defs/leaf"}, {"properties": {"v": kinds[0] if len(kinds) == 1 else {"anyOf": kinds}}}]}
        required = [k for k in merged if len(merged[k]) == len(x)]
        return {"type": "array", "minItems": 1, "items": {"type": "object", "required": required, "properties": props,
                                                          "additionalProperties": ANY}}
    raise ValueError("data must hold leaves, objects or lists of objects (at %s)" % key)


def schema_for(kind, doc):
    return {
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        "$id": "%s/design/schema/%s.schema.json" % (REPO, kind),
        "title": doc["title"],
        "description": "Derived from the %s data by scripts/export_design_pack.py --write-schemas: every key present today is required and typed. Unknown keys are allowed everywhere (minor versions add keys); readers ignore them." % kind,
        "type": "object",
        "required": ["type", "schema_version", "title", "scope", "sources", "data"],
        "properties": {
            "type": {"const": kind},
            "schema_version": {"type": "string", "pattern": "^%s\\.[0-9]+\\.[0-9]+$" % SCHEMA_VERSION.split(".")[0]},
            "title": {"type": "string"}, "scope": {"type": "string"},
            "sources": {"type": "array", "items": {"type": "string"}},
            "data": derive(doc["data"]),
        },
        "additionalProperties": True,
        "$defs": DEFS,
    }


def dump(obj):
    return (json.dumps(obj, indent=2) + "\n").encode()


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
        leaf = lambda v, src=None: dict({"v": v, "p": "opinion"}, **({"src": src} if src else {}))
        out[key] = {
            "name": leaf(card["name"]),
            "card_image": leaf("skills/roblox-game-pipeline/assets/ui-styles/%s.jpg" % key,
                               "pack path; a 2025-26 hit's screen redrawn with its UI kept and new content"),
            "look": leaf(card["look"]),
            "fits": leaf(card["fits"]),
            "font_row": leaf(card["font_row"], "roblox-ui-typography section 2"),
            "values": {k: leaf(v, "ui_style_mock.luau, drawn to match the card") for k, v in values.items()},
        }
    return {
        "type": "styles",
        "schema_version": SCHEMA_VERSION,
        "title": "UI style presets (keys of ui_style_mock.luau PRESETS) with their style card",
        "scope": "every genre; a simulator/tycoon uses stud-chunky (tokens.json rules)",
        "sources": ["roblox-game-pipeline/scripts/ui_style_mock.luau", "roblox-game-pipeline/assets/ui-styles/README.md"],
        "data": {"presets": out},
    }


def load_data():
    data = {p.stem: json.loads(p.read_text()) for p in sorted((DESIGN / "data").glob("*.json"))}
    data["styles"] = build_styles()
    return data


# ---------- guides ----------

def sections(text, wanted):
    found, cur = {}, None
    for line in text.splitlines():
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
    head = ("# %s (sections %s)\n\n<!-- Sections %s of plugins/roblox-skills/skills/%s/SKILL.md. The other sections are left out of the pack; "
            "references to them are listed in manifest.json files[].unresolved_refs and resolve under source_base_url. -->\n\n") % (
        skill, ", ".join(wanted), ", ".join(wanted), skill)
    return head + "\n\n".join(sections(text, wanted)) + "\n"


SKILL_REF = re.compile(r"`?(roblox-[a-z0-9-]+)`?")
SEC_REF = re.compile(r"\bsections?\s+([0-9]+[a-z]?(?:(?:,\s*|\s+and\s+)[0-9]+[a-z]?)*)")
PATH_REF = re.compile(r"(?<![\w/.<>-])((?:roblox-[a-z0-9-]+/)?(?:scripts|assets|references)/[\w./-]*[\w/])")


SUB_HEADING = re.compile(r"^#{2,3} ([0-9]+[a-z]?)\. ", re.M)


def owner(text, start, default):
    """The skill a reference belongs to: a skill name just before it, else the guide's own skill."""
    best = default
    for s in SKILL_REF.finditer(text, max(0, start - 80), start):
        if ". " not in text[s.end():start]:
            best = s.group(1)
    return best


def refs(skill, text, packed, paths):
    """References in a guide that the pack does not contain, relative to the skills folder."""
    if text.startswith("---\n"):
        text = text[text.index("\n---\n", 4) + 5:]
    out = set()
    for m in SEC_REF.finditer(text):
        target = skill
        for s in SKILL_REF.finditer(text, max(0, m.start() - 60), m.start()):
            if len(text[s.end():m.start()].strip(" (")) == 0:
                target = s.group(1)
        for sec in re.split(r",\s*|\s+and\s+", m.group(1)):
            got = packed.get(target, set())
            if "all" not in got and sec not in got and (SKILLS / target / "SKILL.md").exists():
                out.add("%s/SKILL.md#%s" % (target, sec))
    for m in SKILL_REF.finditer(text):
        if m.group(1) not in packed and (SKILLS / m.group(1) / "SKILL.md").exists():
            out.add("%s/SKILL.md" % m.group(1))
    for m in PATH_REF.finditer(text):
        p = m.group(1).rstrip("/")
        rel = p if p.startswith("roblox-") else "%s/%s" % (owner(text, m.start(), skill), p)
        if not any(x == "skills/" + rel or x.startswith("skills/" + rel + "/") for x in paths):
            out.add(rel)
    return sorted(out)


# ---------- pack ----------

def collect():
    """Return (files, errors). files: list of (pack path, bytes, manifest entry)."""
    files, errs = [], []
    try:
        data = load_data()
    except (ValueError, IndexError, KeyError) as e:
        return [], ["data: %s" % e]
    for kind, doc in sorted(data.items()):
        path = DESIGN / "schema" / ("%s.schema.json" % kind)
        if not path.exists():
            errs.append("schema/%s.schema.json missing: run --write-schemas" % kind)
            continue
        schema = json.loads(path.read_text())
        if doc.get("type") != kind or doc.get("schema_version") != SCHEMA_VERSION:
            errs.append("data %s: type must be %s and schema_version %s" % (kind, kind, SCHEMA_VERSION))
        bad = validate_all(doc, schema, "data " + kind)
        errs += bad
        if not bad and schema != json.loads(dump(schema_for(kind, doc))):
            errs.append("schema/%s.schema.json is out of date: review the data change, then run --write-schemas" % kind)
        files.append(("schema/%s.schema.json" % kind, path.read_bytes(), {"kind": "schema", "topic": DATA_TOPIC[kind], "section_ref": None}))
        raw = (DESIGN / "data" / ("%s.json" % kind)).read_bytes() if kind != "styles" else dump(doc)
        files.append(("data/%s.json" % kind, raw, {"kind": "data", "topic": DATA_TOPIC[kind], "section_ref": doc.get("sources", []),
                                                   "schema": "schema/%s.schema.json" % kind}))
    for p in sorted((DESIGN / "schema").glob("*.schema.json")):
        if p.name[:-len(".schema.json")] not in data:
            errs.append("%s has no data" % p.name)
    guides = []
    for skill, wanted, topic in GUIDES:
        try:
            text = guide_text(skill, wanted)
        except (OSError, ValueError) as e:
            errs.append("guide %s: %s" % (skill, e))
            continue
        ref = "%s/SKILL.md" % skill + ("#" + ",".join(wanted) if wanted else "")
        guides.append((skill, text))
        files.append(("skills/%s/SKILL.md" % skill, text.encode(), {"kind": "guide", "topic": topic, "section_ref": [ref]}))
    for folder, topic, ref in ASSET_DIRS:
        d = SKILLS / folder
        if not d.is_dir():
            errs.append("assets: missing " + folder)
            continue
        for p in sorted(d.iterdir()):
            if p.name == "README.md":
                guides.append((folder.split("/")[0], p.read_text()))
                files.append(("skills/%s/README.md" % folder, p.read_bytes(),
                              {"kind": "guide", "topic": topic, "section_ref": ["%s/README.md" % folder]}))
            elif p.suffix.lower() in IMAGE_EXT:
                files.append(("skills/%s/%s" % (folder, p.name), p.read_bytes(), {"kind": "image", "topic": topic, "section_ref": [ref]}))
    packed = {}
    for skill, wanted, _ in GUIDES:
        text = next(t for g, t in guides if g == skill)
        packed[skill] = {"all"} if wanted is None else set(SUB_HEADING.findall(text))
    paths = [f[0] for f in files]
    for path, raw, entry in files:
        if entry["kind"] == "guide":
            skill = path.split("/")[1]
            entry["unresolved_refs"] = refs(skill, raw.decode(), packed, paths)
    for name in ("LICENSE", "NOTICE.md"):
        files.append((name, (ROOT / name).read_bytes(), {"kind": "license", "topic": "license", "section_ref": None}))
    for path, raw, entry in files:
        if entry["kind"] != "image" and any(b > 127 for b in raw):
            errs.append("%s: non-ASCII bytes" % path)
        if entry["topic"] not in TOPICS:
            errs.append("%s: topic %s not in TOPICS" % (path, entry["topic"]))
    return files, errs


def write_schemas():
    errs = []
    for kind, doc in sorted(load_data().items()):
        schema = schema_for(kind, doc)
        bad = validate_all(doc, schema, "data " + kind)
        if bad:
            errs += bad
            continue
        (DESIGN / "schema" / ("%s.schema.json" % kind)).write_bytes(dump(schema))
        print("wrote schema/%s.schema.json" % kind)
    return errs


def git(*args):
    return subprocess.run(["git", "-C", str(ROOT)] + list(args), capture_output=True, text=True, check=True).stdout.strip()


def build(out, version, tgz):
    if not SEMVER.match(version):
        return ["--version %r is not semver (X.Y.Z or X.Y.Z-pre)" % version]
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
    commit = git("rev-parse", "HEAD")
    manifest = {
        "name": "roblox-skills-design-pack",
        "schema_version": SCHEMA_VERSION,
        "pack_version": version,
        "source_repo": REPO,
        "source_commit": commit,
        "source_dirty": bool(git("status", "--porcelain")),
        "source_base_url": "%s/blob/%s/plugins/roblox-skills/skills/" % (REPO, commit),
        "built_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "license": "MIT (LICENSE); source credits in NOTICE.md",
        "provenance": PROVENANCE,
        "kinds": KINDS,
        "topics": TOPICS,
        "excluded": "scripts, the other skills and sections, and the game project's own files (docs/..., assets/refs/...); see files[].unresolved_refs",
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
        sums = "".join("%s  %s\n" % (hashlib.sha256((out / n).read_bytes()).hexdigest(), n) for n in ("design-pack.tgz", "manifest.json"))
        (out / "SHA256SUMS").write_text(sums)
    print("wrote %s (%d files)%s" % (pack, len(entries) + 1, " and design-pack.tgz, manifest.json, SHA256SUMS" if tgz else ""))
    return []


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--check", action="store_true", help="validate only, write nothing")
    ap.add_argument("--write-schemas", action="store_true", help="derive design/schema from the data files")
    ap.add_argument("--out", default="dist", help="output folder (default dist)")
    ap.add_argument("--version", default="0.0.0-dev", help="pack version: the release tag without design-pack-v, semver")
    ap.add_argument("--tgz", action="store_true", help="also write design-pack.tgz, manifest.json and SHA256SUMS next to the folder")
    a = ap.parse_args()
    if a.write_schemas:
        errs = write_schemas()
    elif a.check:
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
