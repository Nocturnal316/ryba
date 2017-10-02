
# Open Nebula Node

OpenNebula is an open-source management platform to build IaaS private, public and hybrid clouds.

    module.exports =
      configure: 'ryba/incubator/nebula/node/configure'
      commands:
        'install': ->
          options = @config.nebula.node
          @call 'ryba/incubator/nebula/node/install', options