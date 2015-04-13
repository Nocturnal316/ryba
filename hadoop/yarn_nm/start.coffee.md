
# YARN NodeManager Start

    lifecycle = require '../../lib/lifecycle'
    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'ryba/hadoop/yarn_rm/wait'
    module.exports.push require('./index').configure

    module.exports.push name: 'Hadoop NodeManager # Start Server', label_true: 'STARTED', handler: (ctx, next) ->
      lifecycle.nm_start ctx, next