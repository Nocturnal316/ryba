
## Configuration for metrics

Configuration of HBase metrics system.

The File sink is activated by default. The Ganglia and Graphite sinks are
automatically activated if the "ryba/ganglia/collector" and
"ryba/graphite/collector" are respectively registered on one of the nodes of the
cluster. You can disable any of those sinks by setting its class to "false", here
how:

```json
{ "ryba": { hbase: {"metrics": 
  "*.sink.file.class": false, 
  "*.sink.ganglia.class": false, 
  "*.sink.graphite.class": false
 } } }
```

Metrics can be filtered by context (in this exemple "master", "regionserver",
"jvm" and "ugi"). The list of available contexts can be obtained from HTTP, read
the [HBase documentation](http://hbase.apache.org/book.html#_hbase_metrics) for
additionnal informations.

```json
{ "ryba": { hbase: {"metrics": 
  "hbase.sink.file-all.filename": "hbase-metrics-all.out",
  "hbase.sink.file-master.filename": "hbase-metrics-master.out",
  "hbase.sink.file-master.context": "mastert",
  "hbase.sink.file-regionserver.filename": "hbase-metrics-regionserver.outt",
  "hbase.sink.file-regionserver.context": "regionservert",
  "hbase.sink.file-jvm.filename": "hbase-metrics-jvm.outt",
  "hbase.sink.file-jvm.context": "jvmt",
  "hbase.sink.file-ugi.filename": "hbase-metrics-ugi.outt",
  "hbase.sink.file-ugi.context": "ugit"
 } } }
```

According to the default "hadoop-metrics-hbase.properties", the list of
supported contexts are "hbase", "jvm" and "rpc".

    module.exports = ->
      [ganglia_ctx] =  @contexts 'ryba/ganglia/collector'
      hbase = @config.ryba.hbase
      hbase.metrics ?= {}
      hbase.metrics.sinks ?= {}
      hbase.metrics.sinks.file ?= true
      hbase.metrics.sinks.ganglia ?= false
      hbase.metrics.sinks.graphite ?= false
      hbase.metrics.config ?= {}
      hbase.metrics.config['*.period'] ?= '60'
      hbase.metrics.config['*.source.filter.class'] ?= 'org.apache.hadoop.metrics2.filter.GlobFilter'
      hbase.metrics.config['hbase.*.source.filter.exclude'] ?= '*Regions*|*Namespace*|*User*'
      hbase.metrics.config['hbase.extendedperiod'] ?= '3600'
      sinks = @config.metrics_sinks ?= {}
      sinks.ganglia ?= {}
      sinks.ganglia.class ?= 'org.apache.hadoop.metrics2.sink.ganglia.GangliaSink31'
      sinks.ganglia.period ?= '10'
      sinks.graphite ?= {}
      sinks.graphite.class ?= 'org.apache.hadoop.metrics2.sink.GraphiteSink'
      sinks.graphite.period ?= '10'
      # File sink
      if hbase.metrics.sinks.file
        hbase.metrics.config["*.sink.file.#{k}"] ?= v for k, v of sinks.file
        hbase.metrics.config['hbase.sink.file.filename'] ?= 'hbase-metrics.out'
      # Ganglia sink, accepted properties are "servers" and "supportsparse"
      if hbase.metrics.sinks.ganglia
        hbase.metrics.config["*.sink.ganglia.#{k}"] ?= v for k, v of sinks.ganglia
        hbase.metrics.config['hbase.sink.ganglia.class'] ?= sinks.ganglia.class
        hbase.metrics.config['jvm.sink.ganglia.class'] ?= sinks.ganglia.class
        hbase.metrics.config['rpm.sink.ganglia.class'] ?= sinks.ganglia.class
        hbase.metrics.config['hbase.sink.ganglia.servers'] ?= "#{ganglia_ctx.config.host}:#{ganglia_ctx.config.ryba.ganglia.nn_port}"
        hbase.metrics.config['jvm.sink.ganglia.servers'] ?= "#{ganglia_ctx.config.host}:#{ganglia_ctx.config.ryba.ganglia.nn_port}"
        hbase.metrics.config['rpc.sink.ganglia.servers'] ?= "#{ganglia_ctx.config.host}:#{ganglia_ctx.config.ryba.ganglia.nn_port}"
      # Graphite sink
      if hbase.metrics.sinks.graphite
        hbase.metrics.config['*.sink.graphite.metrics_prefix'] ?= if sinks.graphite.metrics_prefix? then "#{sinks.graphite.metrics_prefix}.hbase" else "hbase"
        hbase.metrics.config["*.sink.graphite.#{k}"] ?= v for k, v of sinks.graphite
        hbase.metrics.config['hbase.sink.graphite.class'] ?= sinks.graphite.class
        hbase.metrics.config['jvm.sink.graphite.class'] ?= sinks.graphite.class
        hbase.metrics.config['rpc.sink.graphite.class'] ?= sinks.graphite.class
