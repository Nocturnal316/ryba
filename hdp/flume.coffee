
module.exports = []

###

[Flume Account Requirements](https://www.cloudera.com/content/cloudera-content/cloudera-docs/CDH4/latest/CDH4-Security-Guide/cdh4sg_topic_4_3.html)

*   Flume agent machine that writes to HDFS (via a configured HDFS sink) 
    needs a Kerberos principal of the form: 
    flume/fully.qualified.domain.name@YOUR-REALM.COM
*   Each Flume agent machine that writes to HDFS does not need to 
    have a flume Unix user account to write files owned by the flume 
    Hadoop/Kerberos user. Only the keytab for the flume Hadoop/Kerberos 
    user is required on the Flume agent machine.   
*   DataNode machines do not need Flume Kerberos keytabs and also do 
    not need the flume Unix user account.   
*   TaskTracker (MRv1) or NodeManager (YARN) machines need a flume Unix 
    user account if and only if MapReduce jobs are being run as the 
    flume Hadoop/Kerberos user.   
*   The NameNode machine needs to be able to resolve the groups of the 
    flume user. The groups of the flume user on the NameNode machine 
    are mapped to the Hadoop groups used for authorizing access.   
*   The NameNode machine does not need a Flume Kerberos keytab.   

[Secure Impersonation]](https://www.cloudera.com/content/cloudera-content/cloudera-docs/CDH4/latest/CDH4-Security-Guide/cdh4sg_topic_4_2.html)
###
module.exports.push module.exports.configure = (ctx) ->
  require('../actions/krb5_client').configure ctx
  ctx.config.hdp ?= {}
  ctx.config.hdp.flume_user = 'flume'
  ctx.config.hdp.flume_group = 'flume'
  ctx.config.hdp.flume_conf_dir = '/etc/flume/conf'

module.exports.push name: 'HDP Flume # Install', timeout: -1, callback: (ctx, next) ->
  ctx.service name: 'flume', (err, serviced) ->
    next err, if serviced then ctx.OK else ctx.PASS

module.exports.push name: 'HDP Flume # Kerberos', callback: (ctx, next) ->
  {flume_user, flume_group, flume_conf_dir} = ctx.config.hdp
  {realm, kadmin_principal, kadmin_password, kadmin_server} = ctx.config.krb5_client
  ctx.krb5_addprinc 
    principal: "hue/#{ctx.config.host}@#{realm}"
    randkey: true
    keytab: "#{flume_conf_dir}/flume.service.keytab"
    uid: flume_user
    gid: flume_group
    kadmin_principal: kadmin_principal
    kadmin_password: kadmin_password
    kadmin_server: kadmin_server
  , (err, created) ->
    next err, if created then ctx.OK else ctx.PASS
    
module.exports.push name: 'HDP Flume # Check', timeout: -1, callback: (ctx, next) ->
  ctx.write
    content: """
    # Name the components on this agent
    a1.sources = r1
    a1.sinks = k1, k2
    a1.channels = c1
    # Describe/configure the source
    a1.sources.r1.type = netcat
    a1.sources.r1.bind = localhost
    a1.sources.r1.port = 44444
    a1.sinks.k1.type = HDFS
    a1.sinks.k1.hdfs.kerberosPrincipal = flume/_HOST@YOUR-REALM.COM
    a1.sinks.k1.hdfs.kerberosKeytab = /etc/flume/conf/flume.keytab
    a1.sinks.k1.hdfs.proxyUser = test
    a1.sinks.k2.type = HDFS
    a1.sinks.k2.hdfs.kerberosPrincipal = flume/_HOST@YOUR-REALM.COM
    a1.sinks.k2.hdfs.kerberosKeytab = /etc/flume/conf/flume.keytab
    a1.sinks.k2.hdfs.proxyUser = hdfs
    """
    destination: '/tmp/flume.conf'
  , (err, written) ->
    return next err if written
    next null, ctx.OK
    # ctx.execute
    #   cmd: "flume-ng agent --conf conf --conf-file example.conf --name a1 -Dflume.root.logger=INFO,console"


# flume node_nowatch -1 -n dump -c 'dump: console |  collectorSink("hdfs://kerb-nn/user/flume/%Y%m%D-%H/","testkerb");'














