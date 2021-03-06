# Muffin may run three different servers:
#
# 1. A web socket server for live reload
# 2. A dummy web server that serves client files from the build directory.
# This is useful when using Muffin as a static site generator, or when a server
# stack is not available.
# 3. A real Node.js or Google App Engine app server.

sysPath = require 'path'
url = require 'url'
http = require 'http'
net = require 'net'
async = require 'async'
{spawn} = require 'child_process'
_ = require 'underscore'
send = require 'send'
WebSocketServer = require('ws').Server
chokidar = require 'chokidar'
logging = require './utils/logging'
project = require './project'

# Files to ignore
ignored = (file) ->
  filename = sysPath.basename(file)
  /^\.|~$/.test(filename) or /\.swp/.test(filename) or file.match(project.buildDir) or file.match('node_modules')

# The `LiveReloadServer` sets up a web socket server to communicate with the browser.
class LiveReloadServer

  constructor: (@port=9485) ->
    @connections = []

  start: ->
    server = new WebSocketServer {port: @port}
    server.on 'connection', (c) =>
      @connections.push c
      c.on 'close', =>
        # Remove the connection on close.
        i = @connections.indexOf(c)
        @connections.splice(i, 1)

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


# The Node.js app server
class NodeAppServer

  constructor: (options) ->
    @port = options.port ? 4000

  startAndWatch: ->
    # Start the server
    @start()

    # Watch server files and restart the server when they change.
    # Have to turn on 'polling' because FSWatcher has a lot of issues.
    # Set polling interval to 200ms to reduce CPU usage.
    watcher = chokidar.watch project.serverDir,
      {ignored: ignored, persistent: true, ignoreInitial: true, usePolling: true, interval: 200}
    watcher.on 'add', (path) =>
      logging.info "added #{path}"
      @start()
    watcher.on 'change', (path) =>
      logging.info "changed #{path}"
      @start()
    watcher.on 'unlink', (path) =>
      logging.info "removed #{path}"
      @start()
    watcher.on 'error', (error) ->
      logging.error "Error occurred while watching files: #{error}"

  start: =>
    child = exports.child
    if child
      child.shouldRestart = true
      child.kill()
      logging.info 'Restarting the application server...'
    else
      # Start the server in a child process
      env = _.extend(process.env, {PORT: @port})
      child = exports.child = spawn 'node', ['server/server.js'], {stdio: 'inherit', env}
      child.shouldRestart = false

      child.on 'exit', (code) =>
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


# The Google App Engine development server
class GAEAppServer

  constructor: (options) ->
    @port = options.port ? 4000

  start: ->
    console.log 'Starting Google App Engine development server...'
    spawn 'dev_appserver.py', ["--port=#{@port}", project.serverDir], {stdio: 'inherit'}


# Public interface
# ----------------

liveReloadServer = null

startLiveReloadServer = ->
  liveReloadServer = new LiveReloadServer(project.liveReloadPort)
  liveReloadServer.start()

# Test if the live reload port is in use, and increment it as needed.
testLiveReloadPort = (callback) ->
  port = 9485
  portIsAvailable = false

  test = -> portIsAvailable

  fn = (done) ->
    server = net.createServer()
    server.on 'listening', ->
      portIsAvailable = true
      project.liveReloadPort = port
      server.on 'close', done
      server.close()
    .on 'error', (err) ->
      if err.code is 'EADDRINUSE'
        port += 1
        done(null)
    .listen(port)

  async.until test, fn, callback

reloadBrowser = (path) ->
  liveReloadServer?.reloadBrowser(path)

startDummyWebServer = (options) ->
  console.log 'Starting a dummy web server for the static files...'
  app = http.createServer (req, res) ->
    send(req, url.parse(req.url).pathname)
    .root(project.buildDir)
    .pipe(res)
  port = options.port ? 4000
  app.listen port, ->
    console.log "Server is running at http://localhost:#{port}."
    console.log "Quit the server with CONTROL-C."

startAppServer = (options) ->
  switch project.config.serverType
    when 'nodejs'
      server = new NodeAppServer(options)
      server.startAndWatch()
    when 'gae'
      server = new GAEAppServer(options)
      server.start()

module.exports = {startLiveReloadServer, testLiveReloadPort, reloadBrowser, startDummyWebServer, startAppServer}
