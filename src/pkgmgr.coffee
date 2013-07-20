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
{parse} = require 'url'
async = require 'async'
_ = require 'underscore'

# In-flight requests
inFlight = {}

# Package class
class Package extends Emitter
  constructor: (@name, version, options) ->
    if _.isObject(version)
      @pkgInfo = version
      @version = @pkgInfo.version
    else
      @version = version

    options ?= {}
    @version = 'master' if @version is '*'
    logging.info "Installing #{@name}@#{@version}..."

    @slug = "#{@name}@#{@version}"
    @dest = options.dest ? 'components'
    @remote = options.remote ? 'https://raw.github.com'
    @auth = options.auth
    @netrc = netrc(options.netrc)

    if inFlight[@slug]
      @install = @emit.bind(@, 'end')
    inFlight[@slug] = true

  dirname: ->
    sysPath.join @dest, @name

  join: (path) ->
    sysPath.join @dirname(), path

  url: (file) ->
    "#{@remote}/#{@name}/#{@version}/#{file}"

  # Get local json if the component is installed
  getLocalJSON: (callback) ->
    path = @join('component.json')
    fs.readFile path, 'utf8', (err, json) ->
      if err
        return callback(err)
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

    # authorize call
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

  # Create a local component.json from pkgInfo
  writeJSON: (callback) ->
    json = @pkgInfo
    callback(null, json)

  # Fetch a single file, write to disk then call the callback.
  getFile: (file, done) =>
    url = @url(file)
    logging.info "fetching #{url}"

    @emit 'file', file, url
    dst = @join(file)
    fs.mkdirSync sysPath.dirname(dst)

    # pipe file
    req = request.get(url)
    req.set('Accept-Encoding', 'gzip')
    req.buffer(false)

    # authorize call
    # netrc = @netrc[@remote.host]
    # if netrc then req.auth(netrc.login, netrc.password)
    # if @auth then req.auth(@auth.user, @auth.pass)

    req.end (res) ->
      if res.error then return done(res.error)
      res.pipe fs.createWriteStream(dst)
      res.on 'error', done
      res.on 'end', done

  writeFile: (file, str, callback) ->
    file = @join(file)
    logging.info "writing file #{file}"
    fs.writeFile file, str, callback

  # Install dependencies
  getDependencies: (deps, callback) ->
    pkgs = []
    for name, version of deps
      pkg = new Package(name, version)
      pkgs.push pkg

    getPkg = (pkg, done) =>
      @emit 'dep', pkg
      pkg.on 'end', done
      pkg.on 'exists', done
      pkg.install()

    async.each pkgs, getPkg, callback

  # Check if the component exists already,
  # othewise install it for real.
  install: ->
    if @name.indexOf('/') < 0
      @emit 'error', new Error("invalid component name '#{@name}'")

    @getLocalJSON (err, json) =>
      if err?.code is 'ENOENT'
        @reallyInstall()
      else if err
        @emit 'error', err
      else
        @reallyInstall()

  reallyInstall: ->
    if @pkgInfo
      @writeJSON @processJSON
    else
      @getJSON @processJSON

  processJSON: (err, json) =>
    if err
      return @emit('error', err)

    files = []
    if json.main then files.push(json.main)
    if json.scripts then files = files.concat(json.scripts)
    if json.styles then files = files.concat(json.styles)
    if json.templates then files = files.concat(json.templates)
    if json.files then files = files.concat(json.files)
    if json.images then files = files.concat(json.images)
    if json.fonts then files = files.concat(json.fonts)

    # Remove duplicates
    files = _.uniq(files)

    async.parallel [
      # get dependencies
      (done) =>
        if json.dependencies
          @getDependencies json.dependencies, done
        else
          done(null)

      # download the files
      (done) =>
        async.each files, @getFile, done

      # save component.json
      (done) =>
        fs.mkdirSync @dirname()
        json = JSON.stringify(json, null, 2)
        @writeFile 'component.json', json, done

    ], (err, results) =>
      if err
        @emit 'error', err
      else
        @emit 'end'


install = (name, version='master') ->
  pkg = new Package(name, version)
  pkg.install()

module.exports = {install}
