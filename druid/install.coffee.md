
# Druid Install

    module.exports = header: 'Druid Install', handler: ->
      {druid, realm, db_admin} = @config.ryba
      krb5 = @config.krb5.etc_krb5_conf.realms[realm]

## Register and load

      @register 'hconfigure', 'ryba/lib/hconfigure'
      @register 'hdfs_mkdir', 'ryba/lib/hdfs_mkdir'
      @call once: true, 'ryba/commons/db_admin'

## IPTables

| Service   | Port       | Proto     | Parameter                   |
|-----------|------------|-----------|-----------------------------|
| Druid Standalone Realtime    | 8084      | tcp/http  |  |
| Druid Router    | 8088      | tcp/http  |  |

Note, this hasnt been verified.

      # @iptables
      #   header: 'IPTables'
      #   rules: [
      #     { chain: 'INPUT', jump: 'ACCEPT', dport: port, protocol: 'tcp', state: 'NEW', comment: "Falcon Prism Local EndPoint" }
      #   ]
      #   if: @config.iptables.action is 'start'

## Users & Groups

By default, the "druid" package create the following entries:

```bash
cat /etc/passwd | grep druid
druid:x:2435:2435:druid User:/var/lib/druid:/bin/bash
cat /etc/group | grep druid
druid:x:2435:
```

      @group druid.group
      @user druid.user

## Packages

Download and unpack the release archive.

      @service
        name: 'postgresql'
        if: druid.db.engine is 'postgres'
      @service
        name: 'mysql'
        if: druid.db.engine is 'mysql'
      @download
        header: 'Packages'
        source: "#{druid.source}"
        target: "/var/tmp/#{path.basename druid.source}"
      # TODO, could be improved
      # current implementation prevent any further attempt if download status is true and extract fails
      @extract
        source: "/var/tmp/#{path.basename druid.source}"
        target: '/opt'
        if: -> @status -1
      @link
        source: "/opt/druid-#{druid.version}"
        target: "#{druid.dir}"
      @execute
        cmd: """
        if [ $(stat -c "%U" /opt/druid-#{druid.version}) == '#{druid.user.name}' ]; then exit 3; fi
        chown -R #{druid.user.name}:#{druid.group.name} /opt/druid-#{druid.version}
        """
        code_skipped: 3

## Layout

Pid files are stored inside "/var/run/druid" by default.
Log files are stored inside "/var/log/druid" by default.

      @call header: 'Layout', handler: ->
        @mkdir
          target: "#{druid.pid_dir}"
          uid: "#{druid.user.name}"
          gid: "#{druid.group.name}"
          parent: true
        @link
          target: "#{druid.dir}/var/druid/pids"
          source: "#{druid.pid_dir}"
        @mkdir
          target: "#{druid.log_dir}"
          uid: "#{druid.user.name}"
          gid: "#{druid.group.name}"
          parent: true
        @link
          source: "#{druid.log_dir}"
          target: "#{druid.dir}/log"

## Kerberos

Create a service principal for this NameNode. The principal is named after
"nn/#{@config.host}@#{realm}".

      @krb5_addprinc krb5,
        header: 'Kerberos Admin Principal'
        principal: "#{druid.krb5_admin.principal}"
        password: "#{druid.krb5_admin.password}"
        randkey: true
        uid: 'druid'
        gid: 'druid'
        mode: 0o0600
      @krb5_addprinc krb5,
        header: 'Kerberos Service Principal'
        principal: "#{druid.krb5_service.principal}"
        keytab: "#{druid.krb5_service.keytab}"
        randkey: true
        uid: "#{druid.user.name}"
        gid: "#{druid.group.name}"
        mode: 0o0600

## Cron-ed Kinit

Druid has no mechanism to renew its keytab. For that, we use a cron daemon
We then ask a first TGT.

      @cron.add
        header: 'Cron-ed kinit'
        cmd: "/usr/bin/kinit #{druid.krb5_service.principal} -kt #{druid.krb5_service.keytab}"
        when: '0 */9 * * *'
        user: 'druid'
        exec: true

## Configuration

Configure deep storage.

      @db.user druid.db,
        if: druid.db.engine in ['mysql', 'postgres']
      @db.database druid.db,
        if: druid.db.engine in ['mysql', 'postgres']
        user: druid.db.username
      @file.properties
        target: "/opt/druid-#{druid.version}/conf/druid/_common/common.runtime.properties"
        content: druid.common_runtime
        backup: true
      @copy
        target: "/opt/druid-#{druid.version}/conf/druid/_common/core-site.xml"
        source: '/etc/hadoop/conf/core-site.xml'
      @copy
        target: "/opt/druid-#{druid.version}/conf/druid/_common/hdfs-site.xml"
        source: '/etc/hadoop/conf/hdfs-site.xml'
      @hconfigure
        target: "/opt/druid-#{druid.version}/conf/druid/_common/yarn-site.xml"
        source: '/etc/hadoop/conf/yarn-site.xml'
        transform: (properties) ->
          if properties['yarn.resourcemanager.ha.rm-ids']
            [id] = properties['yarn.resourcemanager.ha.rm-ids'].split ','
            properties['yarn.resourcemanager.address'] = properties["yarn.resourcemanager.address.#{id}"]
          properties
      @hconfigure
        target: "/opt/druid-#{druid.version}/conf/druid/_common/mapred-site.xml"
        source: '/etc/hadoop/conf/mapred-site.xml'
        transform: (properties) ->
          classpath = properties['mapreduce.application.classpath'].split ','
          jar_validation = "/opt/druid-#{druid.version}/lib/validation-api-1.1.0.Final.jar"
          classpath.push jar_validation unless jar_validation in classpath
          properties['mapreduce.application.classpath'] = classpath.join ','
          properties
      @hdfs_mkdir
        target: '/apps/druid/segments'
        user: "#{druid.user.name}"
        group: "#{druid.group.name}"
        mode: 0o0750
        krb5_user: @config.ryba.hdfs.krb5_user
      @hdfs_mkdir
        target: '/apps/druid/indexing-logs'
        user: "#{druid.user.name}"
        group: "#{druid.group.name}"
        mode: 0o0750
        krb5_user: @config.ryba.hdfs.krb5_user
      @hdfs_mkdir
        target: "/user/#{druid.user.name}"
        user: "#{druid.user.name}"
        group: "#{druid.group.name}"
        mode: 0o0750
        krb5_user: @config.ryba.hdfs.krb5_user

## Dependencies

    db = require 'mecano/lib/misc/db'
    path = require 'path'