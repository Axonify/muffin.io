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

try config = require sysPath.join(process.cwd(), 'config')
try buildConfig = require sysPath.join(process.cwd(), 'client/config/config')

# Parse build config
shim = {}
parseBuildConfig = ->
  mapping = buildConfig.paths
  for name, value of buildConfig.shim
    path = mapping[name] ? name
    deps = ((mapping[dep] ? dep) for dep in value.deps)
    shim[path] = {deps}
parseBuildConfig() if buildConfig?

# Underscore template settings
_.templateSettings =
  evaluate    : /<\?([\s\S]+?)\?>/g,
  interpolate : /<\?=([\s\S]+?)\?>/g,
  escape      : /<\?-([\s\S]+?)\?>/g

# Directory conventions
cwd = process.cwd()
clientDir = sysPath.join(cwd, 'client')
clientAssetsDir = sysPath.join(cwd, 'client/assets')
clientVendorDir = sysPath.join(cwd, 'client/vendor')
publicDir = sysPath.join(cwd, 'public')
jsDir = sysPath.join(cwd, 'public/javascripts')
serverDir = sysPath.join(cwd, 'server')

# Variables
connections = []

# Update settings
settings = {}
assetHost = ''
setEnv = (env) ->
  settings = {env}
  for key, value of config?.clientSettings
    if key in ['development', 'production', 'test']
      if key is env
        _.extend settings, value
    else
      settings[key] = value
  assetHost = settings.assetHost ? ''

setCDN = (s) ->
  assetHost = s

# Helpers
cacheBuster = (force) ->
  if settings.cacheBuster or force
    "?_#{(new Date()).getTime()}"
  else
    ''

htmlHelpers =
  link_tag: (link, attrs={}) ->
    "<link href='#{assetHost}#{link}#{cacheBuster(attrs.forceCacheBuster)}' #{("#{k}='#{v}'" for k, v of attrs).join(' ')}>"
  stylesheet_link_tag: (link, attrs={}) ->
    "<link rel='stylesheet' type='text/css' href='#{assetHost}#{link}#{cacheBuster(attrs.forceCacheBuster)}' #{("#{k}='#{v}'" for k, v of attrs).join(' ')}>"
  script_tag: (src, attrs={}) ->
    "<script src='#{assetHost}#{src}#{cacheBuster(attrs.forceCacheBuster)}' #{("#{k}='#{v}'" for k, v of attrs).join(' ')}></script>"
  image_tag: (src, attrs={}) ->
    "<img src='#{assetHost}#{src}#{cacheBuster(attrs.forceCacheBuster)}' #{("#{k}='#{v}'" for k, v of attrs).join(' ')}>"
  inline_script: (src) ->
    "<?= _inline_script('#{src}') ?>"
  _inline_script: (src) ->
    "<script>" + fs.readFileSync(sysPath.join(publicDir, src)).toString() + "</script>"

jadeHelpers =
  link_tag: (link, attrs={}) ->
    "link(href='#{assetHost}#{link}#{cacheBuster(attrs.forceCacheBuster)}', #{("#{k}='#{v}'" for k, v of attrs).join(',')})"
  stylesheet_link_tag: (link, attrs={}) ->
    "link(rel='stylesheet', type='text/css', href='#{assetHost}#{link}#{cacheBuster(attrs.forceCacheBuster)}', #{("#{k}='#{v}'" for k, v of attrs).join(',')})"
  script_tag: (src, attrs={}) ->
    "script(src='#{assetHost}#{src}#{cacheBuster(attrs.forceCacheBuster)}', #{("#{k}='#{v}'" for k, v of attrs).join(',')})"
  image_tag: (src, attrs={}) ->
    "img(src='#{assetHost}#{src}#{cacheBuster(attrs.forceCacheBuster)}', #{("#{k}='#{v}'" for k, v of attrs).join(',')})"
  inline_script: (src) ->
    "<?= _inline_script('#{src}') ?>"

injectLiveReloadJS = (data) ->
  # Inject livereload.js
  if settings.liveReload
    i = data.indexOf('</head>')
    if i isnt -1
      data = data[0...i] + "<script src='#{settings.liveReload.src}'></script>\n" + data[i..]
  return data

# Files to ignore
ignored = (file) ->
  /^\.|~$/.test(file) or /\.swp/.test(file)

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

getNetworkIP = ->
  ips = []
  interfaces = os.networkInterfaces()
  for en, addrs of interfaces
    for addr in addrs
      if addr.family is 'IPv4' and not addr.internal
        ips.push(addr.address)
  ips[0]

startLiveReloadServer = ->
  connections = []
  port = settings.liveReload?.port ? 9485
  host = getNetworkIP()
  server = new WebSocketServer {host: "#{host}", port}
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
  inVendorDir = !!~ source.indexOf clientVendorDir
  
  if inAssetsDir
    relativePath = sysPath.relative(clientAssetsDir, source)
    dest = sysPath.join(publicDir, relativePath)
  else if inVendorDir
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
          
          if sourceData.split('\n')[0].match('NO_AMD_PREFIX')
            js = CoffeeScript.compile(sourceData)
            fs.writeFileSync path, js
            logging.info "compiled #{source}"
            reload(path)
          else
            # Wrap the file into AMD module format
            js = CoffeeScript.compile(sourceData, {bare: true})
            modulePath = sysPath.relative(publicDir, path)[...-3]
            deps = parseDeps(js)
            js = "define('#{modulePath}', #{JSON.stringify(deps)}, function(require, exports, module) {#{js}});"
            fs.writeFileSync path, js
            logging.info "compiled #{source}"
            reload(path)
        
        when '.jade'
          # Run the source file through template engine
          sourceData = _.template(fs.readFileSync(source).toString(), _.extend({}, {settings}, jadeHelpers))
          filename = sysPath.basename(source, sysPath.extname(source)) + '.html'
          path = sysPath.join destDir, filename
          
          fn = jade.compile sourceData, { filename: source, compileDebug: false, pretty: true }
          html = fn()
          html = injectLiveReloadJS(html)
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
          sourceData = injectLiveReloadJS(sourceData)
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
          
          modulePath = sysPath.relative(publicDir, path)
          deps = shim[modulePath]?.deps ? []
          if deps.length > 0
            # Only wrap if dependencies are set in shim
            js = "define('#{modulePath}', #{JSON.stringify(deps)}, function() {#{js}});"
          
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

# Inline scripts
inlineScriptsInDir = (source) ->
  fs.stat source, (err, stats) ->
    throw err if err and err.code isnt 'ENOENT'
    return if err?.code is 'ENOENT'
    if stats.isDirectory()
      fs.readdir source, (err, files) ->
        throw err if err and err.code isnt 'ENOENT'
        return if err?.code is 'ENOENT'
        files = files.filter (file) -> not ignored(file)
        inlineScriptsInDir sysPath.join(source, file) for file in files
    else if stats.isFile() and sysPath.extname(source) is '.html'
      # Run the source file through template engine once more to inline the scripts
      sourceData = _.template(fs.readFileSync(source).toString(), htmlHelpers)
      fs.writeFileSync source, sourceData

# Start the server
startAndWatchServer = ->
  # Watch .coffee and .js files and restart the server when they change
  watcher = chokidar.watch serverDir, {ignored: ignored, persistent: true, ignoreInitial: true}
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
    .replace(cjsRequireRegex, (match, dep) -> deps.push(dep))
  deps

module.exports = {setEnv, setCDN, compileDir, watchDir, startAndWatchServer, inlineScriptsInDir}