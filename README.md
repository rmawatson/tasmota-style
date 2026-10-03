# Zigbee Style

A modern dark theme for the Tasmota web UI, installed as a Tasmota extension (`.tapp`). It restyles
every page, Tasmota's own and the ones added by Berry extensions like
[Zigbee Manager](https://github.com/rmawatson/tasmota-zigbee-manager), without changing the firmware.

## Install

Upload `extensions/tapp/zigbee_style.tapp` to the `.extensions` folder of the device (Tools > Manage File system),
or with the Extension Manager, then restart or start it from Configuration > Extension Manager.

Test build: https://raw.githubusercontent.com/rmawatson/tasmota-zigbee-style/main/extensions/tapp/zigbee_style.tapp

## How it works

Tasmota has no way to add a stylesheet to its pages, but it writes the `WebCanvas` setting, unescaped,
into the style of every page. When the extension starts it sets `WebCanvas` to a value that ends that style
and links `/zbs.css`, a route the extension adds that sends the stylesheet from the tapp. The `WebCanvas`
that was there before is put back when the extension is stopped or uninstalled.

## Building

```
python3 scripts/gen_css.py   # builds raw/zigbee_style/zbs.css from src/zbs.css and src/icons
python3 scripts/gen.py       # builds extensions/tapp/zigbee_style.tapp
```

## Credits

Icons: [Font Awesome Free](https://fontawesome.com) 7.3.1 by @fontawesome, licensed under
[CC BY 4.0](https://creativecommons.org/licenses/by/4.0/) (https://fontawesome.com/license/free).
