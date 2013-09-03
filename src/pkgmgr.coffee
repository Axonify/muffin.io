#
# pkgmgr.coffee
#

fs = require 'fs-extra'
sysPath = require 'path'
logging = require './utils/logging'
project = require './project'
Emitter = require('events').EventEmitter
async = require 'async'
_ = require 'underscore'
request = require './utils/request'

# In-flight requests
inFlight = {}

# Package class
class Package extends Emitter
  constructor: (@repo, version, options) ->
    if _.isObject(version)
      @pkgInfo = version
      @version = @pkgInfo.version
      @pkgInfo.name ?= @repo.split('/')[1]
    else
      @version = version

    options ?= {}
    @version = 'master' if @version is '*'
    logging.info "Installing #{@repo}@#{@version}..."

    @slug = "#{@repo}@#{@version}"
    @remote = options.remote ? 'https://raw.github.com'
    @auth = options.auth

    if inFlight[@slug]
      @install = @emit.bind(@, 'end')
    inFlight[@slug] = true

  dirname: ->
    sysPath.join(project.clientComponentsDir, @repo)

  join: (path) ->
    sysPath.join @dirname(), path

  url: (file) ->
    "#{@remote}/#{@repo}/#{@version}/#{file}"

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
  getJSON: (done) ->
    url = @url('component.json')

    logging.info "fetching #{url}"
    request.get url, null, (err, content) ->
      if err
        done(err)
      else
        done(null, JSON.parse(content))

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

    # download file and save to disk
    request.get url, dst, (err, res) ->
      if err then console.log "Problem with request #{err.message}"

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
    if @repo.indexOf('/') < 0
      @emit 'error', new Error("invalid component repo '#{@repo}'")

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


install = (repo, version='master') ->
  pkg = new Package(repo, version)
  pkg.install()

module.exports = {install}
