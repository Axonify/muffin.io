# Install packages from GitHub repos.

fs = require 'fs-extra'
sysPath = require 'path'
Emitter = require('events').EventEmitter
async = require 'async'
_ = require 'underscore'
project = require './project'
logging = require './utils/logging'
request = require './utils/request'

# In-flight requests
inFlight = {}

# Package
class Package extends Emitter

  constructor: (@repo, version) ->
    # The second argument could be a version number or an pkgInfo hash.
    if _.isObject(version)
      @pkgInfo = version
      @version = @pkgInfo.version
      @pkgInfo.name ?= @repo.split('/')[1]
    else
      @version = version

    # The default version is `master`.
    @version = 'master' if not @version or @version is '*'
    logging.info "Installing #{@repo}@#{@version}..."

    @remote = 'https://raw.github.com'
    @slug = "#{@repo}@#{@version}"

    # Use `repo@version` to de-duplicate in-flight requests.
    if inFlight[@slug]
      @install = @emit.bind(@, 'end')
    inFlight[@slug] = true

  dirname: ->
    sysPath.join(project.clientComponentsDir, @repo)

  join: (path) ->
    sysPath.join @dirname(), path

  url: (file) ->
    "#{@remote}/#{@repo}/#{@version}/#{file}"

  # Install the package
  install: ->
    # Sanity check on the repo name
    if @repo.indexOf('/') < 0
      logging.fatal "Invalid repo: #{@repo}"

    # If pkgInfo is given, use it to create a local
    # `component.json` file, then fetch the required files.
    # Otherwise, fetch `component.json` from the remote repo.
    if @pkgInfo
      @writeJSON @processJSON
    else
      @getJSON @processJSON

  # Create a local `component.json` from pkgInfo.
  writeJSON: (callback) ->
    json = @pkgInfo
    callback(null, json)

  # Fetch `component.json` from the remote repo.
  getJSON: (done) ->
    url = @url('component.json')

    logging.info "fetching #{url}"
    request.get url, null, (err, content) ->
      if err
        done(err)
      else
        try
          json = JSON.parse(content)
          done(null, json)
        catch e
          logging.fatal "Failed to fetch #{url}"
          done(e)

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

  # Fetch a single file and write it to disk.
  getFile: (file, done) =>
    url = @url(file)
    logging.info "fetching #{url}"

    @emit 'file', file, url
    dst = @join(file)
    fs.mkdirSync sysPath.dirname(dst)

    # download file and save to disk
    request.get url, dst, (err, res) ->
      if err then console.log "Problem with request #{err.message}"

  # Write a file to disk.
  writeFile: (file, str, callback) ->
    file = @join(file)
    logging.info "writing file #{file}"
    fs.writeFile file, str, callback

  # Install dependencies,
  getDependencies: (deps, callback) ->
    pkgs = []
    for name, version of deps
      pkg = new Package(name, version)
      pkgs.push pkg

    getPkg = (pkg, done) =>
      pkg.on 'end', done
      pkg.install()

    async.each pkgs, getPkg, callback

# Package Manager
class PackageManager

  install: (repo, version) ->
    pkg = new Package(repo, version)
    pkg.install()

# Freeze the object so it can't be modified later.
module.exports = Object.freeze(new PackageManager())
