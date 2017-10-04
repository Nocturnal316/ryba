
# OpenNebula

OpenNebula is an open-source management platform to build IaaS private, public and hybrid clouds.

    module.exports =
      use: {}
      configure: 'ryba/incubator/nebula/base/configure'
      commands:
        install: ->
          options = @config.nebula.base
          @call 'ryba/incubator/nebula/base/install', options