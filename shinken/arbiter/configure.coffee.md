
# Shinken Arbiter Configure

    module.exports = ->
      {shinken, monitoring} = @config.ryba
      # Arbiter specific configuration
      arbiter = shinken.arbiter ?= {}
      # Auto-discovery of Modules
      arbiter.modules ?= {}
      configmod = (name, mod) =>
        if mod.version?
          mod.type ?= name
          mod.archive ?= "mod-#{name}-#{mod.version}"
          mod.format ?= 'zip'
          mod.source ?= "https://github.com/shinken-monitoring/mod-#{name}/archive/#{mod.version}.#{mod.format}"
          mod.config_file ?= "#{name}.cfg"
        mod.modules ?= {}
        mod.config ?= {}
        mod.config.modules = [mod.config.modules] if typeof mod.config.modules is 'string'
        mod.config.modules ?= Object.keys mod.modules
        mod.python_modules ?= {}
        for pyname, pymod of mod.python_modules
          pymod.format ?= 'tar.gz'
          pymod.archive ?= "#{pyname}-#{pymod.version}"
          pymod.url ?= "https://pypi.python.org/simple/#{pyname}/#{pymod.archive}.#{pymod.format}"
        for subname, submod of mod.modules then configmod subname, submod
      for name, mod of arbiter.modules then configmod name, mod

## Config

This configuration is used by arbiter to send the configuration when arbiter
synchronize configuration through network. The generated file must be on the
arbiter host.

      arbiter.config ?= {}
      arbiter.config.host ?= '0.0.0.0'
      arbiter.config.port ?= 7770
      arbiter.config.spare ?= '0'
      arbiter.config.modules = [arbiter.config.modules] if typeof arbiter.config.modules is 'string'
      arbiter.config.modules ?= Object.keys arbiter.modules
      arbiter.config.distributed ?= @contexts('ryba/shinken/arbiter').length > 1
      arbiter.config.hostname ?= @config.host
      arbiter.config.user = shinken.user.name
      arbiter.config.group = shinken.group.name
      arbiter.config.use_ssl ?= shinken.config.use_ssl
      arbiter.config.hard_ssl_name_check ?= shinken.config.hard_ssl_name_check
