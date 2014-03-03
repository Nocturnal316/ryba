
lifecycle = require './lib/lifecycle'
module.exports = []

module.exports.push (ctx) ->
  require('./oozie_server').configure ctx

###
Start Oozie
-----
Execute these commands on the Oozie server host machine
###
module.exports.push name: 'HDP Oozie # Start', timeout: -1, callback: (ctx, next) ->
  return next() unless ctx.has_module 'phyla/hdp/oozie_server'
  lifecycle.oozie_start ctx, (err, started) ->
    next err, if started then ctx.OK else ctx.PASS

