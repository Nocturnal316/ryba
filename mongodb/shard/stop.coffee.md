
# MongoDB Config Server Stop

    module.exports = header: 'MongoDB Shard Server Stop', label_true: 'STOPPED', handler: ->
      {shard} = @config.ryba.mongodb

## Stop

Stop the MongoDB Config Server service.

      @service.stop
        header: 'Stop service'
        name: 'mongod-shard-server'

## Clean Logs

      @call
        if:  @config.ryba.clean_logs
        header: 'Clean Logs'
        label_true: 'CLEANED'
      , ->
        @system.execute
          cmd: "rm #{shard.config.systemLog.path}"
          code_skipped: 1
