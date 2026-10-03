# Tasmota Style

A modern theme for the Tasmota web UI, installed as a Tasmota extension (`.tapp`). It restyles every page,
Tasmota's own and the ones added by Berry extensions, without changing the firmware. The colours are Tasmota's
own `WebColor` settings, picked from presets or one by one in the Tasmota Style Manager.

<table>
<tr><th>Tasmota</th><th>Tasmota Style</th><th>Tasmota Style Manager</th></tr>
<tr>
<td valign="top"><img src="docs/images/main_before.png" width="260"></td>
<td valign="top"><img src="docs/images/main.png" width="260"></td>
<td valign="top"><img src="docs/images/style_manager.png" width="260"></td>
</tr>
</table>

<table>
<tr><th>Daylight</th><th>Graphite</th><th>Ocean</th><th>Ember</th></tr>
<tr>
<td valign="top"><img src="docs/images/preset_daylight.png" width="195"></td>
<td valign="top"><img src="docs/images/preset_graphite.png" width="195"></td>
<td valign="top"><img src="docs/images/preset_ocean.png" width="195"></td>
<td valign="top"><img src="docs/images/preset_ember.png" width="195"></td>
</tr>
<tr><th>Configuration</th><th>Settings</th><th>Information</th><th>Console</th></tr>
<tr>
<td valign="top"><img src="docs/images/configuration.png" width="195"></td>
<td valign="top"><img src="docs/images/settings.png" width="195"></td>
<td valign="top"><img src="docs/images/information.png" width="195"></td>
<td valign="top"><img src="docs/images/console.png" width="195"></td>
</tr>
</table>

- Pages are a single centred column. The sensors, the information page and every form are cards.
- Menu buttons are rows with a [Font Awesome](https://fontawesome.com) icon and a chevron, Restart and Reset are red.
- The power buttons are coloured when the relay is on and grey when it is off.
- The light sliders have fader handles over Tasmota's colour gradients.
- Inputs have a focus ring, the console and the script editors are monospaced and wider.
- The only movement is a short colour fade on hover and focus. Nothing in the sensor area, which Tasmota
  redraws every couple of seconds, is animated.

## Install

To install this extension in Tasmota, paste the url 

```
https://raw.githubusercontent.com/rmawatson/tasmota-style/refs/heads/main/extensions/
```

into the field at the bottom of the Online Store in `Tools->Extension Manager`, press Enter, and install Tasmota Style
from the list.

Or download 


[tasmota_style.tapp](https://raw.githubusercontent.com/rmawatson/tasmota-style/refs/heads/main/extensions/tapp/tasmota_style.tapp)


and upload it to the `/.extensions` folder of the device with Tools > Manage File system. Start it from
Tools > Extension Manager, or restart the device.

Or in the Berry Scripting console:

```berry
import path
path.mkdir("/.extensions")
tasmota.urlfetch("https://raw.githubusercontent.com/rmawatson/tasmota-style/refs/heads/main/extensions/tapp/tasmota_style.tapp", "/.extensions/tasmota_style.tapp")
tasmota.load("/.extensions/tasmota_style.tapp")
```

Reload the page to see the theme. To go back to Tasmota's own style, press Running (which stops it) or
Uninstall in the Extension Manager.

## Colours

The theme uses the 20 colours of Tasmota's `WebColor` command. The first time it starts it sets them to the
Midnight preset. The colours you had are kept, and put back when the extension stops or is uninstalled. The
theme's colours are kept too, and set again when it starts.

Change them in Configuration > Tasmota Style Manager:

- **Presets** sets all 20 colours at once: Midnight, Graphite, Ocean, Ember, Daylight, and Tasmota's own
  Tasmota dark and Tasmota light. If the colours you had before were not one of them, they are there as
  Before Tasmota Style. The preset in use is marked Current.
- **Colours** shows the 20 colours with a colour picker each, Save sets them.
- **Reset to defaults** sets the colours the theme starts with, the Midnight preset, after asking to confirm.
  Tasmota's own default colours are the Tasmota dark preset.

The `WebColor` command works too, `WebColor11 #2563eb` sets the button colour, and
`WebColor {"WebColor":["#e6edf3","#0b0f14",...]}` all 20. The page shows the colours Tasmota has.

The stylesheet uses Tasmota's colours, and mixes the rest from them: the borders and rows of the cards from
the form and text colours, the dimmer text from the text colour, the icons and links from the button colour.
When the background is light, the browser's own controls (check boxes, drop downs, scroll bars) are light too.

## How it works

Tasmota has no setting for a stylesheet, but it writes the `WebCanvas` setting (the page background) unescaped
into the style in the head of every page:

```
body{background:<WebCanvas> 0 0 / cover no-repeat fixed;}
```

When the extension starts it sets `WebCanvas` to

```
var(--c_bg)}</style><link rel=stylesheet href=/tms.css><style>:root{--tms:1
```

which ends that rule and the style, links `/tms.css`, and opens a style that takes the rest of the line. The
extension adds the `/tms.css` page, which sends the stylesheet from the tapp. A `WebCanvas` you had set is kept
in front of the link, and put back when the extension stops or is uninstalled.

Tasmota's pages use the same markup in every language, so the stylesheet matches them on their form actions
(`cn` for Configuration, `md` for Module, ...) and on the inline styles Tasmota writes. The colours come from
the `--c_bg`, `--c_btn`, ... variables Tasmota writes with the `WebColor` colours in every page.

## Notes

- The stylesheet is about 43 KB, 26 KB of it icons. Tasmota sends every page an extension adds with
  `Cache-Control: no-cache, no-store, must-revalidate`, so the browser loads it again with every page.
- `WebCanvas` shares Tasmota's 699 character settings text area with the other text settings. The theme needs
  75 characters, or 92 plus the length of your own `WebCanvas` if you set one. When it does not fit, the log
  shows `TMS: unable to set WebCanvas, the settings have no room for it. The theme is not shown`.
- Setting `WebCanvas` while the theme runs removes the theme until the extension starts again. It then keeps
  your new value in front of the link, to put back when it stops. The theme draws its own background over it.
- The colours from before the theme are kept in `persist` as `tms_colors_before`, and the theme's colours as
  `tms_colors` while it is stopped.
- If the tapp is deleted from the file system without stopping it first, the link stays in `WebCanvas` and
  the theme's colours stay set. The stylesheet is then not found, and the pages are Tasmota's own with those
  colours. `WebCanvas 0` removes the link, `WebColor 0` sets Tasmota's default colours.
- The theme uses Inter if it is installed, otherwise the system font (Segoe UI, San Francisco, Roboto).
- The mixed colours need `color-mix()` (Chrome and Edge 111, Safari 16.2, Firefox 113 and later), the cards
  around the sensors and the wider console need `:has()`. Icons need CSS masks.
- Menu buttons added by other extensions get a cube icon. To give one its own icon, add a rule like
  `form[action=myext] { --i: icon(puzzle-piece) }` to `src/tms.css`, with the icon in `src/icons`.

## Building

```
python3 scripts/gen_css.py   # builds raw/tasmota_style/tms.css from src/tms.css and src/icons
python3 scripts/gen.py       # builds extensions/tapp/tasmota_style.tapp and extensions/extensions.jsonl
```

`src/tms.css` is the stylesheet, `icon(name)` in it is replaced by `src/icons/name.svg`. The icons are copied
from the `svgs` folder of Font Awesome Free 7.3.1. `scripts/upload.py` uploads a tapp to a device over FTP.

## Credits

Icons: [Font Awesome Free](https://fontawesome.com) 7.3.1 by @fontawesome, licensed under
[CC BY 4.0](https://creativecommons.org/licenses/by/4.0/) (https://fontawesome.com/license/free).

The theme is MIT licensed, see [LICENSE](LICENSE).
