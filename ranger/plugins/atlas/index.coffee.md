# Ranger HiveServer2 Plugin

    module.exports =
      use:
        krb5_client: module: 'masson/core/krb5_client'
        hadoop_core: use: true, module: 'ryba/hadoop/core'
      configure:
        'ryba/ranger/plugins/atlas/configure'
