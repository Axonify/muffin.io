#
# watch.coffee
#

fs = require 'fs-extra'
sysPath = require 'path'
os = require 'os'
{spawn} = require 'child_process'
_ = require 'underscore'
logging = require './logging'
chokidar = require 'chokidar'
CoffeeScript = require 'coffee-script'
jade = require 'jade'
less = require 'less'
WebSocketServer = require('ws').Server
md5 = require 'MD5'

# Underscore template settings
_.templateSettings =
  evaluate    : /<\?([\s\S]+?)\?>/g,
  interpolate : /<\?=([\s\S]+?)\?>/g,
  escape      : /<\?-([\s\S]+?)\?>/g

# Load config
try config = require sysPath.resolve('client/config')

# Directories
clientDir = sysPath.resolve('client')
clientAssetsDir = sysPath.join(clientDir, 'assets')
clientComponentsDir = sysPath.join(clientDir, 'components')

if config?
  publicDir = sysPath.resolve('client', config.build.buildDir)
else
  publicDir = sysPath.resolve('public')

jsDir = sysPath.join(publicDir, 'javascripts')
serverDir = sysPath.resolve('server')

# Client settings
settings = {}

setEnv = (env, opts) ->
  settings = {env}
  for key, value of config
    if key in ['development', 'production', 'test']
      if key is env
        _.extend settings, value
    else
      settings[key] = value
  settings.assetHost = opts.cdn ? ''
  settings.version = opts.hash ? '1.0.0'

isDirectory = (path) ->
  stats = fs.statSync(path)
  stats.isDirectory()

# Build path aliases and package dependencies
aliases = {}
packageDeps = {}

buildAliases = ->
  aliases = config.build.aliases if config?

  # iterate over the components dir and get module deps
  users = fs.readdirSync(clientComponentsDir)
  for user in users
    userDir = sysPath.join(clientComponentsDir, user)
    if isDirectory(userDir)
      repos = fs.readdirSync(userDir)
      for repo in repos
        repoDir = sysPath.join(userDir, repo)
        if isDirectory(repoDir)
          aliases[repo] = aliases["#{user}/#{repo}"] = "components/#{user}/#{repo}/index"

          # extract package deps from component.json
          json = fs.readFileSync(sysPath.join(repoDir, 'component.json'))
          json = JSON.parse(json)
          if json.dependencies
            packageDeps["#{user}/#{repo}"] = Object.keys(json.dependencies)
  return aliases

# Helpers
cacheBuster = (force) ->
  if settings.cacheBuster or force
    "?_#{(new Date()).getTime()}"
  else
    ''

# Module loader source
moduleLoaderSrc = fs.readFileSync(sysPath.join(__dirname, '../src-client/module_loader.coffee')).toString()
moduleLoaderSrc = _.template(moduleLoaderSrc, {settings})
moduleLoaderSrc = CoffeeScript.compile(moduleLoaderSrc)

liveReloadSrc = fs.readFileSync(sysPath.join(__dirname, '../src-client/live_reload.coffee')).toString()
liveReloadSrc = _.template(liveReloadSrc, {settings})
liveReloadSrc = CoffeeScript.compile(liveReloadSrc)

htmlHelpers =
  link_tag: (link, attrs={}) ->
    "<link href='#{settings.assetHost}#{link}#{cacheBuster(attrs.forceCacheBuster)}' #{("#{k}='#{v}'" for k, v of attrs).join(' ')}>"
  stylesheet_link_tag: (link, attrs={}) ->
    "<link rel='stylesheet' type='text/css' href='#{settings.assetHost}#{link}#{cacheBuster(attrs.forceCacheBuster)}' #{("#{k}='#{v}'" for k, v of attrs).join(' ')}>"
  script_tag: (src, attrs={}) ->
    "<script src='#{settings.assetHost}#{src}#{cacheBuster(attrs.forceCacheBuster)}' #{("#{k}='#{v}'" for k, v of attrs).join(' ')}></script>"
  image_tag: (src, attrs={}) ->
    "<img src='#{settings.assetHost}#{src}#{cacheBuster(attrs.forceCacheBuster)}' #{("#{k}='#{v}'" for k, v of attrs).join(' ')}>"
  include_module_loader: ->
    """
    <script>#{moduleLoaderSrc}</script>
    <script>require.aliases(#{JSON.stringify(aliases)})</script>
    <script>#{liveReloadSrc}</script>
    """

# Files to ignore
ignored = (file) ->
  /^\.|~$/.test(file) or /\.swp/.test(file)

serverIgnored = (file) ->
  /^\.|~$/.test(file) or /\.swp/.test(file) or file.match(publicDir)

# Set up live reload
connections = []
startLiveReloadServer = ->
  connections = []
  port = settings.liveReload?.port ? 9485
  server = new WebSocketServer {host: 'localhost', port}
  server.on 'connection', (connection) =>
    connections.push connection
    connection.on 'close', ->
      i = connections.indexOf(connection)
      connections[i..i] = []

sendMessageToClients = (message) ->
  cons = _(connections).filter (connection) -> connection.readyState is 1
  _(cons).each (connection) -> connection.send(JSON.stringify(message))

reload = (path) ->
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
  sendMessageToClients(message)

# Watch a directory
watchDir = (dir) ->
  watcher = chokidar.watch dir, {ignored: ignored, persistent: true, ignoreInitial: true}
  watcher.on 'add', compileFile
  watcher.on 'change', compileFile
  watcher.on 'unlink', removeFile
  watcher.on 'error', (error) ->
    logging.error "Error occurred while watching files: #{error}"

  # Live reload
  startLiveReloadServer()

# Recursively compile all files in a directory and its subdirectories
compileDir = (source) ->
  fs.stat source, (err, stats) ->
    throw err if err and err.code isnt 'ENOENT'
    return if err?.code is 'ENOENT'
    if stats.isDirectory()
      fs.readdir source, (err, files) ->
        throw err if err and err.code isnt 'ENOENT'
        return if err?.code is 'ENOENT'
        files = files.filter (file) -> not ignored(file)
        compileDir sysPath.join(source, file) for file in files
    else if stats.isFile()
      compileFile source, yes

destDirForFile = (source) ->
  inAssetsDir = !!~ source.indexOf clientAssetsDir
  inComponentsDir = !!~ source.indexOf clientComponentsDir

  if inAssetsDir
    relativePath = sysPath.relative(clientAssetsDir, source)
    dest = sysPath.join(publicDir, relativePath)
  else if inComponentsDir
    relativePath = sysPath.relative(clientDir, source)
    dest = sysPath.join(publicDir, relativePath)
  else
    relativePath = sysPath.relative(clientDir, source)
    dest = sysPath.join(jsDir, relativePath)
  return sysPath.dirname(dest)

destForFile = (source) ->
  destDir = destDirForFile(source)
  switch sysPath.extname(source)
    when '.coffee'
      filename = sysPath.basename(source, sysPath.extname(source)) + '.js'
    when '.jade'
      filename = sysPath.basename(source, sysPath.extname(source)) + '.html'
    else
      filename = sysPath.basename(source)
  return sysPath.join(destDir, filename)

# Compile a single file
compileFile = (source, abortOnError=no) ->
  destDir = destDirForFile(source)
  fs.exists destDir, (exists) ->
    fs.mkdirSync destDir unless exists
    _compile()

  _compile = ->
    try
      switch sysPath.extname(source)
        when '.coffee'
          # Run the source file through template engine
          sourceData = _.template(fs.readFileSync(source).toString(), {settings})
          filename = sysPath.basename(source, sysPath.extname(source)) + '.js'
          path = sysPath.join destDir, filename

          # Wrap the file into AMD module format
          js = CoffeeScript.compile(sourceData, {bare: true})
          modulePath = sysPath.relative(publicDir, path)[...-3]
          deps = parseDeps(js)

          # Concat package deps
          match = modulePath.match(/^components\/(.*)\/(.*)\//)
          if match
            extraDeps = packageDeps["#{match[1]}/#{match[2]}"]
            if extraDeps?.length > 0
              deps = deps.concat(extraDeps)

          js = "define('#{modulePath}', #{JSON.stringify(deps)}, function(require, exports, module) {#{js}});"
          fs.writeFileSync path, js
          logging.info "compiled #{source}"
          reload(path)

        when '.jade'
          # Compile Jade into html
          sourceData = fs.readFileSync(source).toString()
          filename = sysPath.basename(source, sysPath.extname(source)) + '.html'
          path = sysPath.join destDir, filename
          fn = jade.compile sourceData, {filename: source, compileDebug: false, pretty: true}
          html = fn()

          # Run through the template engine and write to the output file
          html = _.template(html, _.extend({}, {settings}, htmlHelpers))
          fs.writeFileSync path, html
          logging.info "compiled #{source}"
          reload(path)

        when '.less'
          # Run the source file through template engine
          sourceData = _.template(fs.readFileSync(source).toString(), {settings})
          filename = sysPath.basename(source, sysPath.extname(source)) + '.css'
          path = sysPath.join destDir, filename

          less.render sourceData, (err, data) ->
            fs.writeFileSync path, data
            logging.info "compiled #{source}"
            reload(path)

        when '.html', '.htm', '.css'
          # Run the source file through template engine
          sourceData = _.template(fs.readFileSync(source).toString(), _.extend({}, {settings}, htmlHelpers))
          filename = sysPath.basename(source)
          path = sysPath.join destDir, filename
          fs.writeFileSync path, sourceData
          logging.info "copied #{source}"
          reload(path)

        when '.appcache'
          sourceData = _.template(fs.readFileSync(source).toString(), {settings})
          filename = sysPath.basename(source)
          path = sysPath.join destDir, filename
          fs.writeFileSync path, sourceData
          logging.info "copied #{source}"

        when '.js'
          js = fs.readFileSync(source).toString()
          filename = sysPath.basename(source)
          path = sysPath.join destDir, filename

          modulePath = sysPath.relative(publicDir, path)[...-3]
          deps = parseDeps(js)

          # Concat package deps
          match = modulePath.match(/^components\/(.*)\/(.*)\//)
          if match
            extraDeps = packageDeps["#{match[1]}/#{match[2]}"]
            if extraDeps?.length > 0
              deps = deps.concat(extraDeps)

          js = "define('#{modulePath}', #{JSON.stringify(deps)}, function(require, exports, module) {#{js}});"
          fs.writeFileSync path, js
          logging.info "copied #{source}"
          reload(path)

        else
          filename = sysPath.basename(source)
          path = sysPath.join destDir, filename

          fs.copy source, path, (err) ->
            logging.info "copied #{source}"
            reload(path)
    catch err
      if abortOnError
        fatalError err.message
      else
        logging.error "#{err.message} (#{source})"

# Remove a file
removeFile = (source) ->
  dest = destForFile(source)
  fs.stat dest, (err, stats) ->
    return if err
    if stats.isDirectory()
      fs.rmdir dest, (err) ->
        return if err
        logging.info "removed #{source}"
    else if stats.isFile()
      fs.unlink dest, (err) ->
        return if err
        logging.info "removed #{source}"

# Start the server
startAndWatchServer = ->
  # Watch .coffee and .js files and restart the server when they change
  watcher = chokidar.watch serverDir, {ignored: serverIgnored, persistent: true, ignoreInitial: true}
  startServer()
  watcher.on 'add', (source) ->
    logging.info "added #{source}"
    restartServer()
  watcher.on 'change', (source) ->
    logging.info "changed #{source}"
    restartServer()
  watcher.on 'unlink', (source) ->
    logging.info "removed #{source}"
    restartServer()
  watcher.on 'error', (error) ->
    logging.error "Error occurred while watching files: #{error}"

startServer = ->
  child = exports.child
  if child
    child.shouldRestart = true
    child.kill()
    logging.info "Restarting the application server..."
  else
    # Start the server in a child process
    child = exports.child = spawn "node", ["server/server.js"],
      cwd: process.cwd()
    child.shouldRestart = false

    child.stdout.on 'data', (data) ->
      console.log data.toString()
      reload() if /Quit the server with CONTROL-C/.test(data.toString())

    child.stderr.on 'data', (data) ->
      if data.toString().length > 1
        logging.error data

    child.on 'exit', (code) ->
      exports.child = null
      if child.shouldRestart
        # Restart the server when files change
        process.nextTick(startServer)

    child.on 'uncaughtException', (err) ->
      logging.error err.message

    # Pass kill signals through to child
    for signal in ['SIGTERM', 'SIGINT', 'SIGHUP', 'SIGQUIT']
      process.on signal, ->
        child.kill(signal)
        process.exit 1

restartServer = _.debounce startServer, 1000, true

# Print an error and exit.
fatalError = (message) ->
  logging.error message + '\n'
  process.exit 1

parseDeps = (content) ->
  commentRegex = /(\/\*([\s\S]*?)\*\/|([^:]|^)\/\/(.*)$)/mg
  cjsRequireRegex = /[^.]\s*require\s*\(\s*["']([^'"\s]+)["']\s*\)/g
  deps = []

  # Find all the require calls and push them into dependencies.
  content
    .replace(commentRegex, '') # remove comments
    .replace(cjsRequireRegex, (match, dep) -> deps.push(dep) if dep not in deps)
  deps

module.exports = {setEnv, buildAliases, compileDir, watchDir, startAndWatchServer}
