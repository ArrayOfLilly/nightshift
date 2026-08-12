#!/usr/bin/env python3
"""
manual_build.py — Converts countdownApp-manual.md to a self-contained HTML file.
All referenced images are base64-encoded and embedded inline.
Usage: python3 manual_build.py
Output: /Users/ArrayOfLilly/tools/countdownApp/docs/countdownApp-manual.html
"""

import re
import base64
import mimetypes
from pathlib import Path

MANUAL_MD   = Path("/Users/ArrayOfLilly/tools/countdownApp/docs/countdownApp-manual.md")
OUTPUT_HTML = Path("/Users/ArrayOfLilly/tools/countdownApp/docs/countdownApp-manual.html")

# h2 headings that should trigger a page break before them (main chapters only)
PAGE_BREAK_H2 = {
    "Calculate Mode",
    "Countdown Mode",
    "Snippets",
    "Tips",
}

CSS = """
    body {
        font-family: -apple-system, 'Helvetica Neue', sans-serif;
        font-size: 15px;
        line-height: 1.7;
        max-width: 820px;
        margin: 48px auto;
        padding: 0 24px 80px;
        color: #1a1a1a;
        background: #fff;
    }
    h1 { font-size: 2em; border-bottom: 2px solid #e0a020; padding-bottom: 10px; }
    h2 { font-size: 1.4em; margin-top: 2.5em; border-bottom: 1px solid #ddd; padding-bottom: 6px; }
    h3 { font-size: 1.1em; margin-top: 1.8em; color: #333; }
    h4 { font-size: 1em; margin-top: 1.4em; color: #555; }
    code { background: #f4f4f4; padding: 2px 5px; border-radius: 4px; font-size: 0.88em; }
    pre  { background: #f4f4f4; padding: 14px 18px; border-radius: 6px; overflow-x: auto; }
    pre code { background: none; padding: 0; }
    table { border-collapse: collapse; width: 100%; margin: 1em 0; }
    th, td { border: 1px solid #ddd; padding: 8px 12px; text-align: left; }
    th { background: #f9f9f9; font-weight: 600; }
    tr:nth-child(even) td { background: #fafafa; }
    img.screenshot {
        display: block;
        max-width: 50%;
        border-radius: 10px;
        box-shadow: 0 4px 20px rgba(0,0,0,0.15);
        margin: 20px auto;
    }
    .caption {
        text-align: center;
        font-size: 0.82em;
        color: #888;
        font-style: italic;
        margin-top: -12px;
        margin-bottom: 24px;
    }
    hr { border: none; border-top: 1px solid #e8e8e8; margin: 2.5em 0; }
    li { margin: 4px 0; }

    /* ── Print / PDF styles ── */
    @media print {
        @page {
            size: A4;
            margin: 20mm 18mm 22mm 18mm;
        }

        body {
            max-width: 100%;
            margin: 0;
            padding: 0;
            font-size: 11pt;
            line-height: 1.55;
            color: #000;
            background: #fff;
        }

        /* headings: never orphaned at bottom of page */
        h1, h2, h3, h4 {
            page-break-after: avoid;
            page-break-inside: avoid;
        }

        /* only main chapter h2s start on a new page (set via class) */
        h2.chapter {
            page-break-before: always;
        }
        h1 + h2.chapter {
            page-break-before: avoid;
        }

        /* keep image + caption together, never split across pages */
        img.screenshot {
            display: block;
            max-width: 50%;
            margin: 12pt auto 4pt;
            page-break-inside: avoid;
            box-shadow: none;
            border-radius: 0;
            border: 1px solid #ccc;
        }
        .caption {
            page-break-before: avoid;
            page-break-inside: avoid;
            margin-top: 2pt;
            margin-bottom: 14pt;
            font-size: 8.5pt;
            color: #555;
            font-style: italic;
        }

        /* keep list items together where possible */
        li { page-break-inside: avoid; }

        /* tables: header repeats on each page */
        thead { display: table-header-group; }
        tr    { page-break-inside: avoid; }

        /* code blocks */
        pre {
            white-space: pre-wrap;
            word-break: break-all;
            page-break-inside: avoid;
            font-size: 9pt;
        }

        hr { border-top: 0.5pt solid #bbb; }
        a  { color: #000; text-decoration: none; }
    }
"""

def embed_image(path_str: str, md_dir: Path) -> str:
    img_path = (md_dir / path_str).resolve()
    if not img_path.exists():
        print(f"  WARNING: image not found: {img_path}")
        return ""
    mime, _ = mimetypes.guess_type(str(img_path))
    mime = mime or "image/png"
    data = base64.b64encode(img_path.read_bytes()).decode("ascii")
    return f"data:{mime};base64,{data}"


def inline(text: str, md_dir: Path) -> str:
    # bold must come before italic to avoid conflict
    text = re.sub(r'\*\*(.+?)\*\*', r'<strong>\1</strong>', text)
    # italic: *text* but not **text** (already replaced above)
    text = re.sub(r'\*([^*]+?)\*', r'<em>\1</em>', text)
    # inline code
    text = re.sub(r'`([^`]+)`', r'<code>\1</code>', text)
    # images  ![alt](path)
    def img_replace(m):
        alt  = m.group(1)
        path = m.group(2)
        uri  = embed_image(path, md_dir)
        if not uri:
            return f'[image not found: {path}]'
        return (f'<img class="screenshot" src="{uri}" alt="{alt}">')
    text = re.sub(r'!\[([^\]]*)\]\(([^)]+)\)', img_replace, text)
    return text


def md_to_html(md: str, md_dir: Path) -> str:
    lines  = md.splitlines()
    html   = []
    i      = 0
    in_ul  = False
    in_ol  = False

    def close_lists():
        nonlocal in_ul, in_ol
        if in_ul:
            html.append("</ul>")
            in_ul = False
        if in_ol:
            html.append("</ol>")
            in_ol = False

    while i < len(lines):
        line = lines[i]

        # fenced code block
        if line.startswith("```"):
            close_lists()
            lang = line[3:].strip()
            code_lines = []
            i += 1
            while i < len(lines) and not lines[i].startswith("```"):
                code_lines.append(lines[i])
                i += 1
            html.append(f'<pre><code class="language-{lang}">'
                        + "\n".join(code_lines) + "</code></pre>")
            i += 1
            continue

        # horizontal rule
        if re.match(r'^-{3,}$', line.strip()):
            close_lists()
            html.append("<hr>")
            i += 1
            continue

        # headings
        m = re.match(r'^(#{1,4})\s+(.*)', line)
        if m:
            close_lists()
            level  = len(m.group(1))
            title  = m.group(2)
            if level == 2 and title in PAGE_BREAK_H2:
                html.append(f'<h2 class="chapter">{inline(title, md_dir)}</h2>')
            else:
                html.append(f'<h{level}>{inline(title, md_dir)}</h{level}>')
            i += 1
            continue

        # GFM table (line starts with |)
        if line.startswith("|"):
            close_lists()
            rows = []
            while i < len(lines) and lines[i].startswith("|"):
                rows.append(lines[i])
                i += 1
            html.append("<table>")
            for ri, row in enumerate(rows):
                cells = [c.strip() for c in row.strip("|").split("|")]
                if ri == 1:   # separator row
                    continue
                tag = "th" if ri == 0 else "td"
                html.append("  <tr>" + "".join(
                    f"<{tag}>{inline(c, md_dir)}</{tag}>" for c in cells) + "</tr>")
            html.append("</table>")
            continue

        # unordered list item
        m = re.match(r'^- (.*)', line)
        if m:
            if in_ol:
                html.append("</ol>")
                in_ol = False
            if not in_ul:
                html.append("<ul>")
                in_ul = True
            html.append(f"  <li>{inline(m.group(1), md_dir)}</li>")
            i += 1
            continue

        # ordered list item
        m = re.match(r'^\d+\.\s+(.*)', line)
        if m:
            if in_ul:
                html.append("</ul>")
                in_ul = False
            if not in_ol:
                html.append("<ol>")
                in_ol = True
            html.append(f"  <li>{inline(m.group(1), md_dir)}</li>")
            i += 1
            continue

        # blank line
        if line.strip() == "":
            close_lists()
            i += 1
            continue

        # italic-only line = caption (paragraph after an image)
        # render as caption div instead of plain <p>
        m_italic = re.match(r'^\*([^*].+[^*])\*$', line.strip())
        if m_italic:
            close_lists()
            html.append(f'<p class="caption">{m_italic.group(1)}</p>')
            i += 1
            continue

        # paragraph
        close_lists()
        html.append(f"<p>{inline(line, md_dir)}</p>")
        i += 1

    close_lists()
    return "\n".join(html)


def main():
    print(f"Reading {MANUAL_MD}")
    md_text = MANUAL_MD.read_text(encoding="utf-8")
    body    = md_to_html(md_text, MANUAL_MD.parent)
    html    = f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>countdownApp — User Manual</title>
<style>{CSS}</style>
</head>
<body>
{body}
</body>
</html>"""
    OUTPUT_HTML.write_text(html, encoding="utf-8")
    print(f"Written → {OUTPUT_HTML}")


if __name__ == "__main__":
    main()
