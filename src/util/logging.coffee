color = require 'ansi-color'
growl = require 'growl'
path = require 'path'

colors =
  ERROR: 'red'
  WARN: 'yellow'
  INFO: 'green'
  DEBUG: 'blue'

class Logger

  error: (msg) ->
    growl msg, {title: 'muffin error', image: path.join(__dirname, '../muffin.png')}
    @log 'ERROR', msg

  warn: (msg) ->
    @log 'WARN', msg

  info: (msg) ->
    @log 'INFO', msg

  debug: (msg) ->
    @log 'DEBUG', msg

  log: (level, msg) =>
    if level is 'ERROR' or level is 'WARN'
      info = color.set "#{(new Date).toLocaleTimeString()} [#{level}]: #{msg}", colors[level]
      console.error info
    else
      prefix = color.set "#{(new Date).toLocaleTimeString()} [#{level}]", colors[level]
      info = "#{prefix}: #{msg}"
      console.log info

module.exports = Object.freeze(new Logger())
