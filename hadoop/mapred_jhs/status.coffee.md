
# MapReduce JobHistoryServer Status

Check if the Job History Server is running. The process ID is located by default
inside "/var/run/hive/hive-server2.pid".

    module.exports = header: 'MapReduce JHS Status', label_true: 'STARTED', label_false: 'STOPPED', handler: ->
      @service.status
        name: 'hadoop-mapreduce-historyserver'
