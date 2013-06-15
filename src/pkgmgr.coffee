#
# pkgmgr.coffee
#

fs = require 'fs-extra'
sysPath = require 'path'
logging = require './logging'
Emitter = require('events').EventEmitter
netrc = require 'netrc'
utils = require './utils'
request = require 'superagent'

# In-flight requests.
inFlight = {}

# Package class
class Package extends Emitter
  constructor: (@name, @version, options) ->
    options ?= {}
    @version = 'master' if @version is '*'
    logging.info "Installing #{@name}@#{@version}..."

    @slug = "#{name}@#{version}"
    @dest = options.dest ? 'components'
    @remotes = options.remotes ? ['https://raw.github.com']
    @auth = options.auth
    @netrc = netrc(options.netrc)

    # if inFlight[@slug]
    #   @install = @emit.bind(@, 'end')
    # inFlight[@slug] = true

  dirname: ->
    sysPath.join @dest, @name

  join: (path) ->
    sysPath.join @dirname(), path

  url: (file) ->
    remote = @remotes[0]
    "#{remote}/#{@name}/#{@version}/#{file}"

  mkdir: (dir, callback) ->
    @dirs ?= {}
    if @dirs[dir] then return callback()
    fs.mkdirSync(dir, callback)

  # Get local json if the component is installed
  getLocalJSON: (callback) ->
    path = @join('component.json')
    fs.readFile path, 'utf8', (err, json) ->
      if err then return callback(err)
      try
        json = JSON.parse(json)
      catch err
        err.message += " in #{path}"
        return callback(err)
      callback(null, json)

  # Get component.json
  getJSON: (callback) ->
    url = @url('component.json')

    req = request.get(url)
    req.set 'Accept-Encoding', 'gzip'
    logging.info "fetching #{url}"

    # # authorize call
    # netrc = @netrc[parse(url).hostname]
    # if netrc
    #   req.auth(netrc.login, netrc.password)

    req.end (res) ->
      if res.error
        return callback(res.error)
      try
        json = JSON.parse(res.text)
      catch err
        err.message += " in #{url}"
        return callback(err)
      callback(null, json)

    req.on 'error', (err) ->
      if err.syscall is 'getaddrinfo'
        err.message = 'dns lookup failed'
      callback(err)

  # Fetch `files` and write them to disk then fire callback.
  getFiles: (files, callback) ->
    for file in files
      url = @url(file)
      @emit 'file', file, url
      dst = @join(file)

      # mkdir
      @mkdir sysPath.dirname(dst), (err) ->
        if err then return done(err)

        # pipe file
        req = request.get(url)
        req.set('Accept-Encoding', 'gzip')
        req.buffer(false)

        # authorize call
        netrc = @netrc[@remote.host]
        if netrc then req.auth(netrc.login, netrc.password)
        if @auth then req.auth(@auth.user, @auth.pass)

        req.end (res) ->
          if res.error then return done(error(res, url))
          res.pipe fs.createWriteStream(dst)
          res.on 'error', done
          res.on 'end', done

  writeFile: (file, str, callback) ->
    file = @join(file)
    fs.writeFile file, str, callback

  # Install dependencies
  getDependencies: (deps, callback) ->
    for name, version of deps
      pkg = new Package(name, version, {
          dest: @dest
          force: @force
          remotes: @remotes
        })
      @emit 'dep', pkg
      pkg.on 'end', done
      pkg.on 'exists', done
      pkg.install()

  # Check if the component exists already,
  # othewise install it for real.
  install: ->
    @getLocalJSON (err, json) =>
      if err?.code is 'ENOENT'
        @reallyInstall()
      else if err
        @emit 'error', err
      else if not @force
        @emit 'exists', @
      else
        @reallyInstall()

  reallyInstall: ->
    @getJSON (err, json) =>
      if err
        return
        # err.fatal = (err.status is 404) ? last
        # return @emit('error', err)

      files = []
      if json.scripts then files = files.concat(json.scripts)
      if json.styles then files = files.concat(json.styles)
      if json.templates then files = files.concat(json.templates)
      if json.files then files = files.concat(json.files)
      if json.images then files = files.concat(json.images)
      if json.fonts then files = files.concat(json.fonts)

      # json.repo ?= "#{@remote.href}/#{@name}"

      # if json.dependencies
      #   @getDependencies(json.dependencies, done)

      # @mkdir @dirname(), (err) ->
      #   @mkdir @dirname(), (err) ->
      #     json = JSON.stringify(json, null, 2)
      #     @writeFile 'component.json', json, done

      # @mkdir @dirname(), (err) ->
      #   @getFiles(files, done)


install = (name, version='master') ->
  pkg = new Package(name, version)
  pkg.install()

module.exports = {install}
