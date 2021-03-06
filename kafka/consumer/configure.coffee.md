

## Configure

    module.exports = ->
      kafka = @config.ryba.kafka ?= {}
      # ZooKeeper Quorum
      zoo_ctxs = @contexts('ryba/zookeeper/server').filter( (ctx) -> ctx.config.ryba.zookeeper.config['peerType'] is 'participant')
      zookeeper_quorum = for zoo_ctx in zoo_ctxs
        "#{zoo_ctx.config.host}:#{zoo_ctx.config.ryba.zookeeper.port}"
      ks_ctxs = @contexts 'ryba/kafka/broker'
      throw Error 'Cannot configure kafka consumer without broker' unless ks_ctxs.length > 0

## Identities

By default, merge group and user from the Kafka broker configuration.

      kafka.group = merge ks_ctxs[0].config.ryba.kafka.group, kafka.group
      kafka.user = merge ks_ctxs[0].config.ryba.kafka.user, kafka.user

## Configuration

      kafka.admin ?= {}
      kafka.admin.principal ?= ks_ctxs[0].config.ryba.kafka.admin.principal
      kafka.admin.password ?= ks_ctxs[0].config.ryba.kafka.admin.password
      kafka.consumer ?= {}
      kafka.consumer.conf_dir ?= '/etc/kafka/conf'
      kafka.consumer.config ?= {}
      kafka.consumer.config['zookeeper.connect'] ?= zookeeper_quorum
      kafka.consumer.config['group.id'] ?= 'ryba-consumer-group'
      # for now the prop 'sasl.kerberos.service.name' has to be deleted because of
      # https://issues.apache.org/jira/browse/KAFKA-2974
      # http://mail-archives.apache.org/mod_mbox/kafka-commits/201512.mbox/%3Cacb73f26d3bd440ab8a9f33686db0020@git.apache.org%3E
      # which result with the error:
      # Conflicting serviceName values found in JAAS and Kafka configs value in JAAS file kafka, value in Kafka config kafka
      # fixed in 0.9.0.1
      # kafka.consumer.config['sasl.kerberos.service.name'] =  ks_ctxs[0].config.ryba.kafka.broker.config['sasl.kerberos.service.name']
      delete kafka.consumer.config['sasl.kerberos.service.name']
      # producer config does not support several protocol like kafka/broker (e.g. 'listeners' property)
      # thats why we make dynamic discovery of the best protocol available
      # and pass needed protocol to command line in the checks
      protocols = ks_ctxs[0].config.ryba.kafka.broker.protocols
      ssl_enabled = if  ks_ctxs[0].config.ryba.kafka.broker.config['ssl.keystore.location'] then true else false
      sasl_enabled = if  ks_ctxs[0].config.ryba.kafka.broker.kerberos then true else false
      protocol = ''
      if sasl_enabled
        protocol = 'SASL_PLAINTEXT'
        if ssl_enabled
          protocol = 'SASL_SSL'
      else
        if ssl_enabled
          protocol = 'SSL'
        else
          protocol = 'PLAINTEXT'
      brokers = for ks_ctx in ks_ctxs
        "#{ks_ctx.config.host}:#{ks_ctx.config.ryba.kafka.broker.ports[protocol]}"
      kafka.producer.config['security.protocol'] ?= protocol
      kafka.producer.config['bootstrap.servers'] ?= brokers.join ','
      kafka.consumer.config['security.protocol'] ?= protocol
      kafka.consumer.log4j ?= {}
      kafka.consumer.log4j['log4j.rootLogger'] ?= 'WARN, stdout'
      kafka.consumer.log4j['log4j.appender.stdout'] ?= 'org.apache.log4j.ConsoleAppender'
      kafka.consumer.log4j['log4j.appender.stdout.layout'] ?= 'org.apache.log4j.PatternLayout'
      kafka.consumer.log4j['log4j.appender.stdout.layout.ConversionPattern'] ?= '[%d] %p %m (%c)%n'
      kafka.consumer.protocols ?= protocols

## SSL

      ssl_enabled = false
      for protocol in ks_ctxs[0].config.ryba.kafka.broker.protocols
        continue unless ['SASL_SSL','SSL'].indexOf(protocol) > -1
        ssl_enabled = true
      if ssl_enabled
        kafka.consumer.config['ssl.truststore.location'] ?= "#{kafka.consumer.conf_dir}/truststore"
        kafka.consumer.config['ssl.truststore.password'] ?= 'ryba123'
        # kafka.consumer.config['ssl.keystore.location'] ?= "#{kafka.consumer.conf_dir}/keystore"
        # kafka.consumer.config['ssl.keystore.password'] ?= 'ryba123'
        # kafka.consumer.config['ssl.key.password'] ?= 'ryba123'

## Kerberos

      kafka.consumer.env ?= {}
      if ks_ctxs[0].config.ryba.kafka.broker.config['zookeeper.set.acl'] is 'true'
        kafka.consumer.env['KAFKA_KERBEROS_PARAMS'] ?= "-Djava.security.auth.login.config=#{kafka.consumer.conf_dir}/kafka-client.jaas"

## Dependencies

    {merge} = require 'nikita/lib/misc'
