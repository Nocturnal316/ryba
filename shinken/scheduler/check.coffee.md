
# Shinken Scheduler Check

    module.exports = header: 'Shinken Scheduler Check', label_true: 'CHECKED', label_false: 'SKIPPED', handler: ->
      options = @config.ryba.shinken.scheduler

## TCP

      @system.execute
        header: 'TCP'
        cmd: "echo > /dev/tcp/#{@config.host}/#{options.config.port}"

## HTTP

      if options.ini.use_ssl is '1'
        cmd = "curl -k https://#{@config.host}:#{options.config.port}"
      else
        cmd = "curl http://#{@config.host}:#{options.config.port}"
      @system.execute
        header: 'HTTP'
        cmd: "#{cmd} | grep OK"
