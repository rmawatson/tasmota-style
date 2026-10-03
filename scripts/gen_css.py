#!/usr/bin/env python3
"""
Stylesheet builder
Builds raw/tasmota_style/tms.css from src/tms.css. Every icon(name) in the source is replaced
by var(--fa-name), and the icon itself, src/icons/name.svg, is added once to :root as a data
url, so an icon used by several rules is only sent once. icon(name) has no colour, it is used
as a mask, icon(name,#fff) is filled with the colour, to be used as a background. The result
is minified, it is read from the tapp and sent to the browser on every page.
Each menu button style in src/buttons is minified to raw/tasmota_style/btn_<style>.css, the
extension adds the chosen one to the end of the stylesheet. They can not use icon().
"""

import re
import sys
from pathlib import Path

SOURCE = Path("src/tms.css")
ICONS = Path("src/icons")
OUTPUT = Path("raw/tasmota_style/tms.css")
BUTTONS = Path("src/buttons")

ATTRIBUTION = ("/*! Icons: Font Awesome Free 7.3.1 by @fontawesome - https://fontawesome.com "
               "License - https://fontawesome.com/license/free (Icons: CC BY 4.0) "
               "Copyright 2026 Fonticons, Inc. */")


def icon_url(name: str, color: str) -> str:
    """Return the icon as a css url(), an svg with only its viewBox and path"""
    svg = (ICONS / f"{name}.svg").read_text(encoding="utf-8")
    view_box = re.search(r'viewBox="([^"]+)"', svg)
    paths = re.findall(r'<path[^>]*\sd="([^"]+)"', svg)
    if not view_box or not paths:
        raise ValueError(f"unable to read the icon '{name}'")
    fill = f" fill='#{color}'" if color else ""
    body = "".join(f"<path{fill} d='{d}'/>" for d in paths)
    data = f"<svg xmlns='http://www.w3.org/2000/svg' viewBox='{view_box.group(1)}'>{body}</svg>"
    for char, code in (("%", "%25"), ("#", "%23"), ("<", "%3C"), (">", "%3E"), ('"', "'")):
        data = data.replace(char, code)
    return f'url("data:image/svg+xml,{data}")'


def minify(css: str) -> str:
    """Remove comments (except /*! */) and whitespace that is not needed. Strings are copied
    as they are"""
    out = []
    i = 0
    while i < len(css):
        char = css[i]
        if char in "\"'":
            end = i + 1
            while css[end] != char:
                end += 2 if css[end] == "\\" else 1
            out.append(css[i:end + 1])
            i = end + 1
        elif css.startswith("/*", i):
            end = css.index("*/", i) + 2
            if css.startswith("/*!", i):
                out.append(css[i:end])
            i = end
        elif char.isspace():
            while i < len(css) and css[i].isspace():
                i += 1
            out.append(" ")
        else:
            out.append(char)
            i += 1
    text = "".join(out)
    # whitespace around these is never needed, outside of strings. the strings were copied
    # as they are, so they are split out again before the spaces are removed
    parts = re.split(r'("(?:[^"\\]|\\.)*"|\'(?:[^\'\\]|\\.)*\'|/\*!.*?\*/)', text, flags=re.S)
    for index in range(0, len(parts), 2):
        part = re.sub(r"\s*([{};,>])\s*", r"\1", parts[index])
        part = re.sub(r":\s+", ":", part)
        parts[index] = part.replace(";}", "}")
    return "".join(parts).strip()


def build():
    source = SOURCE.read_text(encoding="utf-8")
    icons = {}

    def replace(match):
        name, color = match.group(1), (match.group(2) or "").lower()
        variable = f"--fa-{name}-{color}" if color else f"--fa-{name}"
        icons[variable] = (name, color)
        return f"var({variable})"

    # comments are removed first, so an icon() in a comment is not added
    css = re.sub(r"icon\(([a-z0-9-]+)(?:,\s*#([0-9a-fA-F]{3}|[0-9a-fA-F]{6}))?\)", replace, minify(source))
    names = {name for name, _ in icons.values()}
    unused = sorted(path.stem for path in ICONS.glob("*.svg") if path.stem not in names)

    variables = ";".join(f"{variable}:{icon_url(*icon)}" for variable, icon in icons.items())
    result = css + "\n" + ATTRIBUTION + "\n:root{" + variables + "}\n"
    if not result.isascii():
        raise ValueError("the stylesheet must be ascii")
    OUTPUT.write_text(result, encoding="utf-8")

    print(f"Created: {OUTPUT} ({len(result)} bytes, {len(icons)} icons)")
    if unused:
        print(f"Unused icons: {', '.join(unused)}")

    styles = sorted(BUTTONS.glob("*.css"))
    for source in styles:
        style = minify(source.read_text(encoding="utf-8"))
        if "icon(" in style or not style.isascii():
            raise ValueError(f"{source} must be ascii and can not use icon()")
        output = OUTPUT.parent / f"btn_{source.stem}.css"
        output.write_text(style + "\n", encoding="utf-8")
        print(f"Created: {output} ({len(style) + 1} bytes)")
    for output in OUTPUT.parent.glob("btn_*.css"):
        if output.stem[4:] not in [source.stem for source in styles]:
            output.unlink()
            print(f"Removed: {output}")


if __name__ == "__main__":
    try:
        build()
    except (OSError, ValueError) as error:
        print(f"ERROR: {error}")
        sys.exit(1)
