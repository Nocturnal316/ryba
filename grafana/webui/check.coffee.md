
# Grafana WEBUi Check
Check that the webui is listening for connections.

    module.exports = header: 'Grafana WEBUi Check', handler: (options) ->
      
        @connection.assert
          header: 'Port'
          servers: options.wait.http.filter (server) -> server.host is options.fqdn
                
        