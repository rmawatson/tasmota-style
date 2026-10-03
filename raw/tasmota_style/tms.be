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
        ["Charcoal", ["#e6e7e9", "#121314", "#1b1c1e", "#e6e7e9", "#151618", "#cfd1d4", "#0d0e0f", "#fbbf24", "#4ade80",
                      "#ffffff", "#1786e8", "#3fa0f2", "#dc2626", "#ef4444", "#16a34a", "#22c55e", "#e6e7e9", "#2b2d30",
                      "#f1f2f3", "#2e3033"]],
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
    static var default_preset = "Charcoal"

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

class TmsButtons
    # the styles of the menu rows. Each is a file in the tapp, btn_<style>.css, added to the end of
    # the stylesheet, Plain has none. The style in use is kept in persist

    static var styles = [["edge", "Accent edge"], ["tinted", "Tinted"], ["solid", "Solid"], ["tiles", "Icon tiles"],
                         ["fade", "Fade"], ["plain", "Plain"]]
    static var default_style = "edge"

    static def name(style)
        for entry : _class.styles
            if entry[0] == style
                return entry[1]
            end
        end
        return nil
    end

    static def current()
        var style = persist.find("tms_buttons")
        return _class.name(style) != nil ? style : _class.default_style
    end

    static def set(style)
        if persist.find("tms_buttons") != style
            persist.tms_buttons = style
            persist.save()
        end
    end
end

class TmsSettings
    # the settings of the theme: the 20 WebColor colours, set from a preset or one by one, and the
    # style of the menu buttons. The Tasmota Style Manager and the Tsm commands change them here.
    # As json, {"version":1,"colors":[...],"buttons":"edge"}, they are served on /tms.json for
    # Load from url on another device, saved to a file, copied, and loaded back with Import

    static var url = "/tms.json"
    static var version = 1
    static var keys = ["version", "colors", "buttons"]
    static var before_name = "Before Tasmota Style"
    static var url_timeouts = [3000, 2000]      # http and connect, in ms

    # the presets, and the colours there were before Tasmota Style when they are not one of them
    static def presets()
        var before = persist.find("tms_colors_before")
        if TmsPalette.valid_list(before) && TmsPalette.preset_name(before) == nil
            return TmsPalette.presets + [[_class.before_name, before]]
        end
        return TmsPalette.presets
    end

    # the name of the preset with these colours, or nil
    static def preset_name(colors)
        for preset : _class.presets()
            if preset[1] == colors
                return preset[0]
            end
        end
        return nil
    end

    # names are compared without case and spaces, the commands take tasmotadark for Tasmota dark
    static def same(name, other)
        return string.tolower(string.replace(str(name), " ", "")) == string.tolower(string.replace(str(other), " ", ""))
    end

    # [name, colours] of a preset, or nil
    static def find_preset(name)
        for preset : _class.presets()
            if _class.same(preset[0], name)
                return preset
            end
        end
        return nil
    end

    # a menu button style, by its id or its name, or nil
    static def find_buttons(style)
        for entry : TmsButtons.styles
            if _class.same(entry[0], style) || _class.same(entry[1], style)
                return entry[0]
            end
        end
        return nil
    end

    # the settings as json, in the order they are read
    static def export()
        var pairs = [["version", _class.version], ["colors", TmsPalette.colors()], ["buttons", TmsButtons.current()]]
        var members = []
        for pair : pairs
            members.push(json.dump(pair[0]) + ":" + json.dump(pair[1]))
        end
        return "{" + members.concat(",") + "}"
    end

    # the rest return [message, success]

    static def set_preset(name)
        var preset = _class.find_preset(name)
        if preset == nil
            return [f"There is no preset '{name}'", false]
        end
        if !TmsPalette.set_colors(preset[1])
            return ["Unable to set the colours", false]
        end
        return [f"{preset[0]} applied", true]
    end

    static def set_buttons(style)
        var found = _class.find_buttons(style)
        if found == nil
            return [f"There is no menu button style '{style}'", false]
        end
        TmsButtons.set(found)
        return [f"Menu buttons: {TmsButtons.name(found)}", true]
    end

    # the message for an error. persist.save() raises io_error when it can not write _persist.json,
    # most often because the file system is full
    static def error_message(e, m)
        if e == "io_error"
            return f"Unable to save the settings, {m}. The file system may be full, Tools > Manage File System shows its free space"
        end
        return f"{e}, {m}"
    end

    # the colours and menu buttons the theme starts with
    static def reset()
        TmsButtons.set(TmsButtons.default_style)
        if !TmsPalette.set_colors(TmsPalette.preset(TmsPalette.default_preset))
            return ["Unable to set the colours", false]
        end
        var buttons = TmsButtons.name(TmsButtons.default_style)
        return [f"Colours and menu buttons reset to the defaults ({TmsPalette.default_preset}, {buttons})", true]
    end

    # sets the settings in data, a map from json. Everything is checked before anything is set
    static def apply(data)
        if !isinstance(data, map)
            return ["The settings must be a json object, {\"version\":1,\"colors\":[...],\"buttons\":\"edge\"}", false]
        end
        for key : data.keys()
            if _class.keys.find(key) == nil
                return [f"Unknown setting '{key}', the settings are " + _class.keys.concat(", "), false]
            end
        end
        if data.contains("version") && data["version"] != _class.version
            var version = data["version"]
            return [f"The settings are version {version}, only version {_class.version} can be loaded", false]
        end
        var colors = data.find("colors")
        var buttons = data.find("buttons")
        if colors == nil && buttons == nil
            return ["The settings have no colors or buttons", false]
        end
        if isinstance(colors, list)
            var lower = []
            for color : colors
                lower.push(type(color) == "string" ? string.tolower(color) : color)
            end
            colors = lower
        end
        if colors != nil && !TmsPalette.valid_list(colors)
            return [f"colors must be a list of {size(TmsPalette.names)} colours like #1786e8", false]
        end
        if buttons != nil && TmsButtons.name(buttons) == nil
            return [f"There is no menu button style '{buttons}'", false]
        end

        var loaded = []
        if colors != nil
            if !TmsPalette.set_colors(colors)
                return ["Unable to set the colours", false]
            end
            var preset = _class.preset_name(colors)
            loaded.push(preset != nil ? f"the {preset} colours" : "the colours")
        end
        if buttons != nil
            TmsButtons.set(buttons)
            loaded.push(f"the {TmsButtons.name(buttons)} menu buttons")
        end
        return ["Loaded " + loaded.concat(" and "), true]
    end

    # the settings as text, pasted or from a file
    static def apply_json(text)
        var data = json.load(str(text))
        if data == nil
            return ["The settings are not valid json", false]
        end
        return _class.apply(data)
    end

    # the ip addresses of this device
    static def addresses()
        var addresses = []
        for network : [tasmota.wifi(), tasmota.eth()]
            var address = isinstance(network, map) ? network.find("ip") : nil
            if address != nil && address != "" && address != "0.0.0.0"
                addresses.push(address)
            end
        end
        return addresses
    end

    # the url other devices load the settings from, http://192.168.1.42/tms.json
    static def device_url()
        var addresses = _class.addresses()
        return size(addresses) ? "http://" + addresses[0] + _class.url : _class.url
    end

    # the settings from a url, the /tms.json of another device or a file on a web server. An
    # address on its own, 192.168.1.42 or http://192.168.1.42, gets http:// and /tms.json added
    static def apply_url(url)
        url = string.replace(str(url), " ", "")
        if url == ""
            return ["Give the url to load the settings from, like http://192.168.1.43", false]
        end
        var scheme = string.find(url, "://")
        if scheme < 0
            url = "http://" + url
        elif !string.startswith(url, "http://") && !string.startswith(url, "https://")
            return ["The url must start with http:// or https://", false]
        end
        var host_start = string.find(url, "//") + 2
        var path = string.find(url, "/", host_start)
        if path < 0
            url += _class.url
        elif path == size(url) - 1
            url = url[0..path - 1] + _class.url
        end
        # the web server answers one request at a time, it can not answer its own while it waits
        path = string.find(url, "/", host_start)
        var host = path > host_start ? url[host_start..path - 1] : ""
        var port = string.find(host, ":")
        if port >= 0
            host = port > 0 ? host[0..port - 1] : ""
        end
        if (_class.addresses() + ["localhost", "127.0.0.1"]).find(string.tolower(host)) != nil
            return [f"{url} is this device, give the url of another device", false]
        end

        var client = webclient()
        var status
        var content
        try
            client.set_timeouts(_class.url_timeouts[0], _class.url_timeouts[1])
            client.set_follow_redirects(true)
            client.begin(url)
            status = client.GET()
            if status == 200
                content = client.get_string()
            end
        except .. as e, m
            client.close()
            return [f"Unable to load {url} - {e} {m}", false]
        end
        client.close()
        if status != 200
            var reason = status < 0 ? f"no answer ({status})" : f"http status {status}"
            return [f"Unable to load {url} - {reason}", false]
        end
        var result = _class.apply_json(content)
        result[0] += result[1] ? f" from {url}" : f" ({url})"
        return result
    end
end

class TmsCommands
    # the Tsm commands, in the form of the Zigbee Manager's Zbm commands. Arguments are given in
    # order, TsmConfig Midnight,tinted, as key=value pairs, TsmConfig buttons=Icon tiles, or as
    # json, TsmConfig {"preset":"Tasmota dark"}. An error is logged and answered with Error

    static var names = ["TsmConfig", "TsmPresets", "TsmResetConfig", "TsmExport", "TsmImport"]
    static var config_keys = ["preset", "buttons"]

    static def add()
        tasmota.add_cmd("TsmConfig", _class.guarded(_class.config))
        tasmota.add_cmd("TsmPresets", _class.guarded(_class.presets))
        tasmota.add_cmd("TsmResetConfig", _class.guarded(_class.reset_config))
        tasmota.add_cmd("TsmExport", _class.guarded(_class.export))
        tasmota.add_cmd("TsmImport", _class.guarded(_class.load))
    end

    # the command, with an error it raises, such as a failed persist.save(), logged and answered with Error
    static def guarded(command)
        return def (cmd, idx, payload, payload_json)
            try
                command(cmd, idx, payload, payload_json)
            except .. as e, m
                _class.error(cmd, TmsSettings.error_message(e, m))
            end
        end
    end

    static def remove()
        for name : _class.names
            tasmota.remove_cmd(name)
        end
    end

    static def error(cmd, message)
        tasmota.log(f"TMS: {cmd} error: {message}", 1)
        tasmota.resp_cmnd_error()
    end

    # {"<cmd>":<value>}, value is json
    static def respond(cmd, value)
        tasmota.resp_cmnd("{" + json.dump(cmd) + ":" + value + "}")
    end

    # the arguments, a map by their keys in lower case. Raises argument_error
    static def arguments(payload, payload_json, keys)
        var result = {}
        if isinstance(payload_json, map)
            for key : payload_json.keys()
                result[string.tolower(str(key))] = payload_json[key]
            end
        elif size(payload)
            var parts = string.split(payload, ",")
            if size(parts) > size(keys)
                raise "argument_error", f"expected at most {size(keys)} arguments, got {size(parts)}"
            end
            var assigned = nil
            for index : 0..size(parts) - 1
                var part = parts[index]
                var assign = string.find(part, "=")
                if assign >= 0
                    if assigned == false
                        raise "argument_error", f"'{part}' follows an argument without a key"
                    end
                    assigned = true
                    result[string.tolower(string.replace(part[0..assign - 1], " ", ""))] = part[assign + 1..]
                else
                    if assigned == true
                        raise "argument_error", f"'{part}' has no key, after an argument with one"
                    end
                    assigned = false
                    result[keys[index]] = part
                end
            end
        end
        for key : result.keys()
            if keys.find(key) == nil
                raise "argument_error", f"unknown argument '{key}', the arguments are " + keys.concat(", ")
            end
        end
        return result
    end

    static def config_json()
        var preset = TmsSettings.preset_name(TmsPalette.colors())
        return "{\"preset\":" + json.dump(preset) + ",\"buttons\":" + json.dump(TmsButtons.current()) + "}"
    end

    # TsmConfig shows the preset and the menu buttons, TsmConfig preset=Midnight,buttons=tinted sets them
    static def config(cmd, idx, payload, payload_json)
        var arguments
        try
            arguments = _class.arguments(payload, payload_json, _class.config_keys)
        except .. as e, m
            return _class.error(cmd, m)
        end
        var preset = arguments.find("preset")
        var buttons = arguments.find("buttons")
        if preset != nil && TmsSettings.find_preset(preset) == nil
            return _class.error(cmd, f"there is no preset '{preset}', TsmPresets lists them")
        end
        if buttons != nil && TmsSettings.find_buttons(buttons) == nil
            return _class.error(cmd, f"there is no menu button style '{buttons}', TsmPresets lists them")
        end
        if preset != nil
            var result = TmsSettings.set_preset(preset)
            if !result[1]
                return _class.error(cmd, result[0])
            end
            tasmota.log(f"TMS: {result[0]}", 2)
        end
        if buttons != nil
            tasmota.log(f"TMS: {TmsSettings.set_buttons(buttons)[0]}", 2)
        end
        _class.respond(cmd, _class.config_json())
    end

    # TsmPresets lists the presets and the menu button styles TsmConfig takes
    static def presets(cmd, idx, payload, payload_json)
        var presets = []
        for preset : TmsSettings.presets()
            presets.push(preset[0])
        end
        var buttons = []
        for style : TmsButtons.styles
            buttons.push(style[0])
        end
        _class.respond(cmd, "{\"presets\":" + json.dump(presets) + ",\"buttons\":" + json.dump(buttons) + "}")
    end

    # TsmResetConfig sets the colours and menu buttons the theme starts with
    static def reset_config(cmd, idx, payload, payload_json)
        var result = TmsSettings.reset()
        if !result[1]
            return _class.error(cmd, result[0])
        end
        tasmota.log(f"TMS: {result[0]}", 2)
        tasmota.resp_cmnd_done()
    end

    # TsmExport answers the settings as json, for TsmImport on another device
    static def export(cmd, idx, payload, payload_json)
        _class.respond(cmd, TmsSettings.export())
    end

    # TsmImport {"version":1,"colors":[...],"buttons":"edge"} sets the settings,
    # TsmImport 192.168.1.43 loads them from the /tms.json of another device
    static def load(cmd, idx, payload, payload_json)
        var result
        if payload_json != nil
            result = TmsSettings.apply(payload_json)
        elif !size(payload)
            return _class.error(cmd, "give the settings as json, or the url to load them from")
        elif payload[0] == "{" || payload[0] == "["
            result = TmsSettings.apply_json(payload)
        else
            result = TmsSettings.apply_url(payload)
        end
        if !result[1]
            return _class.error(cmd, result[0])
        end
        tasmota.log(f"TMS: {result[0]}", 2)
        tasmota.resp_cmnd_done()
    end
end

class TmsManager
    # the Tasmota Style Manager page, from a button on the configuration page. It sets the colours
    # with the WebColor command, from a preset or one by one, the style of the menu buttons, and
    # exports and imports the settings

    static var url = "/tms"
    static var swatches = [1, 2, 0, 10, 14, 12]     # background, form, text, button, save and reset button
    # the export and import card: load a file into the text, copy it, and save it to a file
    static var script = "<script>"
                        "function tsl(i){var f=i.files[0];if(!f)return;var r=new FileReader();r.onload=function(){eb('tsj').value=r.result};r.readAsText(f);i.value=''}"
                        "function tsc(b){var t=eb('tsj'),d=function(){b.innerText='Copied';setTimeout(function(){b.innerText='Copy'},1500)};t.select();"
                        "if(navigator.clipboard&&window.isSecureContext){navigator.clipboard.writeText(t.value).then(d)}else{document.execCommand('copy');d()}}"
                        "function tsd(){var a=document.createElement('a');a.href=URL.createObjectURL(new Blob([eb('tsj').value],{type:'application/json'}));"
                        "a.download='tasmota_style.json';document.body.appendChild(a);a.click();a.remove()}"
                        "</script>"

    var message         # [text, success], shown once on the next page
    var draft           # the settings or url that could not be imported, shown again to correct them
    var draft_url

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

        var current = colors != nil ? TmsSettings.preset_name(colors) : nil
        webserver.content_send("<fieldset><legend><b>&nbsp;Presets&nbsp;</b></legend><form method='post' action='tms' class='tsp'>")
        for preset : TmsSettings.presets()
            var swatches = ""
            for index : self.swatches
                swatches += f"<i style='background:{preset[1][index]}'></i>"
            end
            var name = webserver.html_escape(preset[0])
            var mark = preset[0] == current ? "<small>Current</small>" : ""
            webserver.content_send(f"<button name='preset' value='{name}'><span>{swatches}</span>{name}{mark}</button>")
        end
        webserver.content_send("</form></fieldset><p></p>")

        var buttons = TmsButtons.current()
        webserver.content_send("<fieldset><legend><b>&nbsp;Menu buttons&nbsp;</b></legend><form method='post' action='tms' class='tsp'>")
        for style : TmsButtons.styles
            var mark = style[0] == buttons ? "<small>Current</small>" : ""
            webserver.content_send(f"<button name='buttons' value='{style[0]}'><span class='tsb tsb-{style[0]}'></span>{style[1]}{mark}</button>")
        end
        webserver.content_send("</form></fieldset><p></p>")

        if colors != nil
            webserver.content_send("<fieldset><legend><b>&nbsp;Colours&nbsp;</b></legend><form method='post' action='tms'><div class='tsg'>")
            for index : 0..size(colors) - 1
                webserver.content_send(f"<label><input type='color' name='c{index + 1}' value='{colors[index]}'>{TmsPalette.names[index]}</label>")
            end
            webserver.content_send("</div><br><button name='save' class='button bgrn'>Save</button></form></fieldset><p></p>")
        end

        self.page_export()
        webserver.content_send("<p></p><form method='post' action='tms'><button name='reset' class='bred' "
                               "onclick='return confirm(\"Set the colours and menu buttons back to the defaults?\")'>Reset to defaults</button></form>")
        webserver.content_button(webserver.BUTTON_CONFIGURATION)
        webserver.content_button(webserver.BUTTON_MAIN)
        webserver.content_send(self.script)
        webserver.content_stop()
    end

    # the settings as json to copy, save to a file, or paste and import, and the url to load
    # them from on another device
    def page_export()
        var text = self.draft != nil ? self.draft : TmsSettings.export()
        var url = self.draft_url != nil ? self.draft_url : ""
        self.draft = nil
        self.draft_url = nil
        var device_url = webserver.html_escape(TmsSettings.device_url())

        webserver.content_send("<fieldset><legend><b>&nbsp;Export and import&nbsp;</b></legend><form method='post' action='tms' class='tsx'>")
        webserver.content_send("<p class='tsn'>The settings of this device, to copy or save to a file. To load settings, paste them here or load a file, and press Import.</p>")
        webserver.content_send("<textarea id='tsj' name='json' class='tsj' spellcheck='false'>" + webserver.html_escape(text) + "</textarea>")
        webserver.content_send("<input type='file' id='tsf' accept='.json,application/json' style='display:none' onchange='tsl(this)'>")
        webserver.content_send("<div class='tsr'><button type='button' class='tsc' onclick='tsc(this)'>Copy</button>"
                               "<button type='button' class='tsd' onclick='tsd()'>Save to file</button></div>")
        webserver.content_send("<div class='tsr'><button type='button' class='tsl' onclick='eb(\"tsf\").click()'>Load from file</button>"
                               "<button name='import' value='json' class='tsi'>Import</button></div></form>")
        webserver.content_send(f"<p class='tsn'>Other devices load these settings from<br><a href='{TmsSettings.url}' target='_blank'>{device_url}</a></p>")
        webserver.content_send("<form method='post' action='tms' class='tsx'><div class='tsr'>"
                               "<input name='url' value='" + webserver.html_escape(url) + "' placeholder='http://192.168.1.43' required>"
                               "<button name='import' value='url' class='tsu'>Load from url</button></div></form></fieldset>")
    end

    def page_action()
        if !webserver.check_privileged_access() return nil end
        try
            if webserver.has_arg("preset")
                self.message = TmsSettings.set_preset(webserver.arg("preset"))
            elif webserver.has_arg("save")
                self.message = self.save_colors()
            elif webserver.has_arg("buttons")
                self.message = TmsSettings.set_buttons(webserver.arg("buttons"))
            elif webserver.has_arg("reset")
                self.message = TmsSettings.reset()
            elif webserver.has_arg("import")
                self.message = self.import_settings()
            end
        except .. as e, m
            self.message = [TmsSettings.error_message(e, m), false]
        end
        webserver.redirect(self.url)
    end

    # returns [message, success]
    def import_settings()
        var result
        if webserver.arg("import") == "url"
            var url = webserver.arg("url")
            result = TmsSettings.apply_url(url)
            if !result[1]
                self.draft_url = url
            end
        else
            var text = webserver.arg("json")
            result = TmsSettings.apply_json(text)
            if !result[1]
                self.draft = text
            end
        end
        return result
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
        TmsCommands.add()
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
        TmsCommands.remove()
        if self.routes_added
            self.routes_added = false
            try
                webserver.remove_route(self.url, webserver.HTTP_GET)
                webserver.remove_route(TmsSettings.url, webserver.HTTP_GET)
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
        webserver.on(TmsSettings.url, / -> self.send_settings(), webserver.HTTP_GET)
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

    # ---------------------------------------------------------------- settings

    # the settings as json, for Load from url on another device. It has no password, so a device
    # with a web password can be copied too: it is the colours and the menu buttons, nothing else
    def send_settings()
        webserver.content_open(200, "application/json")
        webserver.content_send(TmsSettings.export())
        webserver.content_close()
    end

    # ---------------------------------------------------------------- stylesheet

    # the extension manager renames the tapp to .tapp_ when auto-run is turned off, and back
    def open_file(name)
        var archives = [self.archive]
        if size(self.archive)
            archives.push(string.endswith(self.archive, "_") ? self.archive[0..-2] : self.archive + "_")
        end
        for archive : archives
            try
                var opened = open(size(archive) ? archive + "#" + name : name)
                self.archive = archive
                return opened
            except ..
            end
        end
        return nil
    end

    # only the bytes that are left are read. read(n) frees its buffer with the size it read, so when
    # it reads nothing, at the end of a file, the n bytes are never freed: 2 KB lost on every page
    def send_file(source)
        var left = source.size() - source.tell()
        while left > 0
            var chunk = source.read(left < self.chunk_size ? left : self.chunk_size)
            if !size(chunk)
                break
            end
            webserver.content_send(chunk)
            left -= size(chunk)
        end
    end

    # tasmota sends every response with no-cache, the stylesheet is sent on every page. The style of
    # the menu buttons, the browser's own controls and the shadows for a light background are added
    # at the end
    def send_css()
        var css_file = self.open_file("tms.css")
        if css_file == nil
            tasmota.log(f"TMS: unable to open tms.css in '{self.archive}'", 2)
            webserver.content_open(404, "text/plain")
            webserver.content_send("tms.css not found")
            webserver.content_close()
            return
        end
        webserver.content_open(200, "text/css")
        try
            self.send_file(css_file)
            var buttons = TmsButtons.current()
            if buttons != "plain"
                var buttons_file = self.open_file(f"btn_{buttons}.css")
                if buttons_file != nil
                    self.send_file(buttons_file)
                    buttons_file.close()
                else
                    tasmota.log(f"TMS: unable to open btn_{buttons}.css in '{self.archive}'", 2)
                end
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
