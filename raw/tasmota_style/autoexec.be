do
  import introspect
  import string
  # a copy already running from this tapp is stopped first: loading it again while it runs would
  # start a second one
  var ext_path = string.endswith(tasmota.wd, '#') ? tasmota.wd[0..-2] : tasmota.wd
  tasmota.unload_extension(ext_path)
  var tms_ext = introspect.module('tms.be', true)
  tasmota.add_extension(tms_ext)
end

# to stop it, by the path of its tapp, tasmota keeps extensions by their path:
#       tasmota.unload_extension('/.extensions/tasmota_style.tapp')
