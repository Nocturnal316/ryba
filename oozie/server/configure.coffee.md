
# Oozie Server Configure

*   `oozie.user` (object|string)
    The Unix Oozie login name or a user object (see Nikita User documentation).
*   `oozie.group` (object|string)
    The Unix Oozie group name or a group object (see Nikita Group documentation).

Example

```json
    "oozie": {
      "user": {
        "name": "oozie", "system": true, "gid": "oozie",
        "comment": "Oozie User", "home": "/var/lib/oozie"
      },
      "group": {
        "name": "Oozie", "system": true
      },
      "db": {
        "password": "Oozie123!"
      }
    }
```

    module.exports = ->
      # Internal properties
      zk_ctxs = @contexts('ryba/zookeeper/server').filter( (ctx) -> ctx.config.ryba.zookeeper.config['peerType'] is 'participant')
      {ryba} = @config
      oozie = ryba.oozie ?= {}

## Environment

      # Layout
      oozie.conf_dir ?= '/etc/oozie/conf'
      oozie.data ?= '/var/db/oozie'
      oozie.log_dir ?= '/var/log/oozie'
      oozie.pid_dir ?= '/var/run/oozie'
      oozie.tmp_dir ?= '/var/tmp/oozie'
      oozie.server_dir ?= '/usr/hdp/current/oozie-client/oozie-server'

## Identities

      # User
      oozie.user ?= {}
      oozie.user = name: oozie.user if typeof oozie.user is 'string'
      oozie.user.name ?= 'oozie'
      oozie.user.system ?= true
      oozie.user.gid ?= 'oozie'
      oozie.user.comment ?= 'Oozie User'
      oozie.user.home ?= '/var/lib/oozie'
      # Group
      oozie.group ?= {}
      oozie.group = name: oozie.group if typeof oozie.group is 'string'
      oozie.group.name ?= 'oozie'
      oozie.group.system ?= true

## Security

      # SSL
      oozie.secure ?= true
      # see comment in ../resources/oozie-env.sh.j2
      oozie.keystore_file ?= "#{oozie.conf_dir}/keystore"
      oozie.keystore_pass ?= 'oozie123'
      oozie.truststore_file ?= "#{oozie.conf_dir}/trustore"
      oozie.truststore_pass ?= 'oozie123'
      # Configuration
      oozie.site ?= {}
      oozie.http_port ?= if oozie.secure then 11443 else 11000
      oozie.admin_port ?= 11001
      if oozie.secure
        oozie.site['oozie.base.url'] = "https://#{@config.host}:#{oozie.http_port}/oozie"
      else
        oozie.site['oozie.base.url'] = "http://#{@config.host}:#{oozie.http_port}/oozie"
      # Configuration Database
      oozie.db ?= {}
      oozie.db.engine ?= 'mysql'
      oozie.db[k] ?= v for k, v of ryba.db_admin[oozie.db.engine]
      oozie.db.database ?= 'oozie'
      oozie.db.username ?= 'oozie'
      throw Error "Require Property: oozie.db.password" unless oozie.db.password
      #jdbc provided by ryba/commons/db_admin
      #for now only setting the first host as Oozie fails to parse jdbc url.
      #JIRA: [OOZIE-2136]
      oozie.site['oozie.service.JPAService.jdbc.url'] ?= "jdbc:mysql://#{oozie.db.host}:#{oozie.db.port}/#{oozie.db.database}?createDatabaseIfNotExist=true"
      oozie.site['oozie.service.JPAService.jdbc.driver'] ?= 'com.mysql.jdbc.Driver'
      oozie.site['oozie.service.JPAService.jdbc.username'] = oozie.db.username
      oozie.site['oozie.service.JPAService.jdbc.password'] = oozie.db.password
      # Path to hadoop configuration is required when running 'sharelib upgrade'
      # or an error will complain that the hdfs url is invalid
      oozie.site['oozie.services.ext']?= []
      oozie.site['oozie.service.HadoopAccessorService.hadoop.configurations'] ?= '*=/etc/hadoop/conf'
      oozie.site['oozie.service.SparkConfigurationService.spark.configurations'] ?= '*=/etc/spark/conf/'
      #oozie.site['oozie.service.SparkConfigurationService.spark.configurations.ignore.spark.yarn.jar'] ?= 'true'
      oozie.site['oozie.service.AuthorizationService.authorization.enabled'] ?= 'true'
      oozie.site['oozie.service.HadoopAccessorService.kerberos.enabled'] ?= 'true'
      oozie.site['local.realm'] ?= "#{ryba.realm}"
      oozie.site['oozie.service.HadoopAccessorService.keytab.file'] ?= '/etc/oozie/conf/oozie.service.keytab'
      oozie.site['oozie.service.HadoopAccessorService.kerberos.principal'] ?= "oozie/#{@config.host}@#{ryba.realm}"
      oozie.site['oozie.authentication.type'] ?= 'kerberos'
      oozie.site['oozie.authentication.kerberos.principal'] ?= "HTTP/#{@config.host}@#{ryba.realm}"
      oozie.site['oozie.authentication.kerberos.keytab'] ?= '/etc/oozie/conf/spnego.service.keytab'
      oozie.site['oozie.authentication.kerberos.name.rules'] ?= ryba.core_site['hadoop.security.auth_to_local']
      oozie.site['oozie.service.HadoopAccessorService.nameNode.whitelist'] ?= '' # Fix space value
      oozie.site['oozie.credentials.credentialclasses'] ?= [
       'hcat=org.apache.oozie.action.hadoop.HCatCredentials'
       'hbase=org.apache.oozie.action.hadoop.HbaseCredentials'
       'hive2=org.apache.oozie.action.hadoop.Hive2Credentials'
      ]
      # Spark and Shell action dedicated configuration in each yarn container
      # To benefit from that feature in a ShellAction, one must specify the --config parameter
      # with the HADOOP_CONF_DIR env variable set by Oozie at runtime
      # eg : hadoop --config $HADOOP_CONF_DIR fs -ls /
      # see also OOZIE-2343, OOZIE-2481, OOZIE-2569 and OOZIE-2504, fixed by OOZIE-2739
      oozie.site['oozie.action.spark.setup.hadoop.conf.dir'] ?= 'true'
      oozie.site['oozie.action.shell.setup.hadoop.conf.dir'] ?= 'true'
      oozie.site['oozie.action.shell.setup.hadoop.conf.dir.write.log4j.properties'] ?= 'true'
      oozie.site['oozie.action.shell.setup.hadoop.conf.dir.log4j.content'] ?= '''
      log4j.rootLogger=INFO,console
      log4j.appender.console=org.apache.log4j.ConsoleAppender
      log4j.appender.console.target=System.err
      log4j.appender.console.layout=org.apache.log4j.PatternLayout
      log4j.appender.console.layout.ConversionPattern=%d{yy/MM/dd HH:mm:ss} %p %c{2}: %m%n
      '''
      # Sharelib add-ons
      oozie.sharelib ?= {}
      oozie.sharelib.distcp ?= []
      oozie.sharelib.hcatalog ?= []
      oozie.sharelib.hive ?= []
      oozie.sharelib.hive2 ?= []
      oozie.sharelib.mrstreaming ?= []
      oozie.sharelib.oozie ?= []
      oozie.sharelib.pig ?= []
      oozie.sharelib.spark ?= []
      oozie.sharelib.sqoop ?= []
      # https://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.5.0/bk_command-line-upgrade/content/start-oozie-23.html
      # AMBARI-18383
      oozie.sharelib.spark.push '/usr/hdp/current/spark-client/lib/datanucleus-api-jdo-3.2.6.jar'
      oozie.sharelib.spark.push '/usr/hdp/current/spark-client/lib/datanucleus-core-3.2.10.jar'
      oozie.sharelib.spark.push '/usr/hdp/current/spark-client/lib/datanucleus-rdbms-3.2.9.jar'
      oozie.sharelib.spark.push '/usr/hdp/current/spark-client/lib/spark-assembly-1.6.2.2.5.3.0-37-hadoop2.7.3.2.5.3.0-37.jar'
      oozie.sharelib.spark.push '/usr/hdp/current/spark-client/python/lib/pyspark.zip'
      oozie.sharelib.spark.push '/usr/hdp/current/spark-client/python/lib/py4j-0.9-src.zip'
      # Oozie Notifications
      # see https://oozie.apache.org/docs/4.1.0/AG_Install.html#Notifications_Configuration
      if oozie.jms_url
        oozie.site['oozie.services.ext'].push [
          'org.apache.oozie.service.JMSAccessorService'
          'org.apache.oozie.service.JMSTopicService'
          'org.apache.oozie.service.EventHandlerService'
          'org.apache.oozie.sla.service.SLAService'
          ]
        oozie.site['oozie.service.EventHandlerService.event.listeners'] ?= [
          'org.apache.oozie.jms.JMSJobEventListener'
          'org.apache.oozie.sla.listener.SLAJobEventListener'
          'org.apache.oozie.jms.JMSSLAEventListener'
          'org.apache.oozie.sla.listener.SLAEmailEventListener'
          ]
        oozie.site['oozie.service.SchedulerService.threads'] ?= 15
        oozie.site['oozie.jms.producer.connection.properties'] ?= "java.naming.factory.initial#org.apache.activemq.jndi.ActiveMQInitialContextFactory;java.naming.provider.url#"+"#{oozie.jms_url}"+";connectionFactoryNames#ConnectionFactory"
        #oozie.site['oozie.service.JMSTopicService.topic.prefix'] ?= 'oozie.' # despite the docs, this parameter does not exist
        oozie.site['oozie.service.JMSTopicService.topic.name'] ?= [
          'default=${username}'
          'WORKFLOW=workflow'
          'COORDINATOR=coordinator'
          'BUNDLE=bundle'
          ].join(',')


## Configuration for Proxy Users

      hadoop_ctxs = @contexts [
        'ryba/hadoop/hdfs_nn'
        'ryba/hadoop/hdfs_dn'
        'ryba/hadoop/yarn_rm'
        'ryba/hadoop/yarn_nm'
        'ryba/hive/server2'
        'ryba/hive/hcatalog'
        'ryba/hbase/master'
        ]
      for hadoop_ctx in hadoop_ctxs
        hadoop_ctx.config.ryba ?= {}
        hadoop_ctx.config.ryba.core_site ?= {}
        hadoop_ctx.config.ryba.core_site["hadoop.proxyuser.#{oozie.user.name}.hosts"] ?= (@contexts('ryba/oozie/server')).map((ctx) -> ctx.config.host).join ','
        hadoop_ctx.config.ryba.core_site["hadoop.proxyuser.#{oozie.user.name}.groups"] ?= '*'

## Configuration for Hadoop

      oozie.hadoop_config ?= {}
      oozie.hadoop_config['mapreduce.jobtracker.kerberos.principal'] ?= "mapred/#{ryba.static_host}@#{ryba.realm}"
      oozie.hadoop_config['yarn.resourcemanager.principal'] ?= "yarn/#{ryba.static_host}@#{ryba.realm}"
      oozie.hadoop_config['dfs.namenode.kerberos.principal'] ?= "hdfs/#{ryba.static_host}@#{ryba.realm}"
      oozie.hadoop_config['mapreduce.framework.name'] ?= "yarn"

## Configuration for Log4J

      oozie.log4j ?= {}
      oozie.log4j.opts ?= {}
      oozie.log4j.opts[k] ?= v for k, v of @config.log4j
      if oozie.log4j.opts.server_port?
        oozie.log4j.opts['extra_appender'] = ",socket_server"
      if oozie.log4j.opts.remote_host? && oozie.log4j.opts.remote_port?
        oozie.log4j.opts['extra_appender'] = ",socket_client"
      oozie.log4j_opts = ""
      oozie.log4j_opts += " -Doozie.log4j.#{k}=#{v}" for k, v of oozie.log4j.opts

## Oozie Environment

      oozie.heap_size ?= '256m'

## High Availability
Config [High Availability][oozie-ha]. They should be configured against
the same database. It uses zookeeper for enabling HA.

      oozie.ha = if zk_ctxs.length > 1 then true else false
      if oozie.ha
        quorum = for zk_ctx in zk_ctxs.filter( (ctx) -> ctx.config.ryba.zookeeper.config['peerType'] is 'participant')
          "#{zk_ctx.config.host}:#{zk_ctx.config.ryba.zookeeper.config['clientPort']}"
        oozie.site['oozie.zookeeper.connection.string'] ?= quorum.join ','
        oozie.site['oozie.zookeeper.namespace'] ?= 'oozie-ha'
        oozie.site['oozie.services.ext'].push [
          'org.apache.oozie.service.ZKLocksService'
          'org.apache.oozie.service.ZKXLogStreamingService'
          'org.apache.oozie.service.ZKJobsConcurrencyService'
          'org.apache.oozie.service.ZKUUIDService'
        ]
      oozie.site['oozie.instance.id'] ?= @config.host
      #ACL On zookeeper
      oozie.site['oozie.zookeeper.secure'] ?= 'true'
      oozie.site['oozie.service.ZKUUIDService.jobid.sequence.max'] ?= '99999999990'

[oozie-ha]:(https://oozie.apache.org/docs/4.2.0/AG_Install.html#High_Availability_HA)
