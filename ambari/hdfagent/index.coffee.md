# Ambari Client

[Ambari-agent][Ambari-agent-install] on hosts enables the ambari server to be
aware of the  hosts where Hadoop will be deployed. The Ambari Server must be 
installed before the agent registration.


    module.exports =
      use:
        java: module: 'masson/commons/java', recommanded: true
        hdf: module: 'ryba/hdf'
        ambari_repo: module: 'ryba/ambari/hdfrepo'
        ambari_server: 'ryba/ambari/hdfserver', required: true
      configure:
        'ryba/ambari/hdfagent/configure'
      commands:
        'install': ->
          options = @config.ryba.ambari_hdfagent
          @call 'ryba/ambari/agent/install', options
          @call 'ryba/ambari/agent/start', options
        'start': 'ryba/ambari/agent/start'
        'stop': 'ryba/ambari/agent/stop'

[Ambari-agent-install]: https://cwiki.apache.org/confluence/display/AMBARI/Installing+ambari-agent+on+target+hosts
