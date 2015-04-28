
# Oozie Server Start

Run the command `./bin/ryba start -m ryba/oozie/server` to start the Oozie
server using Ryba.

By default, the pid of the running server is stored in
"/var/run/oozie/oozie.pid".

    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push require('./index').configure

## Start

Start the Oozie server. You can also start the server manually with the
following command:

```
su -l oozie -c "/usr/hdp/current/oozie-server/bin/oozied.sh start"
```

Note, there is no need to clean a zombie pid file before starting the server.

    module.exports.push name: 'Oozie Server # Start', label_true: 'STARTED', timeout: -1, handler: (ctx, next) ->
      {oozie} = ctx.config.ryba
      ctx.execute
        cmd: """
        if [ -f #{oozie.pid_dir}/oozie.pid ]; then
          if kill -0 >/dev/null 2>&1 `cat #{oozie.pid_dir}/oozie.pid`; then exit 3; fi
          rm #{oozie.pid_dir}/oozie.pid # Or Oozie will complain
        fi
        su -l #{oozie.user.name} -c "/usr/hdp/current/oozie-server/bin/oozied.sh start"
        """
        code_skipped: 3
      , next