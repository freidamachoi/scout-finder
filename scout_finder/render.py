"""Render fetched listings + the manual-source guide into a mobile-friendly HTML page
(GitHub Pages) and Markdown (GitHub Issue body / comment)."""
import html as _html
from . import sources as src

# ----------------------------------------------------------------- helpers

def _price(listing):
    return listing.get("price_text") or "Ask"

def _by_source(listings):
    groups = {}
    for l in listings:
        groups.setdefault(l["source_name"], []).append(l)
    return sorted(groups.items(), key=lambda kv: kv[0].lower())

# ----------------------------------------------------------------- Markdown (issue)

def issue_markdown(listings, new_urls, errors, generated_at):
    lines = ["## 🚜 Scout Finder", "",
             "_Updated %s UTC_" % generated_at, ""]
    new = [l for l in listings if l["url"] in new_urls]
    if new:
        lines.append("### 🆕 New since last run (%d)" % len(new))
        for l in new:
            lines.append("- **[%s](%s)** — %s · _%s_"
                         % (l["title"], l["url"], _price(l), l["source_name"]))
        lines.append("")

    lines.append("### Current automated results (%d)" % len(listings))
    if listings:
        for name, items in _by_source(listings):
            lines.append("**%s**" % name)
            for l in items:
                tag = " 🆕" if l["url"] in new_urls else ""
                lines.append("- [%s](%s) — %s%s" % (l["title"], l["url"], _price(l), tag))
            lines.append("")
    else:
        lines.append("_No automated results this run "
                     "(sites may be temporarily blocking the search). "
                     "Use the guided links below._")
        lines.append("")

    lines.append("### 🔎 Search these manually")
    lines.append("Login/auction/JS sites that can't be auto-searched — tap to run the "
                 "prebuilt search:")
    lines.append("")
    for cat, items in src.grouped_manual():
        lines.append("**%s**" % cat)
        for (_id, name, _cat, _kind, url, criteria, login, notes) in items:
            extra = " 🔒" if login else ""
            note = (" — %s" % notes) if notes else ""
            lines.append("- [%s](%s)%s%s" % (name, url, extra, note))
        lines.append("")

    if errors:
        lines.append("<details><summary>Source errors this run (%d)</summary>"
                     % len(errors))
        lines.append("")
        for e in errors:
            lines.append("- `%s`" % e)
        lines.append("</details>")
    return "\n".join(lines)

def new_comment_markdown(new_listings, generated_at):
    lines = ["### 🆕 %d new Scout listing%s — %s UTC"
             % (len(new_listings), "" if len(new_listings) == 1 else "s", generated_at), ""]
    for l in new_listings:
        lines.append("- **[%s](%s)** — %s · _%s_"
                     % (l["title"], l["url"], _price(l), l["source_name"]))
    return "\n".join(lines)

# ----------------------------------------------------------------- HTML (Pages)

_CSS = """
:root{--fg:#1c1c1e;--muted:#6b6b70;--bg:#f5f5f7;--card:#fff;--accent:#b8541a;--new:#0a7d28}
*{box-sizing:border-box}
body{margin:0;font:16px/1.45 -apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,sans-serif;
 color:var(--fg);background:var(--bg);-webkit-text-size-adjust:100%}
header{background:var(--accent);color:#fff;padding:18px 16px}
header h1{margin:0;font-size:20px}
header p{margin:4px 0 0;font-size:13px;opacity:.9}
main{max-width:760px;margin:0 auto;padding:16px}
h2{font-size:16px;margin:24px 0 10px;border-bottom:1px solid #ddd;padding-bottom:6px}
.card{background:var(--card);border-radius:12px;padding:12px 14px;margin:8px 0;
 box-shadow:0 1px 3px rgba(0,0,0,.06);display:flex;gap:12px;align-items:center}
.card img{width:64px;height:64px;border-radius:8px;object-fit:cover;background:#e6eef7;flex:none}
.card a{color:inherit;text-decoration:none}
.card .t{font-weight:600;font-size:15px}
.card .m{color:var(--muted);font-size:13px;margin-top:2px}
.price{color:var(--new);font-weight:700}
.badge{display:inline-block;background:var(--new);color:#fff;font-size:11px;font-weight:700;
 border-radius:6px;padding:1px 6px;margin-right:6px;vertical-align:middle}
.src{display:inline-block;background:#eee;border-radius:6px;padding:1px 6px;font-size:12px;color:#555}
.manual a{display:block;background:var(--card);border-radius:10px;padding:11px 14px;margin:6px 0;
 text-decoration:none;color:inherit;box-shadow:0 1px 2px rgba(0,0,0,.05)}
.manual .lock{color:var(--accent);font-size:12px}
.manual .n{color:var(--muted);font-size:12px;margin-top:2px}
.empty{color:var(--muted);font-style:italic;padding:8px 0}
footer{color:var(--muted);font-size:12px;text-align:center;padding:24px 16px}
"""

def _esc(s):
    return _html.escape(s or "")

def page_html(listings, new_urls, errors, generated_at):
    new = [l for l in listings if l["url"] in new_urls]
    out = ["<!doctype html><html lang=en><head><meta charset=utf-8>",
           "<meta name=viewport content='width=device-width,initial-scale=1'>",
           "<title>Scout Finder</title><style>%s</style></head><body>" % _CSS,
           "<header><h1>🚜 Scout Finder</h1>",
           "<p>International Scout 80 / 800 / 800A / 800B &middot; updated %s UTC</p>"
           "</header><main>" % _esc(generated_at)]

    if new:
        out.append("<h2>🆕 New since last run (%d)</h2>" % len(new))
        for l in new:
            out.append(_card(l, True))

    out.append("<h2>Current results (%d)</h2>" % len(listings))
    if listings:
        for l in listings:
            out.append(_card(l, l["url"] in new_urls))
    else:
        out.append("<div class=empty>No automated results this run — sites may be "
                   "temporarily blocking the search. Use the guided links below.</div>")

    out.append("<h2>🔎 Search these manually</h2>")
    out.append("<div class=manual>")
    for cat, items in src.grouped_manual():
        out.append("<h2 style='border:0;margin:18px 0 6px;font-size:14px'>%s</h2>" % _esc(cat))
        for (_id, name, _cat, _kind, url, criteria, login, notes) in items:
            lock = " <span class=lock>🔒 login</span>" if login else ""
            note = ("<div class=n>%s</div>" % _esc(notes)) if notes else ""
            out.append("<a href='%s' target=_blank rel=noopener><strong>%s</strong>%s"
                       "<div class=n>%s</div>%s</a>"
                       % (_esc(url), _esc(name), lock, _esc(criteria), note))
    out.append("</div>")

    if errors:
        out.append("<h2>Source errors this run</h2><div class=empty>"
                   + "<br>".join(_esc(e) for e in errors) + "</div>")

    out.append("<footer>Generated by GitHub Actions · daily + on-demand</footer>")
    out.append("</main></body></html>")
    return "\n".join(out)

def _card(l, is_new):
    img = ("<img src='%s' alt=''>" % _esc(l["image"])) if l.get("image") \
        else "<img alt='' src=\"data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg'/%3E\">"
    badge = "<span class=badge>NEW</span>" if is_new else ""
    return ("<div class=card>%s<div><a href='%s' target=_blank rel=noopener>"
            "<div class=t>%s%s</div></a>"
            "<div class=m><span class=price>%s</span> &middot; "
            "<span class=src>%s</span></div></div></div>"
            % (img, _esc(l["url"]), badge, _esc(l["title"]),
               _esc(_price(l)), _esc(l["source_name"])))
