
# Oozie Server
[Oozie]https://oozie.apache.org/docs/3.1.3-incubating/index.html is a Java Web-Application that runs in a Java servlet-container which is a server based Workflow Engine specialized in running workflow jobs with actions that run Hadoop Map/Reduce and Pig jobs.
For the purposes of Oozie, a workflow is a collection of actions (i.e. Hadoop Map/Reduce jobs, Pig jobs) arranged in a control dependency DAG (Direct Acyclic Graph). "control dependency" from one action to another means that the second action ca not run until the first action has completed.


    module.exports = []

## Todo

*   [Configure JMS Provider JNDI connection mapping for HCatalog](http://oozie.apache.org/docs/4.0.0/AG_Install.html#HCatalog_Configuration)
*   [Notifications Configuration](http://oozie.apache.org/docs/4.0.0/AG_Install.html#Notifications_Configuration)
*   [Setting Up Oozie with HTTPS (SSL)](http://oozie.apache.org/docs/4.0.0/AG_Install.html#Setting_Up_Oozie_with_HTTPS_SSL)

## Configure

*   `oozie.user` (object|string)
    The Unix Oozie login name or a user object (see Mecano User documentation).
*   `oozie.group` (object|string)
    The Unix Oozie group name or a group object (see Mecano Group documentation).

Example

```json
    "oozie": {
      "user": {
        "name": "oozie", "system": true, "gid": "oozie",
        "comment": "Oozie User", "home": "/var/lib/oozie"
      },
      "group": {
        "name": "Oozie", "system": true
      }
    }
```

    module.exports.configure = (ctx) ->
      require('masson/core/iptables').configure ctx
      require('masson/commons/java').configure ctx
      require('../../hadoop/core').configure ctx
      # require('../client').configure ctx
      # Internal properties
      {ryba} = ctx.config
      ryba.force_war ?= false
      # User
      oozie = ryba.oozie ?= {}
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
      # Layout
      oozie.conf_dir ?= '/etc/oozie/conf'
      oozie.data ?= '/var/db/oozie'
      oozie.log_dir ?= '/var/log/oozie'
      oozie.pid_dir ?= '/var/run/oozie'
      oozie.tmp_dir ?= '/var/tmp/oozie'

      # Configuration
      oozie.site ?= {}
      oozie.site['oozie.base.url'] = "http://#{ctx.config.host}:11000/oozie"
      # Configuration Database
      oozie.site['oozie.service.JPAService.jdbc.url'] ?= "jdbc:mysql://#{ryba.db_admin.host}:#{ryba.db_admin.port}/oozie?createDatabaseIfNotExist=true"
      oozie.site['oozie.service.JPAService.jdbc.driver'] ?= 'com.mysql.jdbc.Driver'
      oozie.site['oozie.service.JPAService.jdbc.username'] ?= 'oozie'
      oozie.site['oozie.service.JPAService.jdbc.password'] ?= 'oozie123'
      # oozie.site['oozie.service.AuthorizationService.security.enabled'] ?= null # Now deprecated in favor of oozie.service.AuthorizationService.authorization.enabled (see oozie "oozie.log" file)
      oozie.site['oozie.service.AuthorizationService.security.enabled'] ?= 'true'
      oozie.site['oozie.service.AuthorizationService.authorization.enabled'] ?= 'true'
      oozie.site['oozie.service.HadoopAccessorService.kerberos.enabled'] ?= 'true'
      oozie.site['local.realm'] ?= "#{ryba.realm}"
      oozie.site['oozie.service.HadoopAccessorService.keytab.file'] ?= '/etc/oozie/conf/oozie.service.keytab'
      oozie.site['oozie.service.HadoopAccessorService.kerberos.principal'] ?= "oozie/#{ctx.config.host}@#{ryba.realm}"
      oozie.site['oozie.authentication.type'] ?= 'kerberos'
      oozie.site['oozie.authentication.kerberos.principal'] ?= "HTTP/#{ctx.config.host}@#{ryba.realm}"
      oozie.site['oozie.authentication.kerberos.keytab'] ?= '/etc/oozie/conf/spnego.service.keytab'
      # oozie.site['oozie.service.HadoopAccessorService.nameNode.whitelist'] = ''
      oozie.site['oozie.authentication.kerberos.name.rules'] ?= ryba.core_site['hadoop.security.auth_to_local']
      oozie.site['oozie.service.HadoopAccessorService.nameNode.whitelist'] ?= '' # Fix space value
      oozie.site['oozie.services'] ?= [
        'org.apache.oozie.service.SchedulerService'
        'org.apache.oozie.service.InstrumentationService'
        'org.apache.oozie.service.MemoryLocksService'
        'org.apache.oozie.service.UUIDService'
        'org.apache.oozie.service.ELService'
        'org.apache.oozie.service.AuthorizationService'
        'org.apache.oozie.service.UserGroupInformationService'
        'org.apache.oozie.service.HadoopAccessorService'
        'org.apache.oozie.service.JobsConcurrencyService'
        'org.apache.oozie.service.URIHandlerService'
        'org.apache.oozie.service.DagXLogInfoService'
        'org.apache.oozie.service.SchemaService'
        'org.apache.oozie.service.LiteWorkflowAppService'
        'org.apache.oozie.service.JPAService'
        'org.apache.oozie.service.StoreService'
        'org.apache.oozie.service.CoordinatorStoreService'
        'org.apache.oozie.service.SLAStoreService'
        'org.apache.oozie.service.DBLiteWorkflowStoreService'
        'org.apache.oozie.service.CallbackService'
        'org.apache.oozie.service.ShareLibService'
        'org.apache.oozie.service.CallableQueueService'
        'org.apache.oozie.service.ActionService'
        'org.apache.oozie.service.ActionCheckerService'
        'org.apache.oozie.service.RecoveryService'
        'org.apache.oozie.service.PurgeService'
        'org.apache.oozie.service.CoordinatorEngineService'
        'org.apache.oozie.service.BundleEngineService'
        'org.apache.oozie.service.DagEngineService'
        'org.apache.oozie.service.CoordMaterializeTriggerService'
        'org.apache.oozie.service.StatusTransitService'
        'org.apache.oozie.service.PauseTransitService'
        'org.apache.oozie.service.GroupsService'
        'org.apache.oozie.service.ProxyUserService'
        'org.apache.oozie.service.XLogStreamingService'
        'org.apache.oozie.service.JvmPauseMonitorService'
      ].join(',')
      # ryba.extjs ?= {}
      # throw new Error "Missing extjs.source" unless ryba.extjs.source
      # throw new Error "Missing extjs.destination" unless ryba.extjs.destination
      # Note, we might also enrich "oozie.credentials.credentialclasses"
      # For example
      # ryba.oozie.site['oozie.credentials.credentialclasses'] = """
      # hcat=org.apache.oozie.action.hadoop.HCatCredentials,
      # hbase=org.apache.oozie.action.hadoop.HbaseCredentials
      # """

## Configuration for Proxy Users

      ryba.oozie.site['oozie.service.ProxyUserService.proxyuser.hive.hosts'] ?= "*"
      ryba.oozie.site['oozie.service.ProxyUserService.proxyuser.hive.groups'] ?= "*"
      ryba.oozie.site['oozie.service.ProxyUserService.proxyuser.hue.hosts'] ?= "*"
      ryba.oozie.site['oozie.service.ProxyUserService.proxyuser.hue.groups'] ?= "*"
      falcon_cts = ctx.contexts 'ryba/falcon', require('../../falcon').configure
      if falcon_cts.length
        {user} = falcon_cts[0].config.ryba.falcon
        ryba.oozie.site["oozie.service.ProxyUserService.proxyuser.#{user.name}.hosts"] ?= "*"
        ryba.oozie.site["oozie.service.ProxyUserService.proxyuser.#{user.name}.groups"] ?= "*"
        ryba.oozie.site['oozie.service.URIHandlerService.uri.handlers'] ?= "org.apache.oozie.dependency.FSURIHandler,org.apache.oozie.dependency.HCatURIHandler"
        ryba.oozie.site['oozie.service.ELService.ext.functions.coord-job-submit-instances'] ?= """
          now=org.apache.oozie.extensions.OozieELExtensions#ph1_now_echo,
          today=org.apache.oozie.extensions.OozieELExtensions#ph1_today_echo,
          yesterday=org.apache.oozie.extensions.OozieELExtensions#ph1_yesterday_echo,
          currentMonth=org.apache.oozie.extensions.OozieELExtensions#ph1_currentMonth_echo,
          lastMonth=org.apache.oozie.extensions.OozieELExtensions#ph1_lastMonth_echo,
          currentYear=org.apache.oozie.extensions.OozieELExtensions#ph1_currentYear_echo,
          lastYear=org.apache.oozie.extensions.OozieELExtensions#ph1_lastYear_echo,
          formatTime=org.apache.oozie.coord.CoordELFunctions#ph1_coord_formatTime_echo,
          latest=org.apache.oozie.coord.CoordELFunctions#ph2_coord_latest_echo,
          future=org.apache.oozie.coord.CoordELFunctions#ph2_coord_future_echo
          """
        ryba.oozie.site['oozie.service.ELService.ext.functions.coord-action-create-inst'] ?= """
          now=org.apache.oozie.extensions.OozieELExtensions#ph2_now_inst,
          today=org.apache.oozie.extensions.OozieELExtensions#ph2_today_inst,
          yesterday=org.apache.oozie.extensions.OozieELExtensions#ph2_yesterday_inst,
          currentMonth=org.apache.oozie.extensions.OozieELExtensions#ph2_currentMonth_inst,
          lastMonth=org.apache.oozie.extensions.OozieELExtensions#ph2_lastMonth_inst,
          currentYear=org.apache.oozie.extensions.OozieELExtensions#ph2_currentYear_inst,
          lastYear=org.apache.oozie.extensions.OozieELExtensions#ph2_lastYear_inst,
          latest=org.apache.oozie.coord.CoordELFunctions#ph2_coord_latest_echo,
          future=org.apache.oozie.coord.CoordELFunctions#ph2_coord_future_echo,
          formatTime=org.apache.oozie.coord.CoordELFunctions#ph2_coord_formatTime,
          user=org.apache.oozie.coord.CoordELFunctions#coord_user
          """
        ryba.oozie.site['oozie.service.ELService.ext.functions.coord-action-start'] ?= """
          now=org.apache.oozie.extensions.OozieELExtensions#ph2_now,
          today=org.apache.oozie.extensions.OozieELExtensions#ph2_today,
          yesterday=org.apache.oozie.extensions.OozieELExtensions#ph2_yesterday,
          currentMonth=org.apache.oozie.extensions.OozieELExtensions#ph2_currentMonth,
          lastMonth=org.apache.oozie.extensions.OozieELExtensions#ph2_lastMonth,
          currentYear=org.apache.oozie.extensions.OozieELExtensions#ph2_currentYear,
          lastYear=org.apache.oozie.extensions.OozieELExtensions#ph2_lastYear,
          latest=org.apache.oozie.coord.CoordELFunctions#ph3_coord_latest,
          future=org.apache.oozie.coord.CoordELFunctions#ph3_coord_future,
          dataIn=org.apache.oozie.extensions.OozieELExtensions#ph3_dataIn,
          instanceTime=org.apache.oozie.coord.CoordELFunctions#ph3_coord_nominalTime,
          dateOffset=org.apache.oozie.coord.CoordELFunctions#ph3_coord_dateOffset,
          formatTime=org.apache.oozie.coord.CoordELFunctions#ph3_coord_formatTime,
          user=org.apache.oozie.coord.CoordELFunctions#coord_user
          """
        ryba.oozie.site['oozie.service.ELService.ext.functions.coord-sla-submit'] = """
          instanceTime=org.apache.oozie.coord.CoordELFunctions#ph1_coord_nominalTime_echo_fixed,
          user=org.apache.oozie.coord.CoordELFunctions#coord_user
          """
        ryba.oozie.site['oozie.service.ELService.ext.functions.coord-sla-create'] = """
          instanceTime=org.apache.oozie.coord.CoordELFunctions#ph2_coord_nominalTime,
          user=org.apache.oozie.coord.CoordELFunctions#coord_user
          """

## Configuration for Hadoop

      ryba.oozie.hadoop_config ?= {}
      ryba.oozie.hadoop_config['mapreduce.jobtracker.kerberos.principal'] ?= "mapred/#{ryba.static_host}@#{ryba.realm}"
      ryba.oozie.hadoop_config['yarn.resourcemanager.principal'] ?= "yarn/#{ryba.static_host}@#{ryba.realm}"
      ryba.oozie.hadoop_config['dfs.namenode.kerberos.principal'] ?= "hdfs/#{ryba.static_host}@#{ryba.realm}"
      ryba.oozie.hadoop_config['mapreduce.framework.name'] ?= "yarn"

## Commands

    module.exports.push commands: 'backup', modules: 'ryba/oozie/server/backup'

    # module.exports.push commands: 'check', modules: 'ryba/oozie/server/check'

    module.exports.push commands: 'install', modules: 'ryba/oozie/server/install'

    module.exports.push commands: 'start', modules: 'ryba/oozie/server/start'

    module.exports.push commands: 'status', modules: 'ryba/oozie/server/status'

    module.exports.push commands: 'stop', modules: 'ryba/oozie/server/stop'