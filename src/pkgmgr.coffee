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
    @remote = 'https://raw.githubusercontent.com'
    logging.info "Installing #{@repo}@#{@version}..."

    # De-duplicate in-flight requests. Also skip local dependencies.
    if inFlight[@repo] or @pkgInfo?.local
      @install = @emit.bind(@, 'end')
    inFlight[@repo] = true

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

    # If `pkgInfo` is given, use it as `component.json`.
    # Otherwise, fetch `component.json` from the remote repo.
    if @pkgInfo
      @processJSON(@pkgInfo)
    else
      @fetchJSON @processJSON

  # Fetch `component.json` from the remote repo.
  fetchJSON: (done) ->
    url = @url('component.json')
    logging.info "Fetching #{url}"

    request.get url, null, (err, content) ->
      if err then logging.fatal err
      try
        json = JSON.parse(content)
        done(json)
      catch e
        logging.fatal "Failed to fetch #{url}.\n#{e}"

  processJSON: (json) =>
    # Gather all the required files
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
      # Get dependencies
      (done) =>
        if json.dependencies
          @getDependencies json.dependencies, done
        else
          done(null)

      # Download the files
      (done) =>
        async.each files, @getFile, done

      # Save component.json
      (done) =>
        fs.mkdirSync @dirname()
        @writeFile 'component.json', JSON.stringify(json, null, 2), done

    ], (err, results) =>
      if err then logging.fatal err
      @emit 'end'

  # Fetch a single file and write it to disk.
  getFile: (file, done) =>
    url = @url(file)
    logging.info "Fetching #{url}"

    # Create the dir
    dest = @join(file)
    fs.mkdirSync sysPath.dirname(dest)

    # Download the file and save it to disk.
    request.get url, dest, done

  # Write a file to disk.
  writeFile: (file, str, callback) ->
    file = @join(file)
    logging.info "Writing file #{file}"
    fs.writeFile file, str, callback

  # Install dependencies,
  getDependencies: (deps, callback) ->
    pkgs = []
    for repo, version of deps
      # Top-level repo settings take precedence.
      version = project.clientConfig.dependencies[repo] ? version
      pkg = new Package(repo, version)
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
