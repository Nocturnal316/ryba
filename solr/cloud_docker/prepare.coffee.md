  
# Solr Cloud Docker Prepare
Build container and save it.
  
    module.exports = 
      header: 'Solr Cloud Docker Prepare'
      timeout: -1
      if: -> @contexts('ryba/solr/cloud_docker')[0]?.config.host is @config.host
      handler: ->
        {solr} = @config.ryba
        @mkdir
          target: solr.cloud_docker.build.dir
        @mkdir
          target: "#{solr.cloud_docker.build.dir}/build"
        @render
          source: "#{__dirname}/../resources/cloud_docker/Dockerfile"
          target: "#{solr.cloud_docker.build.dir}/build/Dockerfile"
          context: @config
        @docker_build
          image: "#{solr.cloud_docker.build.image}:#{solr.cloud_docker.build.version}"
          file: "#{solr.cloud_docker.build.dir}/build/Dockerfile"
        @docker_save
          image: "#{solr.cloud_docker.build.image}:#{solr.cloud_docker.build.version}"
          output: "#{solr.cloud_docker.build.dir}/#{solr.cloud_docker.build.tar}"
        