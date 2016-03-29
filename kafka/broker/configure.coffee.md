

## Configure Kafka Broker
Example:

```json
{
  "ryba": {
    "kafka": {
      "broker": {
        "heapsize": 1024
      }
    }
  }
}
```

    module.exports = handler: ->
      kafka = @config.ryba.kafka ?= {}
      # Group
      kafka.group = name: kafka.group if typeof kafka.group is 'string'
      kafka.group ?= {}
      kafka.group.name ?= 'kafka'
      kafka.group.system ?= true
      # User
      kafka.user ?= {}
      kafka.user = name: kafka.user if typeof kafka.user is 'string'
      kafka.user.name ?= kafka.group.name
      kafka.user.system ?= true
      kafka.user.comment ?= 'Kafka User'
      kafka.user.home = "/var/lib/#{kafka.user.name}"
      kafka.user.gid = kafka.group.name
      # ZooKeeper Quorun
      zoo_ctxs = @contexts 'ryba/zookeeper/server', require('../../zookeeper/server/configure').configure
      zookeeper_quorum = kafka.zookeeper_quorum ?= for zoo_ctx in zoo_ctxs
        "#{zoo_ctx.config.host}:#{zoo_ctx.config.ryba.zookeeper.port}"
      kafka.admin ?= {}
      kafka.admin.principal ?= kafka.user.name
      kafka.admin.password ?= 'kafka123'
      #list of kafka superusers
      kafka.superusers ?= ["#{kafka.admin.principal}"]

# Configuration

      kafka.broker ?= {}
      # Layout
      kafka.broker.conf_dir ?= '/etc/kafka-broker/conf'
      kafka.broker['heapsize'] ?= '1024'
      kafka.broker.config ?= {}
      kafka.broker.config['log.dirs'] ?= '/var/kafka'  # Comma-separated, default is "/tmp/kafka-logs"
      kafka.broker.config['log.dirs'] = kafka.broker['log.dirs'].join ',' if Array.isArray kafka.broker['log.dirs']
      kafka.broker.config['zookeeper.connect'] ?= zookeeper_quorum
      kafka.broker.config['log.retention.hours'] ?= '168'
      kafka.broker.config['delete.topic.enable'] ?= 'true'
      kafka.broker.config['zookeeper.set.acl'] ?= 'true'
      kafka.broker.config['super.users'] ?= kafka.superusers.map( (user) -> "User:#{user}").join(',')
      hosts = @contexts('ryba/kafka/broker').map (ctx) -> ctx.config.host
      kafka.broker.config['num.partitions'] ?= hosts.length # Default number of log partitions per topic, default is "2"
      for host, i in hosts
        kafka.broker.config['broker.id'] ?= "#{i}" if host is @config.host

# Environment

      kafka.broker.env ?= {}
      # A more agressive configuration for production is provided here:
      # http://docs.confluent.io/1.0.1/kafka-rest/docs/deployment.html#jvm
      kafka.broker.env['KAFKA_HEAP_OPTS'] ?= "-Xmx#{kafka.broker['heapsize']}m -Xms#{kafka.broker['heapsize']}m"
      # Avoid console verbose ouput in a non-rotated kafka.out file
      # kafka.broker.env['KAFKA_LOG4J_OPTS'] ?= "-Dlog4j.configuration=file:$base_dir/../config/log4j.properties -Dkafka.root.logger=INFO, kafkaAppender"
      kafka.broker.env['KAFKA_LOG4J_OPTS'] ?= "-Dlog4j.configuration=file:$base_dir/../config/log4j.properties"
      kafka.broker.log4j ?= {}
      kafka.broker.log4j['log4j.rootLogger'] ?= 'INFO, kafkaAppender'
      # kafka.broker.log4j['log4j.logger.kafka.authorizer.logger'] ?= 'DEBUG, authorizerAppender'
      kafka.broker.log4j['log4j.additivity.kafka'] ?= "false"
      # Push user and group configuration to consumer and producer
      # for csm_ctx in ctx.contexts ['ryba/kafka/consumer', 'ryba/kafka/producer']
      #   csm_ctx.config.ryba ?= {}
      #   csm_ctx.config.ryba.kafka ?= {}
      #   csm_ctx.config.ryba.kafka.user ?= kafka.user
      #   csm_ctx.config.ryba.kafka.group ?= kafka.group

# Kafka Broker Protocols

Sarting from 0.9, kafka broker supports multiple secured and un-secured protocols when
broadcasting messages for broker/broker and client/broker communications.
They are PLAINTEXT, SSL, SASL_PLAINTEXT, SASL_SSL.
By default it set at least to SSL for broker/broker and client/broker.
For broker/client communication all protocols are supported.
For broker/broker communication we allow only SSL or SASL_SSL.
Needed protocols can be set at cluster config level.

Example only PLAINTEXT:
{
  "ryba": {
    "kafka": {
      "broker": {
        "protocols" : "PLAINTEXT"
      }
    }
  }
}
Example PLAINTEXT and SSL:
{
  "ryba": {
    "kafka": {
      "broker": {
        "protocols" : ["PLAINTEXT","SSL"]
      }
    }
  }
}

      kafka.broker.protocols ?= if @config.ryba.security is 'kerberos' then ['SASL_SSL'] else ['SSL']
      return Error 'No protocol specified' unless kafka.broker.protocols.length > 0
      kafka.ports ?= {}
      kafka.ports['PLAINTEXT'] ?= '9092'
      kafka.ports['SSL'] ?= '9093'
      kafka.ports['SASL_PLAINTEXT'] ?= '9094'
      kafka.ports['SASL_SSL'] ?= '9096'

# Security SSL

      # for protocol in kafka.broker.protocols
      #   continue unless ['SASL_SSL','SSL'].indexOf(protocol) > -1
      kafka.broker.config['ssl.keystore.location'] ?= "#{kafka.broker.conf_dir}/keystore"
      kafka.broker.config['ssl.keystore.password'] ?= 'ryba123'
      kafka.broker.config['ssl.key.password'] ?= 'ryba123'
      kafka.broker.config['ssl.truststore.location'] ?= "#{kafka.broker.conf_dir}/truststore"
      kafka.broker.config['ssl.truststore.password'] ?= 'ryba123'

# Security Kerberos & ACL

      secure_cluster = false
      if kafka.broker.config['zookeeper.set.acl'] is 'true'
        secure_cluster = true
        kafka.broker.kerberos ?= {}
        kafka.broker.kerberos['principal'] ?= "#{kafka.user.name}/#{@config.host}@#{@config.ryba.realm}"
        kafka.broker.kerberos['keyTab'] ?= '/etc/security/keytabs/kafka.service.keytab'
        match = /^(.+?)[@\/]/.exec kafka.broker.kerberos['principal']
        kafka.broker.config['sasl.kerberos.service.name'] = "#{match[1]}"
        # set to true to be able to use 9092 if PLAINTEXT only mode is enabled
        kafka.broker.config['allow.everyone.if.no.acl.found'] ?= 'true'
        kafka.broker.config['authorizer.class.name'] = 'kafka.security.auth.SimpleAclAuthorizer'
        kafka.broker.env['KAFKA_KERBEROS_PARAMS'] ?= "-Djava.security.auth.login.config=#{kafka.broker.conf_dir}/kafka-server.jaas"

# Brokers internal communication

        kafka.broker.config['replication.security.protocol'] ?= 'SASL_SSL'
      else
        kafka.broker.config['replication.security.protocol'] ?= 'SSL'
      for prot in kafka.broker.protocols
          throw Error 'ACL must be activated' if ( prot.indexOf('SASL') > -1 and not secure_cluster)


# Listeners Protocols

      kafka.broker.config['listeners'] ?= kafka.broker.protocols.map( (protocol) =>
        "#{protocol}://#{@config.host}:#{kafka.ports[protocol]}").join(',')


[kafka-security]:(http://kafka.apache.org/documentation.html#security)
[hdp-security-kafka]:(https://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.3.4/bk_Security_Guide/content/ch_wire-kafka.html)