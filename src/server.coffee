#
# Muffin can start up three servers:
#
# 1. A socket server that provides live reload support
# 2. A dummy web server that serves client files in the build directory. This is useful when a server stack is not available or needed.
# 3. A real application server. This can be either a Node.js server or a Google App Engine development server.
#

http = require 'http'
send = require 'send'
url = require 'url'
WebSocketServer = require('ws').Server
chokidar = require 'chokidar'
logging = require './utils/logging'
project = require './project'


# Files to ignore
ignored = (file) ->
  /^\.|~$/.test(file) or /\.swp/.test(file) or file.match(project.buildDir)

# ## Live reload server

class LiveReloadServer

  constructor: (@port=9485) ->
    @connections = []

  start: ->
    server = new WebSocketServer {host: 'localhost', port: @port}
    server.on 'connection', (c) =>
      @connections.push c
      c.on 'close', =>
        i = @connections.indexOf(c)
        @connections[i..i] = []

  reloadBrowser: (path) ->
    if path
      switch sysPath.extname(path)
        when '.css'
          message = {reload: 'soft', type: 'css', path}
        when '.png', '.jpg', '.jpeg', '.gif', '.ico'
          message = {reload: 'soft', type: 'image', path}
        else
          message = {reload: 'hard'}
    else
      message = {reload: 'hard'}
    @sendMessageToClients(message)

  sendMessageToClients: (message) =>
    connected = _(@connections).filter (c) -> c.readyState is 1
    _(connected).each (c) -> c.send(JSON.stringify(message))


# ## Node.js application server

class NodeAppServer

  constructor: ->
    @restart = _.debounce(@start, 1000, true)

  startAndWatch: ->
    # Watch .coffee and .js files and restart the server when they change
    watcher = chokidar.watch project.serverDir, {ignored: ignored, persistent: true, ignoreInitial: true}
    @start()
    watcher.on 'add', (source) ->
      logging.info "added #{source}"
      @restart()
    watcher.on 'change', (source) ->
      logging.info "changed #{source}"
      @restart()
    watcher.on 'unlink', (source) ->
      logging.info "removed #{source}"
      @restart()
    watcher.on 'error', (error) ->
      logging.error "Error occurred while watching files: #{error}"

  start: ->
    child = exports.child
    if child
      child.shouldRestart = true
      child.kill()
      logging.info 'Restarting the application server...'
    else
      # Start the server in a child process
      child = exports.child = spawn 'node', ['server/server.js'],
        cwd: process.cwd()
      child.shouldRestart = false

      child.stdout.on 'data', (data) ->
        console.log data.toString()
        reloadBrowser() if /Quit the server with CONTROL-C/.test(data.toString())

      child.stderr.on 'data', (data) ->
        if data.toString().length > 1
          logging.error data

      child.on 'exit', (code) ->
        exports.child = null
        if child.shouldRestart
          # Restart the server when files change
          process.nextTick(@start)

      child.on 'uncaughtException', (err) ->
        logging.error err.message

      # Pass kill signals through to child
      for signal in ['SIGTERM', 'SIGINT', 'SIGHUP', 'SIGQUIT']
        process.on signal, ->
          child.kill(signal)
          process.exit 1


# ## Google App Engine dev server

class GAEAppServer

  start: ->
    spawn 'dev_appserver.py', ['server']


# ## Public interface

liveReloadServer = null

startLiveReloadServer = ->
  liveReloadServer = new LiveReloadServer(project.clientConfig.liveReload?.port)
  liveReloadServer.start()

reloadBrowser = (path) ->
  liveReloadServer?.reloadBrowser(path)

startDummyWebServer = ->
  app = http.createServer (req, res) ->
    send(req, url.parse(req.url).pathname)
    .root(buildDir)
    .pipe(res)
  port = 4000
  app.listen port, ->
    console.log "Server is running at http://localhost:#{port}."
    console.log "Quit the server with CONTROL-C."

startAppServer = ->
  switch project.config.serverType
    when 'nodejs'
      server = new NodeAppServer()
      server.startAndWatch()
    when 'gae'
      server = new GAEAppServer()
      server.start()

module.exports = {startLiveReloadServer, reloadBrowser, startDummyWebServer, startAppServer}
