
# JanusGraph

[JanusGraph][website] is a scalable graph database optimized for storing and 
querying graphs containing hundreds of billions of vertices and edges distributed
across a  multi-machine cluster. JanusGraph is a transactional database that can
support thousands of concurrent users executing complex graph traversals in real time.
JanusGraph is a project under The Linux Foundation, and includes participants
from Expero, Google, GRAKN.AI, Hortonworks, and IBM. 

    module.exports =
      use:
        hbase: implicit: true, module: 'ryba/hbase/client'
        java: implicit: true, module: 'masson/commons/java'
        zk: 'ryba/zookeeper/server'
        elasticsearch: 'ryba/elasticsearch'
        solr: 'ryba/solr'
      configure:
        'ryba/janusgraph/configure'
      commands:
        'prepare':
          'ryba/janusgraph/prepare'
        'install': [
          'ryba/janusgraph/install'
          'ryba/janusgraph/check'
        ]
        'check':
          'ryba/janusgraph/check'

## Resources

*   [JanusGraph: Documentation](http://docs.janusgraph.org/0.1.1/)
*   [TinkerPop](http://www.tinkerpop.com/)

[website]: http://janusgraph.org/
