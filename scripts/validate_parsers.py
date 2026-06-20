#!/usr/bin/env python3
"""Executable validation of the shared parsing logic in scout_finder/parsers.py.

Runs the parsers against the SAME fixtures used by ScoutFinderTests/ParsingTests.swift,
so the logic is verifiable without a Mac or network. The GitHub Actions scraper, the
iOS app providers, and this harness all implement the same rules.

Run:  python3 scripts/validate_parsers.py
"""
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))
from scout_finder import parsers as P  # noqa: E402

FIX = os.path.join(os.path.dirname(__file__), "..", "ScoutFinderTests", "Fixtures")
PASS = FAIL = 0


def check(name, cond, detail=""):
    global PASS, FAIL
    if cond:
        PASS += 1
        print("  \033[32mPASS\033[0m " + name)
    else:
        FAIL += 1
        print("  \033[31mFAIL\033[0m %s  %s" % (name, detail))


def read(name):
    with open(os.path.join(FIX, name), encoding="utf-8") as f:
        return f.read()


def main():
    print("Relevance filter")
    check("accepts '1965 International Harvester Scout 800'",
          P.is_relevant("1965 International Harvester Scout 800"))
    check("accepts '1969 Scout 800A project'", P.is_relevant("1969 Scout 800A project"))
    check("rejects '1972 Ford Bronco'", not P.is_relevant("1972 Ford Bronco"))
    check("rejects '1974 International Scout II'", not P.is_relevant("1974 International Scout II"))
    check("rejects 'Boy Scout memorabilia lot'", not P.is_relevant("Boy Scout memorabilia lot"))

    print("Price parsing")
    check("'$24,500' -> 24500", P.price_value("$24,500") == 24500)
    check("'$31,500.00' -> 31500", P.price_value("$31,500.00") == 31500)
    check("'-' -> None", P.price_value("—") is None)
    check("format 24500 -> '$24,500'", P.format_price(24500) == "$24,500")

    print("eBay HTML (fixture: ebay.html)")
    eb = P.parse_ebay(read("ebay.html"))
    titles = [x["title"] for x in eb]
    check("2 relevant listings", len(eb) == 2, "got %d: %s" % (len(eb), titles))
    check("includes Scout 800 4x4", "1967 International Scout 800 4x4" in titles)
    check("includes Scout 800B", "1971 International Scout 800B" in titles)
    check("drops 'Shop on eBay'", not any("shop on ebay" in t.lower() for t in titles))
    check("drops Ford Bronco", not any("bronco" in t.lower() for t in titles))
    first = next((x for x in eb if "1967" in x["title"]), {})
    check("Scout 800 price = 22000", first.get("price") == 22000, "got %s" % first.get("price"))
    check("Scout 800 url keeps path+query",
          first.get("url") == "https://www.ebay.com/itm/111222333?hash=item5f&var=0",
          "got %s" % first.get("url"))
    check("Scout 800 image parsed",
          first.get("image") == "https://i.ebayimg.com/images/g/abcAAOSw/s-l225.jpg")

    print("Craigslist RSS (fixture: craigslist.xml)")
    cl = P.parse_craigslist(read("craigslist.xml"), "raleigh")
    check("2 relevant listings", len(cl) == 2, "got %d: %s" % (len(cl), [x["title"] for x in cl]))
    s800 = next((x for x in cl if "Scout 800" in x["title"]), {})
    check("Scout 800 price = 18500", s800.get("price") == 18500)
    check("location = Raleigh", s800.get("location") == "Raleigh")
    check("drops Ford Bronco", not any("bronco" in x["title"].lower() for x in cl))

    print("ClassicCars.com JSON-LD (fixture: classiccars.html)")
    cc = P.parse_jsonld_listings(read("classiccars.html"), "classiccars", "ClassicCars.com")
    check("2 relevant listings", len(cc) == 2, "got %d: %s" % (len(cc), [x["title"] for x in cc]))
    cc800 = next((x for x in cc if "Scout 800" in x["title"] and "800A" not in x["title"]), {})
    check("Scout 800 price = 24500", cc800.get("price") == 24500, "got %s" % cc800.get("price"))
    cc800a = next((x for x in cc if "800A" in x["title"]), {})
    check("Scout 800A price = 19995 (AggregateOffer.lowPrice)",
          cc800a.get("price") == 19995, "got %s" % cc800a.get("price"))
    check("drops Chevrolet Camaro", not any("camaro" in x["title"].lower() for x in cc))

    print("Hemmings JSON-LD (fixture: hemmings.html)")
    hm = P.parse_jsonld_listings(read("hemmings.html"), "hemmings", "Hemmings")
    check("2 relevant listings", len(hm) == 2, "got %d: %s" % (len(hm), [x["title"] for x in hm]))
    check("prices = {27500, 33900}", {x["price"] for x in hm} == {27500, 33900},
          "got %s" % sorted(x["price"] for x in hm))
    check("drops Scout II", not any("scout ii" in x["title"].lower() for x in hm))

    print("\n%d passed, %d failed" % (PASS, FAIL))
    sys.exit(1 if FAIL else 0)


if __name__ == "__main__":
    main()
