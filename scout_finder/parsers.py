"""Pure parsing/filtering logic — the single source of truth shared by the GitHub
Actions scraper and the test/validation harness. Mirrors the Swift providers
(EbayProvider, CraigslistProvider, ClassicCars/HemmingsProvider, JSONLD, ScrapeHelpers).

A "listing" is a plain dict:
    {title, url, price (float|None), price_text (str|None), image (str|None),
     source (id), source_name, location (str|None)}
"""
import json
import re

# ----------------------------------------------------------------- scrape helpers

def strip_tags(s):
    s = re.sub(r"<[^>]+>", " ", s)
    for k, v in {"&amp;": "&", "&#39;": "'", "&quot;": '"', "&nbsp;": " ",
                 "&gt;": ">", "&lt;": "<", "&ndash;": "-", "&mdash;": "-"}.items():
        s = s.replace(k, v)
    return re.sub(r"\s+", " ", s).strip()

def price_value(s):
    if s is None:
        return None
    digits = re.sub(r"[^0-9.]", "", s)
    if not digits:
        return None
    try:
        return float(digits)
    except ValueError:
        return None

def format_price(v):
    if v is None:
        return None
    return "${:,.0f}".format(v)

def is_relevant(title):
    """True if the title plausibly refers to an early International Scout
    (80/800/800A/800B). Filters out Scout II and unrelated 'scout' hits."""
    t = title.lower()
    if "scout" not in t:
        return False
    internationalish = ("international" in t or "harvester" in t
                        or " ih " in t or t.startswith("ih "))
    early = any(x in t for x in
               ("scout 80", "scout 800", "800a", "800b", "scout80", "scout800"))
    scout_ii = "scout ii" in t or "scout 2" in t or "scoutii" in t
    if scout_ii and not early:
        return False
    return internationalish or early

# ----------------------------------------------------------------- JSON-LD

VEHICLE_TYPES = ("vehicle", "car", "product", "individualproduct", "motorizedvehicle")

def _type_str(v):
    if isinstance(v, str):
        return v.lower()
    if isinstance(v, list):
        return ",".join(x for x in v if isinstance(x, str)).lower()
    return ""

def _price_from_offers(offers):
    def extract(d):
        raw = d.get("price")
        if raw is None:
            raw = d.get("lowPrice")
        if raw is None and isinstance(d.get("priceSpecification"), dict):
            raw = d["priceSpecification"].get("price")
        if isinstance(raw, (int, float)):
            return float(raw)
        if isinstance(raw, str):
            return price_value(raw)
        return None
    if isinstance(offers, dict):
        return extract(offers)
    if isinstance(offers, list) and offers and isinstance(offers[0], dict):
        return extract(offers[0])
    return None

def _image_str(v):
    if isinstance(v, str):
        return v
    if isinstance(v, list) and v:
        if isinstance(v[0], str):
            return v[0]
        if isinstance(v[0], dict):
            return v[0].get("url")
    if isinstance(v, dict):
        return v.get("url")
    return None

def jsonld_vehicles(html):
    out = []
    for raw in re.findall(r'<script[^>]*type="application/ld\+json"[^>]*>(.*?)</script>',
                          html, re.S | re.I):
        cleaned = raw.replace("<!--", "").replace("-->", "").strip()
        try:
            obj = json.loads(cleaned)
        except json.JSONDecodeError:
            continue
        _collect(obj, out)
    return out

def _collect(any_, out):
    if isinstance(any_, list):
        for el in any_:
            _collect(el, out)
        return
    if not isinstance(any_, dict):
        return
    for key in ("@graph", "itemListElement", "item"):
        if key in any_:
            _collect(any_[key], out)
    if not any(v in _type_str(any_.get("@type")) for v in VEHICLE_TYPES):
        return
    name = any_.get("name") or ""
    if not name:
        return
    out.append({
        "name": name,
        "url": any_.get("url") or any_.get("@id"),
        "price": _price_from_offers(any_.get("offers")),
        "image": _image_str(any_.get("image")),
    })

def parse_jsonld_listings(html, source, source_name):
    out, seen = [], set()
    for v in jsonld_vehicles(html):
        title = strip_tags(v["name"])
        if not is_relevant(title):
            continue
        url = v["url"]
        if not url or url in seen:
            continue
        seen.add(url)
        out.append({
            "title": title, "url": url,
            "price": v["price"], "price_text": format_price(v["price"]),
            "image": v.get("image"), "source": source,
            "source_name": source_name, "location": None,
        })
    return out

# ----------------------------------------------------------------- eBay HTML

def parse_ebay(html):
    matches = list(re.finditer(r'href="(https://www\.ebay\.com/itm/[^"]+)"', html, re.I))
    out, seen = [], set()
    for i, m in enumerate(matches):
        start = m.start()
        end = matches[i + 1].start() if i + 1 < len(matches) else len(html)
        window = html[start:end]
        href = m.group(1).replace("&amp;", "&")
        tm = re.search(r"s-item__title[^>]*>(.*?)</a>", window, re.S | re.I) \
            or re.search(r"s-item__title[^>]*>(.*?)<", window, re.S | re.I)
        title = strip_tags(tm.group(1)) if tm else ""
        if not title or "shop on ebay" in title.lower() or not is_relevant(title):
            continue
        canonical = href.split("?")[0]
        if canonical in seen:
            continue
        seen.add(canonical)
        pm = re.search(r"s-item__price[^>]*>(.*?)<", window, re.S | re.I)
        price_text = strip_tags(pm.group(1)) if pm else None
        im = re.search(r"(https://i\.ebayimg\.com/[^\"']+)", window)
        out.append({
            "title": title, "url": href,
            "price": price_value(price_text), "price_text": price_text,
            "image": im.group(1) if im else None,
            "source": "ebay", "source_name": "eBay Motors", "location": None,
        })
    return out

# ----------------------------------------------------------------- Craigslist RSS

def parse_craigslist(xml, region):
    out = []
    for block in re.findall(r"<item\b(.*?)</item>", xml, re.S | re.I):
        tm = re.search(r"<title>(.*?)</title>", block, re.S | re.I)
        lm = re.search(r"<link>(.*?)</link>", block, re.S | re.I) \
            or re.search(r'rdf:about="(.*?)"', block, re.I)
        if not tm or not lm:
            continue
        title = strip_tags(tm.group(1))
        if not is_relevant(title):
            continue
        pm = re.search(r"(\$[0-9,]+)", title)
        out.append({
            "title": title, "url": lm.group(1).strip(),
            "price": price_value(pm.group(1)) if pm else None,
            "price_text": pm.group(1) if pm else None,
            "image": None, "source": "craigslist",
            "source_name": "Craigslist (%s)" % region,
            "location": region.capitalize(),
        })
    return out
