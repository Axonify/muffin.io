# The `Logger` class supports multiple log levels, ASCII color and
# growl notifications.

sysPath = require 'path'
color = require 'ansi-color'
growl = require 'growl'

# Color map for log levels
colors =
  ERROR: 'red'
  WARN: 'yellow'
  INFO: 'green'
  DEBUG: 'blue'

class Logger

  # `logging.fatal` calls `logging.error`, then kills the process.
  fatal: (msg) ->
    @error(msg)
    process.exit 1

  # `logging.error` prints the error message in red, and displays a growl notification.
  error: (msg) ->
    @log 'ERROR', msg
    growl msg, {title: 'muffin error', image: sysPath.join(__dirname, '../muffin.png')}

  warn: (msg) ->
    @log 'WARN', msg

  info: (msg) ->
    @log 'INFO', msg

  debug: (msg) ->
    @log 'DEBUG', msg

  log: (level, msg) =>
    # Prepend timestamp and log level to the log message.
    if level in ['ERROR', 'WARN']
      info = color.set "#{(new Date).toLocaleTimeString()} [#{level}]: #{msg}", colors[level]
      console.error info
    else
      prefix = color.set "#{(new Date).toLocaleTimeString()} [#{level}]", colors[level]
      info = "#{prefix}: #{msg}"
      console.log info

# Freeze the Logger object so it can't be modified later.
module.exports = Object.freeze(new Logger())
