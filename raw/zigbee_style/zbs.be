# MIT License - Copyright (c) 2026 rmawatson@hotmail.com - See LICENSE file for details
#-  -#

import string
import webserver

class ZbsExtension
    # Tasmota has no way to add a stylesheet to its pages, but it writes the WebCanvas setting
    # unescaped into the style of every page, as body{background:<WebCanvas> 0 0 / cover no-repeat fixed;}
    # The theme sets WebCanvas to the background tasmota would have used, followed by the end of
    # that style, a link to the stylesheet served from the tapp and the start of a style that takes
    # the rest of the line. The WebCanvas there was before is put back when the extension stops.

    static var url = "/zbs.css"
    static var link = "}</style><link rel=stylesheet href=/zbs.css><style>:root{--zbs:1"
    static var link_start = "}</style><link rel=stylesheet href=/zbs.css>"
    static var canvas_options = " 0 0 / cover no-repeat fixed"
    static var default_background = "var(--c_bg)"
    static var chunk_size = 2048

    var archive         # the tapp the stylesheet is read from, ex: /.extensions/zigbee_style.tapp
    var route_added

    def init()
        var wd = tasmota.wd
        self.archive = string.endswith(wd, "#") ? wd[0..-2] : wd
        self.route_added = false
        tasmota.add_driver(self)
        # tasmota only sends web_add_handler once, when the web server starts. if the extension
        # is started later, from the extension manager, the route is added straight away
        if webserver.state() != webserver.HTTP_OFF
            self.web_add_handler()
        end
        self.apply()
    end

    def unload()
        tasmota.remove_driver(self)
        if self.route_added
            self.route_added = false
            try
                webserver.remove_route(self.url, webserver.HTTP_GET)
            except .. as e, m
                tasmota.log(f"ZBS: unable to remove {self.url} - {e} {m}", 2)
            end
        end
        self.restore()
    end

    def web_add_handler()
        if self.route_added
            return
        end
        webserver.on(self.url, / -> self.send_css(), webserver.HTTP_GET)
        self.route_added = true
    end

    # ---------------------------------------------------------------- WebCanvas

    static def canvas()
        var result = tasmota.cmd("WebCanvas", true)
        if result == nil
            return ""
        end
        return str(result.find("WebCanvas", ""))
    end

    static def themed(canvas)
        return string.find(canvas, _class.link_start) >= 0
    end

    # the WebCanvas that was set before the theme
    static def original(canvas)
        var position = string.find(canvas, _class.link_start)
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
            tasmota.log("ZBS: unable to set WebCanvas, the settings have no room for it. The theme is not shown", 1)
            return false
        end
        tasmota.log("ZBS: theme applied", 2)
        return true
    end

    def restore()
        var current = self.canvas()
        if !self.themed(current)
            return true
        end
        if !self.set_canvas(self.original(current))
            tasmota.log("ZBS: unable to restore WebCanvas", 1)
            return false
        end
        tasmota.log("ZBS: theme removed", 2)
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
                var css_file = open(size(archive) ? archive + "#zbs.css" : "zbs.css")
                self.archive = archive
                return css_file
            except ..
            end
        end
        return nil
    end

    # tasmota sends every response with no-cache, the stylesheet is sent on every page
    def send_css()
        var css_file = self.open_css()
        if css_file == nil
            tasmota.log(f"ZBS: unable to open zbs.css in '{self.archive}'", 2)
            webserver.content_open(404, "text/plain")
            webserver.content_send("zbs.css not found")
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
        except .. as e, m
            tasmota.log(f"ZBS: unable to send zbs.css - {e} {m}", 2)
        end
        css_file.close()
        webserver.content_close()
    end
end

return ZbsExtension()
