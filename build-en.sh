#!/usr/bin/env bash
# Regenerates en/index.html from index.html + the EN dictionary in script.js.
# Run this after editing the French page (index.html) so the English page stays in sync.
# Requires: node, python with beautifulsoup4 (pip install beautifulsoup4).
set -e
cd "$(dirname "$0")"

node -e '
const fs=require("fs");let s=fs.readFileSync("script.js","utf8");
let a=s.indexOf("const EN"),b=s.indexOf("const FR");
let o=s.slice(a,b).replace(/^const EN\s*=\s*/,"").replace(/;\s*$/,"").trim();
fs.writeFileSync("_en.json", JSON.stringify(eval("("+o+")")));
'

python - << 'PY'
import json, os
from bs4 import BeautifulSoup
DOMAIN="https://snmi.sarl"
EN=json.load(open("_en.json",encoding="utf-8"))
soup=BeautifulSoup(open("index.html",encoding="utf-8").read(),"html.parser")
soup.html["lang"]="en"
for el in soup.select("[data-i18n]"):
    k=el.get("data-i18n")
    if k not in EN: continue
    v=EN[k]
    if el.name=="meta": el["content"]=v
    else:
        el.clear()
        for c in list(BeautifulSoup(v,"html.parser").contents): el.append(c)
for tag,attr in [("img","src"),("script","src"),("link","href"),("source","src"),("video","poster")]:
    for el in soup.find_all(tag):
        v=el.get(attr)
        if v and v.startswith("assets/"): el[attr]="../"+v
for el in soup.find_all("script", src=True):
    if el["src"]=="script.js": el["src"]="../script.js"
for l in soup.find_all("link", rel=True):
    r=l.get("rel")
    if "canonical" in r: l["href"]=DOMAIN+"/en/"
    if "alternate" in r and l.get("hreflang")=="en": l["href"]=DOMAIN+"/en/"
for m in soup.find_all("meta"):
    if m.get("property")=="og:url": m["content"]=DOMAIN+"/en/"
    if m.get("property")=="og:locale": m["content"]="en_US"
    if m.get("property")=="og:locale:alternate": m["content"]="fr_MA"
for a in soup.select('a[hreflang]'):
    if a.get("hreflang")=="fr": a["href"]="../"; a["class"]=["hdr-flip","text-stone"]; a.attrs.pop("aria-current",None)
    elif a.get("hreflang")=="en": a["href"]="./"; a["class"]=["hdr-flip","text-ink"]; a["aria-current"]="true"
for sc in soup.find_all("script", type="application/ld+json"):
    d=json.loads(sc.string); d["url"]=DOMAIN+"/en/"
    d["description"]="Industrial maintenance company in Morocco: steam turbines, mills, gearboxes, boilermaking, laser alignment and energy optimization for heavy industry."
    sc.string=json.dumps(d,ensure_ascii=False,indent=2)
os.makedirs("en",exist_ok=True)
open("en/index.html","w",encoding="utf-8").write(str(soup))
print("Rebuilt en/index.html")
PY
rm -f _en.json
