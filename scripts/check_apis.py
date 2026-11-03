#!/usr/bin/env python3
"""Check that Roblox API names used in the skills still exist in the live docs.

Usage: python3 -I scripts/check_apis.py [skills_dir]
Reads every SKILL.md, finds Class.Member / Class:Method / Enum.Name.Item tokens whose
class is in the live engine index, fetches the class page and reports tokens that are
missing or marked deprecated. Needs network, no login. Exit code 1 if anything is missing.
"""
import re, sys, pathlib, urllib.request, concurrent.futures as cf

BASE = "https://create.roblox.com/docs/reference/engine"
skills = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else "plugins/roblox-skills/skills")

def get(url):
    try:
        with urllib.request.urlopen(urllib.request.Request(url, headers={"User-Agent": "skills-api-check"}), timeout=30) as r:
            return r.read().decode("utf8", "replace")
    except Exception:
        return None

index = get(f"{BASE}/llms.txt")
if not index:
    sys.exit("cannot fetch the engine index")
kinds = {}
for m in re.finditer(r"/reference/engine/(classes|datatypes|enums)/([A-Za-z0-9_]+)\.md", index):
    kinds[m.group(2)] = m.group(1)

tok = re.compile(r"\b([A-Z][A-Za-z0-9]+)(?:[.:]([A-Z][A-Za-z0-9]+))(?:\.([A-Z][A-Za-z0-9]+))?")
used = {}  # (kind, name, member) -> set(files)
for f in sorted(skills.glob("*/SKILL.md")):
    text = f.read_text(encoding="utf8")
    for m in tok.finditer(text):
        a, b, c = m.groups()
        if a == "Enum":
            if b in kinds and kinds[b] == "enums" and c:
                used.setdefault(("enums", b, c), set()).add(f.parent.name)
        elif a in kinds and kinds[a] != "enums":
            used.setdefault((kinds[a], a, b), set()).add(f.parent.name)

pages = {}
def page(kind, name):
    key = (kind, name)
    if key not in pages:
        pages[key] = get(f"{BASE}/{kind}/{name}.md")
    return pages[key]

want = sorted({(k, n) for k, n, _ in used})
with cf.ThreadPoolExecutor(8) as ex:
    list(ex.map(lambda kn: page(*kn), want))

ignore = set()
ign = pathlib.Path(__file__).with_name("check_apis.ignore")
if ign.exists():
    for line in ign.read_text(encoding="utf8").splitlines():
        line = line.split("#")[0].strip()
        if line:
            ignore.add(line)

# Members inherited from these bases are not on the subclass page.
BASES = ["BasePart", "PVInstance", "Instance", "GuiObject", "GuiBase2d", "LayerCollector", "Light", "Model", "LuaSourceContainer", "ValueBase"]

def find(body, name, member):
    return re.search(rf"^#+ .*\b{re.escape(name)}[.:]{re.escape(member)}\b.*$|^\| `{re.escape(member)}`", body, re.M)

bad = 0
for (kind, name, member), files in sorted(used.items()):
    if f"{name}.{member}" in ignore:
        continue
    body = page(kind, name)
    where = ", ".join(sorted(files))
    if body is None:
        print(f"UNREADABLE {name} ({where})"); continue
    head = find(body, name, member)
    if not head and kind == "classes":
        for base in BASES:
            bb = page("classes", base)
            if bb and (h := find(bb, base, member)):
                head, body = h, bb
                break
    if not head:
        print(f"MISSING    {name}.{member}  ({where})"); bad += 1; continue
    after = body[head.end(): head.end() + 700].lower()
    if "deprecated" in after.split("\n### ")[0]:
        print(f"DEPRECATED {name}.{member}  ({where})"); bad += 1

print(f"checked {len(used)} names from {len(list(skills.glob('*/SKILL.md')))} skills; {bad} problems")
sys.exit(1 if bad else 0)
