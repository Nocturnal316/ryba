
# Hive HCatalog Status

Check if the HCatalog is running. The process ID is located by default
inside "/var/lib/hive-hcatalog/hcat.pid".

    module.exports = header: 'Hive HCatalog Status', label_true: 'STARTED', label_false: 'STOPPED', handler: ->
      @service.status
        name: 'hive-hcatalog-server'
