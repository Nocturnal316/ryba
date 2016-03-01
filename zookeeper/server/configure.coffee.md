
# ZooKeeper Client Configure

*   `zookeeper.user` (object|string)   
    The Unix Zookeeper login name or a user object (see Mecano User documentation).   
*   `zookeeper.env` (object)   
    Map of variables present in "zookeeper-env.sh" and used to initialize the server.   
*   `zookeeper.config` (object)   
    Map of variables present in "zoo.cfg" and used to configure the server.   

Example :

```json
{
  "ryba": {
    "zookeeper" : {
      "user": {
        "name": "zookeeper", "system": true, "gid": "hadoop",
        "comment": "Zookeeper User", "home": "/var/lib/zookeeper"
      }
    }
  }
}
```

    module.exports = handler: ->
      {java} = @config
      zk_ctxs = @contexts 'ryba/zookeeper/server'
      zookeeper = @config.ryba.zookeeper ?= {}
      # Layout
      zookeeper.pid_dir ?= '/var/run/zookeeper'
      # Environnment
      zookeeper.env ?= {}
      zookeeper.env['JAVA_HOME'] ?= "#{java.java_home}"
      zookeeper.env['ZOOKEEPER_HOME'] ?= "/usr/hdp/current/zookeeper-client"
      zookeeper.env['ZOO_AUTH_TO_LOCAL'] ?= "RULE:[1:\\$1]RULE:[2:\\$1]"
      zookeeper.env['ZOO_LOG_DIR'] ?= "#{zookeeper.log_dir}"
      zookeeper.env['ZOOPIDFILE'] ?= "#{zookeeper.pid_dir}/zookeeper_server.pid"
      zookeeper.env['SERVER_JVMFLAGS'] ?= "-Xmx1024m -Djava.security.auth.login.config=#{zookeeper.conf_dir}/zookeeper-server.jaas"
      zookeeper.env['CLIENT_JVMFLAGS'] ?= "-Djava.security.auth.login.config=#{zookeeper.conf_dir}/zookeeper-client.jaas"
      zookeeper.env['JAVA'] ?= '$JAVA_HOME/bin/java'
      zookeeper.env['CLASSPATH'] ?= '$CLASSPATH:/usr/share/zookeeper/*'
      zookeeper.env['ZOO_LOG4J_PROP'] ?= 'INFO,CONSOLE,ROLLINGFILE'
      if zookeeper.env['SERVER_JVMFLAGS'].indexOf('-Dzookeeper.security.auth_to_local') is -1
        zookeeper.env['SERVER_JVMFLAGS'] = "#{zookeeper.env['SERVER_JVMFLAGS']} -Dzookeeper.security.auth_to_local=$ZOO_AUTH_TO_LOCAL"
      if zookeeper.env['JMXPORT']? and zookeeper.env['SERVER_JVMFLAGS'].indexOf('-Dcom.sun.management.jmxremote.rmi.port') is -1
        zookeeper.env['SERVER_JVMFLAGS'] = "#{zookeeper.env['SERVER_JVMFLAGS']} -Dcom.sun.management.jmxremote.rmi.port=$JMXPORT"
      zookeeper.log4j ?= {}
      zookeeper.log4j[k] ?= v for k, v of @config.log4j
      if zookeeper.log4j.remote_host? and zookeeper.log4j.remote_port? and zookeeper.env['ZOO_LOG4J_PROP'].indexOf('SOCKET') is -1
        zookeeper.env['ZOO_LOG4J_PROP'] = "#{zookeeper.env['ZOO_LOG4J_PROP']},SOCKET"
      if zookeeper.log4j.server_port? and zookeeper.env['ZOO_LOG4J_PROP'].indexOf('SOCKETHUB') is -1
        zookeeper.env['ZOO_LOG4J_PROP'] = "#{zookeeper.env['ZOO_LOG4J_PROP']},SOCKETHUB"
      # Configuration
      zookeeper.config ?= {}
      zookeeper.config['maxClientCnxns'] ?= '200'
      # The number of milliseconds of each tick
      zookeeper.config['tickTime'] ?= "2000"
      # The number of ticks that the initial synchronization phase can take
      zookeeper.config['initLimit'] ?= "10"
      zookeeper.config['tickTime'] ?= "2000"
      # The number of ticks that can pass between
      # sending a request and getting an acknowledgement
      zookeeper.config['syncLimit'] ?= "5"
      # the directory where the snapshot is stored.
      zookeeper.config['dataDir'] ?= '/var/zookeeper/data/'
      # the port at which the clients will connect
      zookeeper.config['clientPort'] ?= "#{zookeeper.port}"
      if zk_ctxs.length > 1 then for zk_ctx, i in zk_ctxs
        zookeeper.config["server.#{i+1}"] = "#{zk_ctx.config.host}:2888:3888"
      # SASL
      zookeeper.config['authProvider.1'] ?= 'org.apache.zookeeper.server.auth.SASLAuthenticationProvider'
      zookeeper.config['jaasLoginRenew'] ?= '3600000'
      zookeeper.config['kerberos.removeHostFromPrincipal'] ?= 'true'
      zookeeper.config['kerberos.removeRealmFromPrincipal'] ?= 'true'
      # Internal
      zookeeper.myid ?= null
      zookeeper.retention ?= 3 # Used to clean data dir
      zookeeper.purge ?= '@weekly'
      zookeeper.purge = '@weeekly' if zookeeper.purge is true
      # Superuser
      zookeeper.superuser ?= {}
      # zookeeper.superuser.password ?= 'ryba123'