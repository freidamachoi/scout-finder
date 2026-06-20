"""Entry point for the GitHub Actions run.

  python -m scout_finder.run

Fetches the automated sources live, diffs against committed state (data/seen.json) to
find genuinely-new listings, then writes:
  public/index.html      -> published to GitHub Pages
  out/issue.md           -> GitHub Issue body (full snapshot)
  out/new.md             -> issue comment (only when there are new listings)
  out/has_new            -> "1" if there are new listings (read by the workflow)
  data/seen.json         -> updated state (committed back by the workflow)
"""
import datetime
import json
import os

from . import fetch, render

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
STATE = os.path.join(ROOT, "data", "seen.json")
PUBLIC = os.path.join(ROOT, "public")
OUT = os.path.join(ROOT, "out")

# Drop remembered listings after this many days so state can't grow forever.
RETAIN_DAYS = 90


def _load_state():
    try:
        with open(STATE, encoding="utf-8") as f:
            return json.load(f)
    except (FileNotFoundError, json.JSONDecodeError):
        return {}


def _save_state(state):
    os.makedirs(os.path.dirname(STATE), exist_ok=True)
    with open(STATE, "w", encoding="utf-8") as f:
        json.dump(state, f, indent=1, sort_keys=True)


def _write(path, text):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        f.write(text)


def main():
    regions = os.environ.get("CL_REGIONS", "").split(",")
    regions = [r.strip() for r in regions if r.strip()] or None

    now = datetime.datetime.now(datetime.timezone.utc)
    stamp = now.strftime("%Y-%m-%d %H:%M")
    today = now.date().isoformat()

    listings, errors = fetch.fetch_all(regions)

    state = _load_state()
    new_urls = set()
    for l in listings:
        if l["url"] not in state:
            new_urls.add(l["url"])
            state[l["url"]] = {"title": l["title"], "first_seen": today}
        else:
            state[l["url"]]["last_seen"] = today

    # Prune stale entries.
    cutoff = (now - datetime.timedelta(days=RETAIN_DAYS)).date().isoformat()
    for url in list(state.keys()):
        seen_day = state[url].get("last_seen") or state[url].get("first_seen", today)
        if seen_day < cutoff:
            del state[url]

    new_listings = [l for l in listings if l["url"] in new_urls]
    print("New this run: %d" % len(new_listings))

    _write(os.path.join(PUBLIC, "index.html"),
           render.page_html(listings, new_urls, errors, stamp))
    _write(os.path.join(OUT, "issue.md"),
           render.issue_markdown(listings, new_urls, errors, stamp))
    if new_listings:
        _write(os.path.join(OUT, "new.md"),
               render.new_comment_markdown(new_listings, stamp))
    _write(os.path.join(OUT, "has_new"), "1" if new_listings else "0")

    _save_state(state)
    print("Wrote public/index.html, out/issue.md%s"
          % (", out/new.md" if new_listings else ""))


if __name__ == "__main__":
    main()
