#!/usr/bin/env python3
"""End-to-end test of the GitHub Actions pipeline WITHOUT network.

Injects fixture-parsed listings in place of the live fetch, then runs the pipeline
twice to prove: (1) first run flags everything new, renders cards, writes new.md;
(2) second run flags nothing new. Validates state diffing + rendering + outputs.

Run:  python3 scripts/test_pipeline.py
"""
import os
import sys

ROOT = os.path.join(os.path.dirname(__file__), "..")
sys.path.insert(0, ROOT)

from scout_finder import parsers as P, fetch, run  # noqa: E402

FIX = os.path.join(ROOT, "ScoutFinderTests", "Fixtures")
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


def read_out(rel):
    with open(os.path.join(ROOT, rel), encoding="utf-8") as f:
        return f.read()


def main():
    # Build a realistic combined result set from the fixtures.
    listings = []
    listings += P.parse_ebay(read("ebay.html"))
    listings += P.parse_craigslist(read("craigslist.xml"), "raleigh")
    listings += P.parse_jsonld_listings(read("classiccars.html"), "classiccars", "ClassicCars.com")
    listings += P.parse_jsonld_listings(read("hemmings.html"), "hemmings", "Hemmings")
    expected = len(listings)  # 2 + 2 + 2 + 2 = 8

    # Replace the live fetch with our fixture set.
    fetch.fetch_all = lambda regions=None: (listings, [])

    # Fresh state.
    if os.path.exists(run.STATE):
        os.remove(run.STATE)

    print("Run 1 (cold state — everything is new)")
    run.main()
    check("found all %d fixture listings" % expected,
          read_out("out/has_new") == "1")
    new_md = read_out("out/new.md")
    check("new.md lists 8 new", new_md.count("\n- ") == expected,
          "got %d" % new_md.count("\n- "))
    issue = read_out("out/issue.md")
    check("issue has 'New since last run'", "New since last run" in issue)
    check("issue includes manual guide", "Search these manually" in issue)
    check("issue includes Facebook (login)", "Facebook Marketplace" in issue)
    page = read_out("public/index.html")
    check("page renders a Scout card", "International Scout 800" in page)
    check("page has NEW badge", "class=badge>NEW" in page)
    check("page includes manual links", "Bring a Trailer" in page)

    print("Run 2 (warm state — nothing new)")
    run.main()
    check("has_new is 0", read_out("out/has_new") == "0")
    issue2 = read_out("out/issue.md")
    check("issue still shows current results", "Current automated results (8)" in issue2)
    check("issue has no new-section", "New since last run" not in issue2)

    print("\n%d passed, %d failed" % (PASS, FAIL))
    # Clean up generated state so it isn't committed from a local test run.
    for p in ("data/seen.json", "out/has_new", "out/new.md", "out/issue.md",
              "public/index.html"):
        fp = os.path.join(ROOT, p)
        if os.path.exists(fp):
            os.remove(fp)
    sys.exit(1 if FAIL else 0)


if __name__ == "__main__":
    main()
