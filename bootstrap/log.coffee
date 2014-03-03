
fs = require 'fs'
pad = require 'pad'
mecano = require 'mecano'

module.exports = []

###
Log
----
Gather system information
###
module.exports.push name: 'Bootstrap # Log', callback: (ctx, next) ->
  mecano.mkdir
    destination: './logs'
  , (err, created) ->
    return next err if err
    host = ctx.config.host.split('.').reverse().join('.')
    # Add log interface
    ctx.log = log = (msg) ->
      log.out.write "#{msg}\n"
    log.out = fs.createWriteStream "./logs/#{host}_out.log"
    log.err = fs.createWriteStream "./logs/#{host}_err.log"
    close = ->
      setTimeout ->
        log.out.close()
        log.err.close()
      , 100
    ctx.on 'action', (status) ->
      return unless status is ctx.STARTED
      date = (new Date).toISOString()
      msg = "\n#{date} #{ctx.action.name}\n#{pad date.length+ctx.action.name.length, '', '-'}\n"
      log.out.write msg
      log.err.write msg
    ctx.on 'end', ->
      log.out.write 'FINISHED WITH SUCCESS\n'
      close()
    ctx.on 'error', (err) ->
      print = (err) ->
        log.out.write 'FINISHED WITH ERROR\n'
        log.err.write err.message + '\n'
        log.err.write err.stack if err.stack
      print err
      if err.errors
        for error in err.errors then print error
      close()
    next null, ctx.PASS