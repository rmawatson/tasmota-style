do
  import introspect
  var tms_ext = introspect.module('tms.be', true)
  tasmota.add_extension(tms_ext)
end

# to remove:
#       tasmota.unload_extension('Tasmota Style')
