
# Ganglia Monitor Start

Execute these commands on the Ganglia server host machine.

    module.exports = []
    module.exports.push 'masson/bootstrap/connection'
    module.exports.push 'masson/bootstrap/mecano'

# Start

The gmetad daemon is started by the "hdp-gmetad" script and not directly. The
"hdp-gemetad" will enter into an invalid state if "gemetd" is stoped
independently complaining that "rrdcached" is already running.

    module.exports.push name: 'Ganglia Collector # Start', label_true: 'STARTED', handler: (ctx, next) ->
      ctx.service [
      #   name: 'httpd'
      #   action: 'start'
      # ,
        # name: 'ganglia-gmetad-3.5.0-99'
        srv_name: 'hdp-gmetad'
        action: 'start'
        if_exists: '/etc/init.d/hdp-gmetad'
      ], next