# MIT License - Copyright (c) 2026 rmawatson@hotmail.com - See LICENSE file for details
#-  -#

import string
import webserver
import persist
import json

class TmsPalette
    # the colours of Tasmota's WebColor command, in its order. The stylesheet uses them through the
    # --c_ variables Tasmota writes in every page, and works out the rest of its colours from them

    static var names = ["Text", "Background", "Form", "Input text", "Input", "Console text", "Console",
                        "Warning text", "Success text", "Button text", "Button", "Button hover", "Reset button",
                        "Reset button hover", "Save button", "Save button hover", "Timer tab text",
                        "Timer tab", "Title", "Button off"]

    static var presets = [
        ["Midnight", ["#e6edf3", "#0b0f14", "#121821", "#e6edf3", "#0d131b", "#c9d5e3", "#070a0f", "#fbbf24", "#4ade80",
                      "#ffffff", "#2563eb", "#3b82f6", "#dc2626", "#ef4444", "#16a34a", "#22c55e", "#e6edf3", "#212c3b",
                      "#e6edf3", "#263243"]],
        ["Graphite", ["#e4e4e7", "#111113", "#1b1b1f", "#e4e4e7", "#141417", "#d4d4d8", "#0a0a0c", "#fbbf24", "#4ade80",
                      "#ffffff", "#7c3aed", "#8b5cf6", "#dc2626", "#ef4444", "#16a34a", "#22c55e", "#e4e4e7", "#27272a",
                      "#fafafa", "#2c2c33"]],
        ["Ocean", ["#e0f2f1", "#061417", "#0b1f24", "#e0f2f1", "#08181c", "#b2dfdb", "#041013", "#fbbf24", "#34d399",
                   "#ffffff", "#0891b2", "#06b6d4", "#dc2626", "#ef4444", "#059669", "#10b981", "#e0f2f1", "#12323a",
                   "#ecfeff", "#16343b"]],
        ["Ember", ["#f5e9e2", "#130d0b", "#1d1512", "#f5e9e2", "#17100e", "#e7d5c9", "#0c0807", "#fbbf24", "#4ade80",
                   "#ffffff", "#ea580c", "#f97316", "#b91c1c", "#dc2626", "#16a34a", "#22c55e", "#f5e9e2", "#3a2a24",
                   "#fff7ed", "#33241f"]],
        ["Daylight", ["#1f2937", "#f3f5f8", "#ffffff", "#1f2937", "#f8fafc", "#1f2937", "#f8fafc", "#b45309", "#15803d",
                      "#ffffff", "#2563eb", "#1d4ed8", "#dc2626", "#b91c1c", "#16a34a", "#15803d", "#ffffff", "#64748b",
                      "#111827", "#94a3b8"]],
        ["Tasmota dark", ["#eaeaea", "#252525", "#4f4f4f", "#000000", "#dddddd", "#65c115", "#1f1f1f", "#ff5661", "#008000",
                          "#faffff", "#1fa3ec", "#0e70a4", "#d43535", "#931f1f", "#47c266", "#5aaf6f", "#faffff", "#999999",
                          "#eaeaea", "#08405e"]],
        ["Tasmota light", ["#000000", "#ffffff", "#f2f2f2", "#000000", "#ffffff", "#000000", "#ffffff", "#ff0000", "#008000",
                           "#ffffff", "#1fa3ec", "#0e70a4", "#d43535", "#931f1f", "#47c266", "#5aaf6f", "#ffffff", "#999999",
                           "#000000", "#a1d9f7"]]
    ]
    static var default_preset = "Midnight"

    # the colours tasmota uses now, lower case #rrggbb as WebColor answers, or nil
    static def colors()
        var result = tasmota.cmd("WebColor", true)
        var colors = result != nil ? result.find("WebColor") : nil
        if !isinstance(colors, list) || size(colors) != size(_class.names)
            return nil
        end
        return colors
    end

    static def set_colors(colors)
        tasmota.cmd("WebColor " + json.dump({"WebColor": colors}), true)
        return _class.colors() == colors
    end

    static def valid(color)
        if type(color) != "string" || size(color) != 7 || color[0] != "#"
            return false
        end
        for index : 1..6
            if string.find("0123456789abcdef", color[index]) < 0
                return false
            end
        end
        return true
    end

    static def valid_list(colors)
        if !isinstance(colors, list) || size(colors) != size(_class.names)
            return false
        end
        for color : colors
            if !_class.valid(color)
                return false
            end
        end
        return true
    end

    static def preset(name)
        for preset : _class.presets
            if preset[0] == name
                return preset[1]
            end
        end
        return nil
    end

    static def preset_name(colors)
        for preset : _class.presets
            if preset[1] == colors
                return preset[0]
            end
        end
        return nil
    end

    # true when the colour is light, the browser's own controls then use their light colours
    static def light(color)
        var rgb = bytes(color[1..6])
        return (rgb[0] * 299 + rgb[1] * 587 + rgb[2] * 114) / 1000 > 140
    end
end

class TmsManager
    # the Tasmota Style Manager page, from a button on the configuration page. It sets the colours
    # with the WebColor command, from a preset or one by one

    static var url = "/tms"
    static var swatches = [1, 2, 0, 10, 14, 12]     # background, form, text, button, save and reset button

    var message         # [text, success], shown once on the next page

    def page()
        if !webserver.check_privileged_access() return nil end
        var colors = TmsPalette.colors()

        webserver.content_start("Tasmota Style")
        webserver.content_send_style()
        webserver.content_send("<div style='padding:0px 5px;text-align:center;'><h3><hr>Tasmota Style Manager<hr></h3></div>")
        if self.message != nil
            var message_class = self.message[1] ? "tsm" : "tsm tse"
            webserver.content_send(f"<p class='{message_class}'>{webserver.html_escape(self.message[0])}</p>")
            self.message = nil
        end

        var current = colors != nil ? TmsPalette.preset_name(colors) : nil
        webserver.content_send("<fieldset><legend><b>&nbsp;Presets&nbsp;</b></legend><form method='post' action='tms' class='tsp'>")
        for preset : self.presets()
            var swatches = ""
            for index : self.swatches
                swatches += f"<i style='background:{preset[1][index]}'></i>"
            end
            var name = webserver.html_escape(preset[0])
            var mark = preset[0] == current ? "<small>Current</small>" : ""
            webserver.content_send(f"<button name='preset' value='{name}'><span>{swatches}</span>{name}{mark}</button>")
        end
        webserver.content_send("</form></fieldset><p></p>")

        if colors != nil
            webserver.content_send("<fieldset><legend><b>&nbsp;Colours&nbsp;</b></legend><form method='post' action='tms'><div class='tsg'>")
            for index : 0..size(colors) - 1
                webserver.content_send(f"<label><input type='color' name='c{index + 1}' value='{colors[index]}'>{TmsPalette.names[index]}</label>")
            end
            webserver.content_send("</div><br><button name='save' class='button bgrn'>Save</button></form></fieldset>")
        end
        webserver.content_button(webserver.BUTTON_CONFIGURATION)
        webserver.content_stop()
    end

    # the presets, and the colours there were before Tasmota Style when they are not one of them
    def presets()
        var before = persist.find("tms_colors_before")
        if TmsPalette.valid_list(before) && TmsPalette.preset_name(before) == nil
            return TmsPalette.presets + [["Before Tasmota Style", before]]
        end
        return TmsPalette.presets
    end

    def page_action()
        if !webserver.check_privileged_access() return nil end
        try
            if webserver.has_arg("preset")
                self.message = self.apply_preset(webserver.arg("preset"))
            elif webserver.has_arg("save")
                self.message = self.save_colors()
            end
        except .. as e, m
            self.message = [f"{e}, {m}", false]
        end
        webserver.redirect(self.url)
    end

    # returns [message, success]
    def apply_preset(name)
        var colors = nil
        for preset : self.presets()
            if preset[0] == name
                colors = preset[1]
            end
        end
        if colors == nil
            return [f"There is no preset '{name}'", false]
        end
        if !TmsPalette.set_colors(colors)
            return ["Unable to set the colours", false]
        end
        return [f"{name} applied", true]
    end

    def save_colors()
        var colors = []
        for index : 1..size(TmsPalette.names)
            var color = string.tolower(str(webserver.arg(f"c{index}")))
            if !TmsPalette.valid(color)
                return [f"{TmsPalette.names[index - 1]} is not a colour", false]
            end
            colors.push(color)
        end
        if !TmsPalette.set_colors(colors)
            return ["Unable to set the colours", false]
        end
        return ["Colours saved", true]
    end
end

class TmsExtension
    # Tasmota has no way to add a stylesheet to its pages, but it writes the WebCanvas setting
    # unescaped into the style of every page, as body{background:<WebCanvas> 0 0 / cover no-repeat fixed;}
    # The theme sets WebCanvas to the background tasmota would have used, followed by the end of
    # that style, a link to the stylesheet served from the tapp and the start of a style that takes
    # the rest of the line. The WebCanvas there was before is put back when the extension stops.
    #
    # The colours are Tasmota's own, set with WebColor. The colours there were before are kept in
    # persist and put back when the extension stops, the theme's colours are kept until it starts again.

    static var url = "/tms.css"
    static var link = "}</style><link rel=stylesheet href=/tms.css><style>:root{--tms:1"
    static var link_start = "}</style><link rel=stylesheet href=/tms.css>"
    # the link of the test builds, named Zigbee Style, replaced when the theme is applied
    static var old_link_starts = ["}</style><link rel=stylesheet href=/zbs.css>"]
    static var canvas_options = " 0 0 / cover no-repeat fixed"
    static var default_background = "var(--c_bg)"
    static var chunk_size = 2048

    var archive         # the tapp the stylesheet is read from, ex: /.extensions/tasmota_style.tapp
    var routes_added
    var manager

    def init()
        var wd = tasmota.wd
        self.archive = string.endswith(wd, "#") ? wd[0..-2] : wd
        self.routes_added = false
        self.manager = TmsManager()
        tasmota.add_driver(self)
        # tasmota only sends web_add_handler once, when the web server starts. if the extension
        # is started later, from the extension manager, the routes are added straight away
        if webserver.state() != webserver.HTTP_OFF
            self.web_add_handler()
        end
        self.apply_colors()
        self.apply()
    end

    def unload()
        tasmota.remove_driver(self)
        if self.routes_added
            self.routes_added = false
            try
                webserver.remove_route(self.url, webserver.HTTP_GET)
                webserver.remove_route(self.manager.url, webserver.HTTP_GET)
                webserver.remove_route(self.manager.url, webserver.HTTP_POST)
            except .. as e, m
                tasmota.log(f"TMS: unable to remove the pages - {e} {m}", 2)
            end
        end
        self.restore()
        self.restore_colors()
    end

    def web_add_handler()
        if self.routes_added
            return
        end
        webserver.on(self.url, / -> self.send_css(), webserver.HTTP_GET)
        webserver.on(self.manager.url, / -> self.manager.page(), webserver.HTTP_GET)
        webserver.on(self.manager.url, / -> self.manager.page_action(), webserver.HTTP_POST)
        self.routes_added = true
    end

    def web_add_config_button()
        webserver.content_send("<p></p><form id=but_tms style='display:block;' action='tms' method='get'><button>Tasmota Style Manager</button></form>")
    end

    # ---------------------------------------------------------------- WebColor

    def apply_colors()
        if persist.contains("tms_colors_before")        # applied before the device restarted
            return
        end
        var before = TmsPalette.colors()
        if before == nil
            tasmota.log("TMS: unable to read WebColor", 1)
            return
        end
        var colors = persist.find("tms_colors")
        if !TmsPalette.valid_list(colors)
            colors = TmsPalette.preset(TmsPalette.default_preset)
        end
        persist.tms_colors_before = before
        persist.save()
        if !TmsPalette.set_colors(colors)
            tasmota.log("TMS: unable to set WebColor", 1)
        end
    end

    def restore_colors()
        var before = persist.find("tms_colors_before")
        if before == nil
            return
        end
        var colors = TmsPalette.colors()
        if colors != nil
            persist.tms_colors = colors
        end
        if TmsPalette.valid_list(before) && !TmsPalette.set_colors(before)
            tasmota.log("TMS: unable to restore WebColor", 1)
        end
        persist.remove("tms_colors_before")
        persist.save()
    end

    # ---------------------------------------------------------------- WebCanvas

    static def canvas()
        var result = tasmota.cmd("WebCanvas", true)
        if result == nil
            return ""
        end
        return str(result.find("WebCanvas", ""))
    end

    # where the link starts in the canvas, or -1
    static def link_position(canvas)
        for link_start : [_class.link_start] + _class.old_link_starts
            var position = string.find(canvas, link_start)
            if position >= 0
                return position
            end
        end
        return -1
    end

    static def themed(canvas)
        return _class.link_position(canvas) >= 0
    end

    # the WebCanvas that was set before the theme
    static def original(canvas)
        var position = _class.link_position(canvas)
        if position < 0
            return canvas
        end
        var background = position > 0 ? canvas[0..position - 1] : ""
        if background == _class.default_background
            return ""
        end
        if string.endswith(background, _class.canvas_options)
            return background[0..-(size(_class.canvas_options) + 1)]
        end
        return background
    end

    # the WebCanvas that links the stylesheet. the original background is kept in front of it,
    # tasmota still draws it if the stylesheet can not be loaded
    static def theme_canvas(original)
        var background = original == "" ? _class.default_background : original + _class.canvas_options
        return background + _class.link
    end

    static def set_canvas(value)
        tasmota.cmd("WebCanvas " + (value == "" ? "0" : value), true)
        return _class.canvas() == value
    end

    def apply()
        var current = self.canvas()
        var wanted = self.theme_canvas(self.original(current))
        if current == wanted
            return true
        end
        if !self.set_canvas(wanted)
            tasmota.log("TMS: unable to set WebCanvas, the settings have no room for it. The theme is not shown", 1)
            return false
        end
        tasmota.log("TMS: theme applied", 2)
        return true
    end

    def restore()
        var current = self.canvas()
        if !self.themed(current)
            return true
        end
        if !self.set_canvas(self.original(current))
            tasmota.log("TMS: unable to restore WebCanvas", 1)
            return false
        end
        tasmota.log("TMS: theme removed", 2)
        return true
    end

    # ---------------------------------------------------------------- stylesheet

    # the extension manager renames the tapp to .tapp_ when auto-run is turned off, and back
    def open_css()
        var archives = [self.archive]
        if size(self.archive)
            archives.push(string.endswith(self.archive, "_") ? self.archive[0..-2] : self.archive + "_")
        end
        for archive : archives
            try
                var css_file = open(size(archive) ? archive + "#tms.css" : "tms.css")
                self.archive = archive
                return css_file
            except ..
            end
        end
        return nil
    end

    # tasmota sends every response with no-cache, the stylesheet is sent on every page. The
    # browser's own controls, and the shadows, follow the background colour, added at the end
    def send_css()
        var css_file = self.open_css()
        if css_file == nil
            tasmota.log(f"TMS: unable to open tms.css in '{self.archive}'", 2)
            webserver.content_open(404, "text/plain")
            webserver.content_send("tms.css not found")
            webserver.content_close()
            return
        end
        webserver.content_open(200, "text/css")
        try
            while true
                var chunk = css_file.read(self.chunk_size)
                if !size(chunk)
                    break
                end
                webserver.content_send(chunk)
            end
            var colors = TmsPalette.colors()
            if colors != nil && TmsPalette.light(colors[1])
                webserver.content_send(":root{color-scheme:light;--ts-shadow:0 1px 3px rgba(0,0,0,.08)}")
            else
                webserver.content_send(":root{color-scheme:dark}")
            end
        except .. as e, m
            tasmota.log(f"TMS: unable to send tms.css - {e} {m}", 2)
        end
        css_file.close()
        webserver.content_close()
    end
end

return TmsExtension()
