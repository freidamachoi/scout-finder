"""Live fetching of the automated sources (stdlib urllib only). Each fetch is
best-effort: a failure (timeout, 403 bot-block, empty body) is recorded and skipped
so one bad source never fails the whole run.
"""
import urllib.request
import urllib.error

from . import parsers

UA = ("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 "
      "(KHTML, like Gecko) Version/17.0 Safari/605.1.15")

DEFAULT_REGIONS = ["raleigh", "charlotte", "greensboro", "norfolk", "richmond",
                   "washingtondc"]

def _get(url, timeout=25):
    req = urllib.request.Request(url, headers={
        "User-Agent": UA,
        "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
        "Accept-Language": "en-US,en;q=0.9",
    })
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return r.read().decode("utf-8", "replace")

def _fetch_one(label, fn, errors):
    try:
        items = fn()
        print("  %-26s %d listing(s)" % (label, len(items)))
        return items
    except Exception as e:  # noqa: BLE001 - best-effort by design
        msg = "%s: %s" % (label, e)
        print("  %-26s ERROR %s" % (label, e))
        errors.append(msg)
        return []

def fetch_ebay():
    html = _get("https://www.ebay.com/sch/6001/i.html"
                "?_nkw=international+scout&_sop=10&_ipg=60")
    return parsers.parse_ebay(html)

def fetch_classiccars():
    html = _get("https://classiccars.com/listings/find/1960-1972/international/scout")
    return parsers.parse_jsonld_listings(html, "classiccars", "ClassicCars.com")

def fetch_hemmings():
    html = _get("https://www.hemmings.com/classifieds/cars-for-sale/"
                "international-harvester/scout/")
    return parsers.parse_jsonld_listings(html, "hemmings", "Hemmings")

def fetch_craigslist(regions):
    out, seen = [], set()
    for region in regions:
        try:
            xml = _get("https://%s.craigslist.org/search/cta"
                       "?query=international%%20scout&format=rss" % region, timeout=20)
            for item in parsers.parse_craigslist(xml, region):
                if item["url"] not in seen:
                    seen.add(item["url"])
                    out.append(item)
        except Exception as e:  # noqa: BLE001
            print("  craigslist/%-15s ERROR %s" % (region, e))
    return out

def fetch_all(regions=None):
    """Run every automated provider. Returns (listings, errors). Listings are
    de-duplicated by URL across sources."""
    regions = regions or DEFAULT_REGIONS
    errors = []
    print("Fetching automated sources...")
    collected = []
    collected += _fetch_one("eBay Motors", fetch_ebay, errors)
    collected += _fetch_one("ClassicCars.com", fetch_classiccars, errors)
    collected += _fetch_one("Hemmings", fetch_hemmings, errors)
    collected += _fetch_one("Craigslist (%d regions)" % len(regions),
                            lambda: fetch_craigslist(regions), errors)

    seen, deduped = set(), []
    for item in collected:
        if item["url"] not in seen:
            seen.add(item["url"])
            deduped.append(item)
    print("Total unique: %d (%d source error(s))" % (len(deduped), len(errors)))
    return deduped, errors
