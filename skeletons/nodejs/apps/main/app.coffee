express = require 'express'
require 'express-namespace'
mongoose = require 'mongoose'
http = require 'http'
path = require 'path'
io = require 'socket.io'

app = express()

# Config
app.configure ->
  app.set 'port', process.env.PORT ? 3000
  app.use express.favicon()
  app.use express.logger('dev')
  app.use express.bodyParser()
  app.use express.methodOverride()
  app.use(express.cookieParser('your secret here'));
  app.use(express.session());
  app.use app.router
  app.use express.static(path.join(__dirname, '../../../public'))

app.configure 'development', ->
  app.use express.errorHandler({ dumpExceptions: true, showStack: true })
  mongoose.connect 'mongodb://localhost/muffin_development'

app.configure 'test', ->
  app.use express.errorHandler({ dumpExceptions: true, showStack: true })
  mongoose.connect 'mongodb://localhost/muffin_test'

app.configure 'production', ->
  app.use express.errorHandler()
  mongoose.connect 'mongodb://localhost/muffin_production'

app.namespace '/api/v1', ->
  router = require('./router')(app)

server = http.createServer(app)
server.listen app.get('port'), ->
  console.log "Server is running at http://localhost:#{app.get('port')} in #{app.settings.env} mode."
  console.log "Quit the server with CONTROL-C."

# Set up socket.IO server
socket = io.listen(server)
socket.on 'connection', (client) ->
  console.log 'Client connected'
