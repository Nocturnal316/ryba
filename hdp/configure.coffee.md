
# HDP Repository Configure

    module.exports = ->
      options = @config.ryba.hdp ?= {}
      options.source ?= null
      options.target ?= 'hdp.repo'
      options.target = path.resolve '/etc/yum.repos.d', options.target
      options.replace ?= 'hdp*'

## Dependencies

    path = require('path').posix
