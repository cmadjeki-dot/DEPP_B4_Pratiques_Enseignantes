"""Contrôler le site Pages après déploiement, sans dépendance Python externe."""
import csv
import sys
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import urldefrag, unquote, urljoin, urlsplit
from urllib.request import Request, urlopen

BASE = (sys.argv[1] if len(sys.argv) > 1 else
        "https://cmadjeki-dot.github.io/DEPP_B4_Pratiques_Enseignantes/").rstrip("/") + "/"
PAGES = ["index.html", "reports/rapport_scientifique.html", "reports/annexes.html",
         "reports/note_decideur.html", "presentation/presentation_depp_b4.html"]


class Page(HTMLParser):
    def __init__(self):
        super().__init__()
        self.links, self.ids = [], set()

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if "id" in attrs:
            self.ids.add(attrs["id"])
        for key in ("href", "src", "data-src"):
            if key in attrs:
                self.links.append(attrs[key])


cache, checks = {}, []


def fetch(url):
    if url not in cache:
        try:
            with urlopen(Request(url, headers={"User-Agent": "DEPP-publication-audit"}), timeout=30) as response:
                body = response.read()
                mime = response.headers.get_content_type()
                cache[url] = (response.status, body.decode("utf-8", errors="replace") if mime == "text/html" else "")
        except Exception as error:
            cache[url] = (str(error), "")
    return cache[url]


for relative in PAGES:
    url = urljoin(BASE, relative)
    status, text = fetch(url)
    checks.append((relative, url, status == 200, str(status)))
    if status != 200:
        continue
    checks.append((relative, "Mention simulation", "Données simulées" in text, "Texte HTML"))
    parser = Page()
    parser.feed(text)
    for link in parser.links:
        target, fragment = urldefrag(urljoin(url, link))
        # Contrôler aussi les chemins à la racine du domaine : ils peuvent révéler
        # une erreur de préfixe du projet lors du passage de local à GitHub Pages.
        if urlsplit(target).netloc != urlsplit(BASE).netloc:
            continue
        code, content = fetch(target)
        ok = code == 200
        # Les fragments revealjs commençant par / désignent des diapositives.
        if ok and fragment and fragment != "top" and not fragment.startswith("/") and content:
            other = Page()
            other.feed(content)
            ok = unquote(fragment) in other.ids
        checks.append((relative, target + ("#" + fragment if fragment else ""), ok, str(code)))

Path("outputs/tables").mkdir(parents=True, exist_ok=True)
with open("outputs/tables/audit_site_publie.csv", "w", encoding="utf-8", newline="") as out:
    writer = csv.writer(out)
    writer.writerow(["page", "cible", "succes", "statut_http"])
    writer.writerows(checks)
failed = [row for row in checks if not row[2]]
print(f"Contrôles HTTP : {len(checks)} ; URL uniques : {len(cache)} ; échecs : {len(failed)}")
for row in failed:
    print(row)
sys.exit(bool(failed))
