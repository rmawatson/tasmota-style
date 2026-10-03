do
  import introspect
  var zbs_ext = introspect.module('zbs.be', true)
  tasmota.add_extension(zbs_ext)
end

# to remove:
#       tasmota.unload_extension('Zigbee Style')
