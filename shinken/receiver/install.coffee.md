
# Shinken Receiver Install

    module.exports = header: 'Shinken Receiver Install', handler: ->
      {shinken} = @config.ryba
      {receiver} = @config.ryba.shinken

## IPTables

| Service          | Port  | Proto | Parameter       |
|------------------|-------|-------|-----------------|
| shinken-receiver | 7773  |  tcp  |   config.port   |

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

      @tools.iptables
        header: 'IPTables'
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: receiver.config.port, protocol: 'tcp', state: 'NEW', comment: "Shinken Receiver" }
        ]
        if: @config.iptables.action is 'start'

## Packages

      @service
        header: 'Packages'
        name: 'shinken-receiver'

## Configuration

      @file.ini
        header: 'Configuration'
        target: '/etc/shinken/daemons/receiverd.ini'
        content: daemon: receiver.ini
        backup: true
        eof: true

## Modules

      @call header: 'Modules', ->
        installmod = (name, mod) =>
          @call unless_exec: "shinken inventory | grep #{name}", ->
            @file.download
              target: "#{shinken.build_dir}/#{mod.archive}.#{mod.format}"
              source: mod.source
              cache_file: "#{mod.archive}.#{mod.format}"
              unless_exec: "shinken inventory | grep #{name}"
            @tools.extract
              source: "#{shinken.build_dir}/#{mod.archive}.#{mod.format}"
            @system.execute
              cmd: "shinken install --local #{shinken.build_dir}/#{mod.archive}"
            @system.remove target: "#{shinken.build_dir}/#{mod.archive}.#{mod.format}"
            @system.remove target: "#{shinken.build_dir}/#{mod.archive}"
          for subname, submod of mod.modules then installmod subname, submod
        for name, mod of receiver.modules then installmod name, mod

## Python Modules

      @call header: 'Python Modules', ->
        install_dep = (k, v) =>
          @call unless_exec: "pip list | grep #{k}", ->
            @file.download
              source: v.url
              target: "#{shinken.build_dir}/#{v.archive}.#{v.format}"
              cache_file: "#{v.archive}.#{v.format}"
            @tools.extract
              source: "#{shinken.build_dir}/#{v.archive}.#{v.format}"
            @system.execute
              cmd:"""
              cd #{shinken.build_dir}/#{v.archive}
              python setup.py build
              python setup.py install
              """
            @system.remove target: "#{shinken.build_dir}/#{v.archive}.#{v.format}"
            @system.remove target: "#{shinken.build_dir}/#{v.archive}"
        for _, mod of receiver.modules then for k,v of mod.python_modules then install_dep k, v
