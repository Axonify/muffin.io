# Create dummy console functions if they don't exist in browser
window.console ?= {}
methods = [
  'assert', 'count', 'debug', 'dir', 'dirxml', 'error', 'exception', 'group'
  'groupCollapsed', 'groupEnd', 'info', 'log', 'markTimeline', 'profile', 'profileEnd'
  'time', 'timeEnd', 'trace', 'warn'
]
(console[method] ?= ->) for method in methods

# Logger class
class Logger
  
  levels:
    TRACE:  {value: 0, name: 'TRACE'}
    DEBUG:  {value: 1, name: 'DEBUG'}
    INFO:   {value: 2, name: 'INFO'}
    WARN:   {value: 3, name: 'WARN'}
    ERROR:  {value: 4, name: 'ERROR'}
    FATAL:  {value: 5, name: 'FATAL'}
  
  consoleWriter:
    write: (msg) ->
      console.log(msg)
      
      # Save to log history
      logMaxEntries = <?- settings.logMaxEntries ?> ? 20
      @history ?= []
      @history.unshift msg
      @history.pop() while @history.length > logMaxEntries
  
  localStorageWriter:
    write: (msg) ->
      logMaxEntries = <?- settings.logMaxEntries ?> ? 20
      s = localStorage['app:log']
      s = if s then JSON.parse(s) else []
      s.unshift msg
      s.pop() while s.length > logMaxEntries
      try localStorage['app:log'] = JSON.stringify(s)
  
  simpleFormatter:
    format: (msg, datetime, level) ->
      "#{datetime.toString()} [#{level.name}]: #{msg}"
  
  JSONFormatter:
    format: (msg, datetime, level) ->
      JSON.stringify {msg, datetime, level}
  
  clear: -> @history = []
  
  log: (level, msg) =>
    logLevel = @levels['<?- settings.logLevel ?>' ? 'ERROR']
    logWriter = @['<?- settings.logWriter ?>' ? 'consoleWriter']
    logFormatter = @['<?- settings.logFormatter ?>' ? 'simpleFormatter']
    datetime = new Date
    
    if level.value >= logLevel.value
      logWriter.write logFormatter.format(msg, datetime, level)
  
  info: (msg) ->
    @log @levels.INFO, msg
  
  debug: (msg) ->
    @log @levels.DEBUG, msg
  
  warn: (msg) ->
    @log @levels.WARN, msg
  
  error: (msg) ->
    @log @levels.ERROR, msg

module.exports = Logger