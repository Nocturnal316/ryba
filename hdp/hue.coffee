
misc = require 'mecano/lib/misc'
# path = require 'path'
# lifecycle = require './lib/lifecycle'
# mkcmd = require './lib/mkcmd'

###

Resources:   
*   [Hortonworks instruction](http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.0.8.0/bk_installing_manually_book/content/rpm-chap-hue.html)

###
module.exports = []

# Install the mysql connector
module.exports.push 'histi/actions/mysql_client'
# Install client to create new Hive principal
module.exports.push 'histi/actions/krb5_client'

# module.exports.push 'histi/hdp/hdfs'
# module.exports.push 'histi/hdp/yarn'
# module.exports.push 'histi/hdp/oozie_client'
# module.exports.push 'histi/hdp/hive_client'
module.exports.push 'histi/hdp/pig'
# module.exports.push 'histi/hdp/hbase'

module.exports.push (ctx) ->
  # Allow proxy user inside "webhcat-site.xml"
  throw new Error 'WebHCat server must be installed on the Hue node' unless ctx.has_module 'histi/hdp/webhcat'
  require('./webhcat').configure ctx
  # Allow proxy user inside "oozie-site.xml"
  throw new Error 'Oozie server must be installed on the Hue node' unless ctx.has_module 'histi/hdp/oozie_server'
  require('./oozie_').configure ctx
  # Allow proxy user inside "core-site.xml"
  require('./core').configure ctx
  # require('./hdfs').configure ctx
  # Webhdfs should be active on the NameNode, Secondary NameNode, and all the DataNodes
  # throw new Error 'WebHDFS not active' if ctx.config.hdp.hdfs_site['dfs.webhdfs.enabled'] isnt 'true'
  ctx.config.hdp.hue_conf_dir ?= '/etc/hue/conf'
  ctx.config.hdp.hue_ini ?= {}
  ctx.config.hdp.hue_user ?= 'hue'
  ctx.config.hdp.hue_group ?= 'hue'

module.exports.push name: 'HDP Hue # Packages', timeout: -1, callback: (ctx, next) ->
  ctx.service [
    name: 'extjs-2.2-1'
  ,
    name: 'hue'
  ], (err, serviced) ->
    next err, if serviced then ctx.OK else ctx.PASS

module.exports.push name: 'HDP Hue # Core', callback: (ctx, next) ->
  {hadoop_conf_dir, hadoop_user, hadoop_group} = ctx.config.hdp
  properties = 
    'hadoop.proxyuser.hue.hosts': '*'
    'hadoop.proxyuser.hue.groups': '*'
    'hadoop.proxyuser.hcat.groups': '*'
    'hadoop.proxyuser.hcat.hosts': '*'
  ctx.hconfigure
    destination: "#{hadoop_conf_dir}/core-site.xml"
    properties: properties
    merge: true
  , (err, configured) ->
    return next err if err
    next err, if configured then ctx.OK else ctx.PASS

module.exports.push name: 'HDP Hue # WebHCat', callback: (ctx, next) ->
  {webhcat_conf_dir} = ctx.config.hdp
  properties = 
    'webhcat.proxyuser.hue.hosts': '*'
    'webhcat.proxyuser.hue.groups': '*'
  ctx.hconfigure
    destination: "#{webhcat_conf_dir}/webhcat-site.xml"
    properties: properties
    merge: true
  , (err, configured) ->
    return next err if err
    next err, if configured then ctx.OK else ctx.PASS

module.exports.push name: 'HDP Hue # Oozie', callback: (ctx, next) ->
  {oozie_conf_dir} = ctx.config.hdp
  properties = 
    'oozie.service.ProxyUserService.proxyuser.hue.hosts': '*'
    'oozie.service.ProxyUserService.proxyuser.hue.groups': '*'
  ctx.hconfigure
    destination: "#{oozie_conf_dir}/oozie-site.xml"
    properties: properties
    merge: true
  , (err, configured) ->
    return next err if err
    next err, if configured then ctx.OK else ctx.PASS

# # http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.0.8.0/bk_installing_manually_book/content/rpm-chap-hue-5-2.html
module.exports.push name: 'HDP Hue # Configure', callback: (ctx, next) ->
  {hadoop_conf_dir, hue_conf_dir, hue_ini, hue_smtp_host, webhcat_site} = ctx.config.hdp
  webhcat_port = webhcat_site['templeton.port']
  oozie_server = ctx.hosts_with_module 'histi/hdp/oozie_server', 1
  webhcat_server = ctx.hosts_with_module 'histi/hdp/webhcat', 1
  namenode = ctx.hosts_with_module 'histi/hdp/hdfs_nn', 1
  resourcemanager = ctx.hosts_with_module 'histi/hdp/yarn_rm', 1
  # Configure HDFS Cluster
  hue_ini['hadoop'] ?= {}
  hue_ini['hadoop']['hdfs_clusters'] ?= {}
  hue_ini['hadoop']['hdfs_clusters']['default'] ?= {}
  hue_ini['hadoop']['hdfs_clusters']['default']['fs_defaultfs'] ?= "hdfs://#{namenode}:8020"
  hue_ini['hadoop']['hdfs_clusters']['default']['webhdfs_url'] ?= "http://#{namenode}:50070/webhdfs/v1"
  hue_ini['hadoop']['hdfs_clusters']['default']['hadoop_hdfs_home'] ?= '/usr/lib/hadoop'
  hue_ini['hadoop']['hdfs_clusters']['default']['hadoop_bin'] ?= '/usr/bin/hadoop'
  hue_ini['hadoop']['hdfs_clusters']['default']['hadoop_conf_dir'] ?= hadoop_conf_dir
  # Configure YARN (MR2) Cluster
  hue_ini['hadoop']['yarn_clusters'] ?= {}
  hue_ini['hadoop']['yarn_clusters']['default'] ?= {}
  hue_ini['hadoop']['yarn_clusters']['default']['resourcemanager_host'] ?= "#{resourcemanager}"
  hue_ini['hadoop']['yarn_clusters']['default']['resourcemanager_port'] ?= "8050"
  hue_ini['hadoop']['yarn_clusters']['default']['submit_to'] ?= "true"
  hue_ini['hadoop']['yarn_clusters']['default']['resourcemanager_api_url'] ?= "http://#{resourcemanager}:8088"
  hue_ini['hadoop']['yarn_clusters']['default']['proxy_api_url'] ?= "http://#{resourcemanager}:8088" # NOT very sure
  hue_ini['hadoop']['yarn_clusters']['default']['history_server_api_url'] ?= "http://#{resourcemanager}:19888"
  hue_ini['hadoop']['yarn_clusters']['default']['node_manager_api_url'] ?= "http://#{resourcemanager}:8042"
  hue_ini['hadoop']['yarn_clusters']['default']['hadoop_mapred_home'] ?= "/usr/lib/hadoop-mapreduce"
  hue_ini['hadoop']['yarn_clusters']['default']['hadoop_bin'] ?= "/usr/bin/hadoop"
  hue_ini['hadoop']['yarn_clusters']['default']['hadoop_conf_dir'] ?= hadoop_conf_dir
  # Configure components
  hue_ini['liboozie'] ?= {}
  hue_ini['liboozie']['oozie_url'] ?= "http://#{oozie_server}:11000/oozie"
  hue_ini['hcatalog'] ?= {}
  hue_ini['hcatalog']['templeton_url'] ?= "http://#{webhcat_server}:#{webhcat_port}/oozie"
  hue_ini['beeswax'] ?= {}
  hue_ini['beeswax']['beeswax_server_host'] ?= "#{ctx.config.host}"
  # Desktop
  hue_ini['desktop'] ?= {}
  hue_ini['desktop']['http_host'] ?= '0.0.0.0'
  hue_ini['desktop']['http_port'] ?= '8000'
  hue_ini['desktop']['secret_key'] ?= 'jFE93j;2[290-eiwMYSECRTEKEYy#e=+Iei*@Mn<qW5o'
  hue_ini['desktop']['smtp'] ?= {}
  hue_ini['desktop']['smtp']['host'] ?= hue_smtp_host if hue_smtp_host
  ctx.ini
    destination: "#{hue_conf_dir}/hue.ini"
    content: hue_ini
    merge: true
    parse: misc.ini.parse_multi_brackets 
    stringify: misc.ini.stringify_multi_brackets
    separator: '='
    comment: '#'
  , (err, written) ->
    next err, if written then ctx.OK else ctx.PASS

###
TODO: install Hue over SSL
http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.0.8.0/bk_installing_manually_book/content/rpm-chap-hue-5-1.html
###
# module.exports.push name: 'HDP Hue # SSL', (ctx, next) ->
#   {hue_conf_dir, hue_ini} = ctx.config.hdp
#   ctx.execute
#     destination: "#{hue_conf_dir}/build/env/bin/easy_install"
#     write: write
#     backup: true
#   , (err, written) ->
#     next err, if written then ctx.OK else ctx.PASS

# [Kerberos instructions](http://docs.hortonworks.com/HDPDocuments/HDP1/HDP-1.3.3/bk_installing_manually_book/content/rpm-chap14-2-3-hue.html)
module.exports.push name: 'HDP Hue # Kerberos', callback: (ctx, next) ->
  {hue_user, hue_group, hue_conf_dir} = ctx.config.hdp
  {realm, kadmin_principal, kadmin_password, kadmin_server} = ctx.config.krb5_client
  principal = "hue/#{ctx.config.host}@#{realm}"
  modified = false
  do_addprinc = ->
    ctx.krb5_addprinc 
      principal: principal
      randkey: true
      keytab: "/etc/hue/conf/hue.service.keytab"
      uid: hue_user
      gid: hue_group
      kadmin_principal: kadmin_principal
      kadmin_password: kadmin_password
      kadmin_server: kadmin_server
    , (err, created) ->
      return next err if err
      modified = true if created
      do_config()
  do_config = ->
    hue_ini = {}
    hue_ini['desktop'] ?= {}
    hue_ini['desktop']['kerberos'] ?= {}
    hue_ini['desktop']['kerberos']['hue_keytab'] ?= '/etc/hue/conf/hue.service.keytab'
    hue_ini['desktop']['kerberos']['hue_principal'] ?= principal
    # Path to kinit
    # For RHEL/CentOS 5.x, kinit_path is /usr/kerberos/bin/kinit
    # For RHEL/CentOS 6.x, kinit_path is /usr/bin/kinit 
    hue_ini['desktop']['kerberos']['kinit_path'] ?= '/usr/bin/kinit'
    # Uncomment all security_enabled settings and set them to true
    hue_ini['hadoop'] ?= {}
    hue_ini['hadoop']['hdfs_clusters'] ?= {}
    hue_ini['hadoop']['hdfs_clusters']['default'] ?= {}
    hue_ini['hadoop']['hdfs_clusters']['default']['security_enabled'] = 'true'
    hue_ini['hadoop'] ?= {}
    hue_ini['hadoop']['mapred_clusters'] ?= {}
    hue_ini['hadoop']['mapred_clusters']['default'] ?= {}
    hue_ini['hadoop']['mapred_clusters']['default']['security_enabled'] = 'true'
    hue_ini['hadoop'] ?= {}
    hue_ini['hadoop']['yarn_clusters'] ?= {}
    hue_ini['hadoop']['yarn_clusters']['default'] ?= {}
    hue_ini['hadoop']['yarn_clusters']['default']['security_enabled'] = 'true'
    hue_ini['liboozie'] ?= {}
    hue_ini['liboozie']['security_enabled'] = 'true'
    hue_ini['hcatalog'] ?= {}
    hue_ini['hcatalog']['security_enabled'] = 'true'
    console.log hue_ini
    console.log "#{hue_conf_dir}/hue.ini"
    ctx.ini
      destination: "#{hue_conf_dir}/hue.ini"
      content: hue_ini
      merge: true
      parse: misc.ini.parse_multi_brackets 
      stringify: misc.ini.stringify_multi_brackets
      separator: '='
      comment: '#'
    , (err, written) ->
      return next err if err
      modified = true if written
      do_end()
  do_end = ->
    next null, if modified then ctx.OK else ctx.PASS
  do_addprinc()









