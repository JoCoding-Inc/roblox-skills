#!/usr/bin/env python3
"""Push static UI text from a Rojo src tree into the experience's auto-localization table.

  python3 -I l10n_sync.py SRC_DIR [UNIVERSE_ID] [--dry-run] [--list] [--skip GLOB ...]

Why: Creator Hub says Automatic Text Capture can take up to several days to fill the table.
Strings you add yourself were machine-translated into every enabled language in about a
minute (peer observation, 2026-11).
Reads the key from env ROBLOX_API_KEY (scope legacy-universe:manage) and never prints it.
UNIVERSE_ID (not the place id) defaults to env ROBLOX_UNIVERSE_ID. Only sources missing from
the table are added, so it is safe to run after every publish and to re-run after a failure.
--dry-run: extract and count only; no key, no writes. --list also prints each string and
where it was found: read it once, the extractor is a heuristic. --skip GLOB: file names
to ignore (art, audio and mesh builders whose literals are part and sound names).
Literals only: runtime-built text never matches an entry. Endpoints are legacy and EXPERIMENTAL
(checked against the OpenAPI spec 2026-11). Stdlib only.
"""
import argparse, fnmatch, json, os, re, sys, urllib.error, urllib.parse, urllib.request
from pathlib import Path

BATCH = 50  # 100 per PATCH returned 400 "Maximum entries exceeded" (2026-11), 50 worked
API = "https://apis.roblox.com"
TABLES = API + "/legacy-localization-tables/v1"
INTL = API + "/legacy-game-internationalization/v1"
CLASSES = {"Part", "Frame", "Folder", "Model", "Sound", "Texture", "Decal", "Beam", "Trail", "Tool", "Script",
           "Humanoid", "Animator", "Animation", "Attachment", "Highlight", "Sky", "Font"}
NON_UI_CALL = re.compile(
    r"(Instance\.new|GetService|WaitForChild|FindFirstChild\w*|IsA|SetAttribute|GetAttribute\w*|"
    r"GetPropertyChangedSignal|require|warn|print|error|FireServer|FireClient|FireAllClients|"
    r"Enum\.\w+|BindAction|UnbindAction|BindToRenderStep|UnbindFromRenderStep|GetDataStore|"
    r"GetOrderedDataStore|Log\w*Event|debug\.\w+|SetCore|GetCore|CollectionService\.\w+|"
    r"AddTag|HasTag|GetTagged|RemoveTag)\s*\(\s*[^)]*$")
NON_UI_KEY = re.compile(
    r"\b(Name|Tag|Key|key|id|Id|kind|type|icon|Icon|font|Font|anim|sound|Sound|event|action|remote|"
    r"layout|Image|image|Texture|TextureID|MeshId|SoundId|AnimationId|Material|Style|Shape)\s*=\s*$")


def is_ui_text(s):
    if not re.search(r"[A-Za-z]", s) or not 2 <= len(s) <= 300 or s in CLASSES:
        return False
    if s.startswith(("rbxasset", "rbxthumb", "http", "#", "/")) or "\\" in s or s != s.strip():
        return False  # asset urls, escapes, concat fragments with edge spaces
    if re.search(r"%[-\d.]*[dsfigqx]|%%|%[a-zA-Z]|\[\^", s):
        return False  # format and match patterns are filled in at runtime
    if " " not in s:  # one word: only Word or CAPS, not UICorner, Pet_1, Pet_, a.b, camelCase
        return bool(re.fullmatch(r"[^\sA-Za-z0-9_]*(?:[A-Z][a-z]+|[A-Z]+)[^\sA-Za-z0-9_]*", s))
    return True


def literals(line, in_block):
    """Return ([(start, text)] of quoted literals outside comments, still-in-block-comment)."""
    out, i, n = [], 0, len(line)
    while i < n:
        if in_block:
            j = line.find("]]", i)
            if j < 0:
                break
            in_block, i = False, j + 2
        elif line[i] in "\"'":
            j = i + 1
            while j < n and line[j] != line[i]:
                j += 2 if line[j] == "\\" else 1
            if j < n:
                out.append((i, line[i + 1:j]))
            i = j + 1
        elif line.startswith("--[[", i):
            in_block, i = True, i + 4
        elif line.startswith("--", i):
            break
        else:
            i += 1
    return out, in_block


def extract(src, skip):
    found, root = {}, Path(src)
    for f in sorted(list(root.rglob("*.lua")) + list(root.rglob("*.luau"))):
        if any(fnmatch.fnmatch(f.name, g) for g in skip):
            continue
        in_block = False
        for ln, line in enumerate(f.read_text(encoding="utf-8", errors="replace").splitlines(), 1):
            lits, in_block = literals(line, in_block)
            for pos, s in lits:
                before = line[:pos]
                tail = line[pos + len(s) + 2:].lstrip()
                if NON_UI_CALL.search(before) or NON_UI_KEY.search(before):
                    continue
                if before.rstrip().endswith("[") or tail.startswith(("]", "==", "~=")) or re.search(r"(==|~=)\s*$", before):
                    continue  # table keys and comparisons are ids, not text
                if is_ui_text(s):
                    found.setdefault(s, f"{f.relative_to(root.parent).as_posix()}:{ln}")
    return found


def call(method, url, body=None):
    req = urllib.request.Request(url, method=method, data=None if body is None else json.dumps(body).encode(),
                                 headers={"x-api-key": os.environ["ROBLOX_API_KEY"], "Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(req, timeout=60) as r:
            txt = r.read().decode()
            return json.loads(txt) if txt else {}
    except urllib.error.HTTPError as e:
        sys.exit(f"{method} {url.split('?')[0]} -> {e.code} {e.read().decode()[:300]}")


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("src")
    ap.add_argument("universe", nargs="?", default=os.environ.get("ROBLOX_UNIVERSE_ID"))
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--list", action="store_true")
    ap.add_argument("--skip", action="append", default=[])
    a = ap.parse_args()
    if not a.universe:
        ap.error("give UNIVERSE_ID or set ROBLOX_UNIVERSE_ID")
    found = extract(a.src, a.skip)
    print(f"{len(found)} source strings in {a.src}")
    if a.list:
        for s, where in found.items():
            print(f"{where}\t{s}")
    try:  # public endpoint, no key
        with urllib.request.urlopen(f"https://gameinternationalization.roblox.com/v1/source-language/games/{a.universe}", timeout=30) as r:
            lang = json.load(r)["languageCode"]
    except urllib.error.HTTPError as e:
        sys.exit(f"source-language -> {e.code} (check UNIVERSE_ID)")
    print(f"source language: {lang}" + ("" if lang == "en" else "  WARNING: English text under another source language is never translated"))
    if a.dry_run:
        return
    if not os.environ.get("ROBLOX_API_KEY"):
        sys.exit("set ROBLOX_API_KEY (scope legacy-universe:manage)")
    table = call("POST", f"{TABLES}/autolocalization/games/{a.universe}/autolocalizationtable", {})["autoLocalizationTableId"]
    have, cursor = set(), None
    while True:
        page = call("GET", f"{TABLES}/localization-table/tables/{table}/entries?gameId={a.universe}"
                    + (f"&cursor={urllib.parse.quote(cursor)}" if cursor else ""))
        have.update(e["identifier"]["source"] for e in page["data"])
        cursor = page.get("nextPageCursor")
        if not cursor:
            break
    new = [(s, w) for s, w in found.items() if s not in have]
    print(f"table has {len(have)} entries, {len(new)} new")
    for i in range(0, len(new), BATCH):
        entries = [{"identifier": {"source": s, "context": "", "key": ""}, "metadata": {"example": w}} for s, w in new[i:i + BATCH]]
        call("PATCH", f"{TABLES}/localization-table/tables/{table}?gameId={a.universe}", {"entries": entries})
        print(f"sent {min(i + BATCH, len(new))}/{len(new)}")  # the reply lists no entries even on success
    count = call("GET", f"{TABLES}/localization-table/tables/{table}/entry-count?gameId={a.universe}")["entryCount"]
    langs = call("GET", f"{INTL}/supported-languages/games/{a.universe}/automatic-translation-status")["data"]
    off = [x["languageCode"] for x in langs if not x["isAutomaticTranslationEnabled"]]
    print(f"entry-count {count}; auto translation on for {len(langs) - len(off)}/{len(langs)} languages" + (f", OFF: {' '.join(off)}" if off else ""))


if __name__ == "__main__":
    main()
