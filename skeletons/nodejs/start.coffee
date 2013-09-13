express = require 'express'
MongoStore = require('connect-mongo')(express)
require 'express-namespace'
mongoose = require 'mongoose'
http = require 'http'
sysPath = require 'path'
io = require 'socket.io'
settings = require './config'

# Create express app
app = express()

# Configure the app
app.set 'port', process.env.PORT ? 4000

app.configure 'development', ->
  app.set 'db uri', 'mongodb://localhost/muffin_development'

app.configure 'test', ->
  app.set 'db uri', 'mongodb://localhost/muffin_test'

app.configure 'production', ->
  app.set 'db uri', process.env.MONGOLAB_URI

# Configure middleware
app.configure ->
  app.use express.favicon()
  app.use express.logger('dev')
  app.use express.compress()
  app.use express.static(sysPath.join(__dirname, './public'))
  app.use express.methodOverride()
  app.use express.bodyParser()
  app.use express.cookieParser()
  app.use express.session({secret: settings.cookie_secret, store: new MongoStore({url: app.get('db uri')})})
  app.use app.router

app.configure 'development', ->
  app.use express.errorHandler({dumpExceptions: true, showStack: true})

app.configure 'test', ->
  app.use express.errorHandler({dumpExceptions: true, showStack: true})

app.configure 'production', ->
  app.use express.errorHandler()

# Connect to MongoDB
mongoose.connect app.get('db uri')

# Create routers
app.namespace '/api/v1', ->
  require('./apps/main/router')(app)

# Start HTTP server
server = http.createServer(app)
server.listen app.get('port'), ->
  console.log "Server is running at http://localhost:#{app.get('port')} in #{app.settings.env} mode."
  console.log "Quit the server with CONTROL-C."

# Start Socket.IO server
socket = io.listen(server)
socket.on 'connection', (client) ->
  console.log 'Client connected'
