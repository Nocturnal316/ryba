
# HBase Rest Gateway Install

Note, Hortonworks recommand to grant administrative access to the _acl_ table
for the service princial define by "hbase.rest.kerberos.principal". For example,
run the command `grant '$USER', 'RWCA'`. Ryba isnt doing it because we didn't
have usecase for it yet.

    module.exports =  header: 'HBase Rest Install', handler: ->
      {hadoop_group, hbase, realm} = @config.ryba
      krb5 = @config.krb5_client.admin[realm]

## Register

      @registry.register 'hconfigure', 'ryba/lib/hconfigure'
      @registry.register 'hdp_select', 'ryba/lib/hdp_select'

## IPTables

| Service                    | Port  | Proto | Info                   |
|----------------------------|-------|-------|------------------------|
| HBase REST Server          | 60080 | http  | hbase.rest.port        |
| HBase REST Server Web UI   | 60085 | http  | hbase.rest.info.port   |

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

      @tools.iptables
        header: 'Iptables'
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: hbase.rest.site['hbase.rest.port'], protocol: 'tcp', state: 'NEW', comment: "HBase Master" }
          { chain: 'INPUT', jump: 'ACCEPT', dport: hbase.rest.site['hbase.rest.info.port'], protocol: 'tcp', state: 'NEW', comment: "HMaster Info Web UI" }
        ]
        if: @config.iptables.action is 'start'

## Identities

By default, the "hbase" package create the following entries:

```bash
cat /etc/passwd | grep hbase
hbase:x:492:492:HBase:/var/run/hbase:/bin/bash
cat /etc/group | grep hbase
hbase:x:492:
```

      @system.group header: 'Group', hbase.group
      @system.user header: 'User', hbase.user

## HBase Rest Server Layout

      @call header: 'Layout', ->
        @system.mkdir
          target: hbase.rest.pid_dir
          uid: hbase.user.name
          gid: hbase.group.name
          mode: 0o0755
        @system.mkdir
          target: hbase.rest.log_dir
          uid: hbase.user.name
          gid: hbase.group.name
          mode: 0o0755
        @system.mkdir
          target: hbase.rest.conf_dir
          uid: hbase.user.name
          gid: hbase.group.name
          mode: 0o0755

## HBase Rest Service

      @call header: 'Service', (options) ->
        @service
          name: 'hbase-rest'
        @hdp_select
          name: 'hbase-client'
        @service.init
          if_os: name: ['redhat','centos'], version: '6'
          header: 'Init Script'
          source: "#{__dirname}/../resources/hbase-rest.j2"
          local: true
          context: @config
          target: '/etc/init.d/hbase-rest'
          mode: 0o0755
          unlink: true
        @call
          if_os: name: ['redhat','centos'], version: '7'
        , ->
          @service.init
            header: 'Systemd Script'
            target: '/usr/lib/systemd/system/hbase-rest.service'
            source: "#{__dirname}/../resources/hbase-rest-systemd.j2"
            local: true
            context: @config.ryba
            mode: 0o0640
          @system.tmpfs
            header: 'Run dir'
            mount: hbase.rest.pid_dir
            uid: hbase.user.name
            gid: hbase.group.name
            perm: '0755'

## Configure

Note, we left the permission mode as default, Master and RegionServer need to
restrict it but not the rest server.

      @hconfigure
        header: 'HBase Site'
        target: "#{hbase.rest.conf_dir}/hbase-site.xml"
        source: "#{__dirname}/../resources/hbase-site.xml"
        local: true
        properties: hbase.rest.site
        uid: hbase.user.name
        gid: hbase.group.name
        mode: 0o600
        backup: true

## Env

Environment passed to the HBase Rest Server before it starts.

      @file.render
        header: 'Hbase Env'
        target: "#{hbase.rest.conf_dir}/hbase-env.sh"
        source: "#{__dirname}/../resources/hbase-env.sh.j2"
        local: true
        context: @config
        mode: 0o0750
        uid: hbase.user.name
        gid: hbase.group.name
        unlink: true
        write: for k, v of hbase.rest.env
          match: RegExp "export #{k}=.*", 'm'
          replace: "export #{k}=\"#{v}\" # RYBA, DONT OVERWRITE"

## Kerberos

Create the Kerberos keytab for the service principal.

      @krb5.addprinc krb5,
        header: 'Kerberos'
        principal: hbase.rest.site['hbase.rest.kerberos.principal'].replace '_HOST', @config.host
        randkey: true
        keytab: hbase.rest.site['hbase.rest.keytab.file']
        uid: hbase.user.name
        gid: hadoop_group.name

# User limits

      @system.limits
        header: 'Ulimit'
        user: hbase.user.name
      , hbase.user.limits

## Logging

      @file
        header: 'Log4J'
        target: "#{hbase.rest.conf_dir}/log4j.properties"
        source: "#{__dirname}/../resources/log4j.properties"
        local: true
