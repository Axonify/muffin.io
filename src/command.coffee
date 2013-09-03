#
# command.coffee
#

fs = require 'fs-extra'
sysPath = require 'path'
optparse = require 'coffee-script/lib/coffee-script/optparse'
async = require 'async'
{spawn, exec} = require 'child_process'
logging = require './utils/logging'
utils = require './utils/utils'
project = require './project'
watcher = require './watcher'
# server = require './server'
# pkgmgr = require './pkgmgr'
# optimizer = require './optimizer'

# The help banner that is printed when `muffin` is called without arguments.
BANNER = '''
  Usage:

    muffin new <project-name>
      - create a new project

    Code generators:
      * muffin generate model user
      * muffin generate view UserListView
      * muffin generate scaffold user name:string email:string age:number --app auth

    Remove generated code:
      * muffin destroy model user
      * muffin destroy view UserListView
      * muffin destroy scaffold user --app auth

    Package management:
      * muffin install <package-name>
      * muffin install (installs all the frontend dependencies specified in package.json)
      * muffin update <package-name>
      * muffin update (updates all the frontend dependencies)

    muffin watch
      - watch the current project and recompile as needed

    muffin build
      - compile coffeescripts into javascripts and copy assets to `public/` directory

    muffin minify
      - minify and concatenate js/css files, optimize png/jpeg images, build for production

    muffin clean
      - remove the build directory

    muffin test
      - run tests written in Mocha or Zombie.js

    muffin server
      - serve the app on port 3000 while watching static files

    muffin deploy [heroku | amazon | nodejitsu]
      - deploy to Heroku, Amazon or Nodejitsu

'''

# The list of all the valid option flags that `muffin` supports.
SWITCHES = [
  ['-h', '--help',            'display this help message']
  ['-v', '--version',         'display the version number']
  ['-s', '--server',          'choose the server stack']
  ['-e', '--env',             'set environment (development|production)']
  ['-a', '--app',             'set the app (default to main)']
  ['--cdn',                   'set CDN prefix']
  ['--hash',                  'set a hash as the client version']
]

# Top-level objects shared by all the functions.
tasks = {}
opts = {}
optionParser = null

# Define a task with a short name, an optional description, and the function to run.
task = (name, description, action) ->
  [action, description] = [description, action] unless action
  tasks[name] = {name, description, action}

# Invoke a task
invoke = (name) ->
  missingTask name unless tasks[name]
  tasks[name].action opts

# Run `muffin`
exports.run = ->
  optionParser = new optparse.OptionParser SWITCHES, BANNER
  try
    opts = optionParser.parse process.argv[2..]
  catch e
    utils.fatal e

  return usage() if process.argv.length <= 2 or opts.help
  return version() if opts.version

  if '-e' in opts.arguments or '--env' in opts.arguments
    index = opts.arguments.indexOf('-e')
    index = opts.arguments.indexOf('--env') if index is -1
    opts.env = opts.arguments[index+1]
    opts.arguments.splice(index, 2)

  if '-a' in opts.arguments or '--app' in opts.arguments
    index = opts.arguments.indexOf('-a')
    index = opts.arguments.indexOf('--app') if index is -1
    opts.app = opts.arguments[index+1]
    opts.arguments.splice(index, 2)

  if '-s' in opts.arguments or '--server' in opts.arguments
    index = opts.arguments.indexOf('-s')
    index = opts.arguments.indexOf('--server') if index is -1
    opts.server = opts.arguments[index+1]
    opts.arguments.splice(index, 2)

  if '--cdn' in opts.arguments
    opts.cdn = opts.arguments[opts.arguments.indexOf('--cdn') + 1]

  if '--hash' in opts.arguments
    opts.hash = opts.arguments[opts.arguments.indexOf('--hash') + 1]

  for len in [1..2]
    name = opts.arguments[0...len].join(' ')
    return invoke name if tasks[name]

# Task - create a new project
task 'new', 'create a new project', ->
  projectName = opts.arguments[1]
  utils.fatal "Must supply a name for the new project" unless projectName
  projectDir = sysPath.join(process.cwd(), projectName)
  utils.fatal "The application #{projectName} already exists." if fs.existsSync(projectDir)

  # Copy skeleton files
  createProjectDir = (done) ->
    fs.mkdir projectDir, done

  copyClientSkeleton = (done) ->
    from = sysPath.join(project.muffinDir, 'skeletons/client')
    to = sysPath.join(projectDir, 'client')
    fs.copy from, to, done

  copyNodeJSSkeleton = (done) ->
    from = sysPath.join(project.muffinDir, 'skeletons/nodejs')
    to = sysPath.join(projectDir, 'server')
    fs.copy from, to, done

  copyGAESkeleton = (done) ->
    from = sysPath.join(project.muffinDir, 'skeletons/gae')
    to = sysPath.join(projectDir, 'server')
    fs.copy from, to, done

  writeJSONConfig = (done) ->
    json = JSON.parse(fs.readFileSync(sysPath.join(project.muffinDir, 'skeletons/config.json')))
    switch opts.server
      when 'nodejs'
        json.serverDir = 'server'
        json.buildDir = 'server/public'
        json.plugins.push 'muffin-generator-nodejs'
      when 'gae'
        json.serverDir = 'server'
        json.buildDir = 'server/public'
        json.plugins.push 'muffin-generator-gae'
    to = sysPath.join(projectDir, 'config.json')
    fs.writeFileSync(to, JSON.stringify(json, null, 2))
    done(null)

  printMessage = (done) ->
    logging.info "The application '#{projectName}' has been created."
    logging.info "You need to run `muffin install` inside the project directory to install dependencies."

  opts.server ?= 'none'
  switch opts.server
    when 'none'
      async.series [createProjectDir, copyClientSkeleton, writeJSONConfig, printMessage]
    when 'nodejs'
      async.series [createProjectDir, copyClientSkeleton, copyNodeJSSkeleton, writeJSONConfig, printMessage]
    when 'gae'
      async.series [createProjectDir, copyClientSkeleton, copyGAESkeleton, writeJSONConfig, printMessage]

# Task - create a new model
task 'generate model', 'create a new model', ->
  model = opts.arguments[2]
  utils.fatal "Must supply a name for the model" unless model
  app = opts.app ? 'main'
  for generator in project.plugins.generators
    generator.generateModel(model, app, opts)

# Task - remove a generated model
task 'destroy model', 'remove a generated model', ->
  model = opts.arguments[2]
  utils.fatal "Must supply a name for the model" unless model
  app = opts.app ? 'main'
  for generator in project.plugins.generators
    generator.destroyModel(model, app)

# Task - create a new view
task 'generate view', 'create a new view', ->
  view = opts.arguments[2]
  utils.fatal "Must supply a name for the view" unless view
  app = opts.app ? 'main'
  for generator in project.plugins.generators
    generator.generateView(view, app)

# Task - remove a generated view
task 'destroy view', 'remove a generated view', ->
  view = opts.arguments[2]
  utils.fatal "Must supply a name for the view" unless view
  app = opts.app ? 'main'
  for generator in project.plugins.generators
    generator.destroyView(view, app)

# Task - create scaffold for a resource, including client models, views, templates, tests, and server models, RESTful APIs
task 'generate scaffold', 'create scaffold for a resource', ->
  model = opts.arguments[2]
  utils.fatal "Must supply a name for the model" unless model
  app = opts.app ? 'main'
  for generator in project.plugins.generators
    generator.generateScaffold(model, app, opts)

# Task - remove generated scaffold for a resource
task 'destroy scaffold', 'remove generated scaffold for a resource', ->
  model = opts.arguments[2]
  utils.fatal "Must supply a name for the model" unless model
  app = opts.app ? 'main'
  for generator in project.plugins.generators
    generator.destroyScaffold(model, app)

# Task - install packages
task 'install', 'install packages', ->
  pkgs = opts.arguments[1..]
  config = project.clientConfig
  if pkgs.length > 0
    # install the packages
    for pkg in pkgs
      [repo, version] = pkg.split('@')
      pkgmgr.install repo, version

    # save to config.json
    config.dependencies ?= {}
    for pkg in pkgs
      [repo, version] = pkg.split('@')
      config.dependencies[repo] = version ? '*'
    fs.writeFileSync(sysPath.join(project.clientDir, 'config.json'), JSON.stringify(config, null, 2))
  else
    # install all dependencies listed in config.json
    for repo, version of config.dependencies
      pkgmgr.install repo, version

# Task - update packages
task 'update', 'update packages', ->

# Task - watch files and compile as needed
task 'watch', 'watch files and compile as needed', ->
  logging.info 'Watching project...'
  project.setEnv (opts.env ? 'development'), opts
  project.loadClientSources()
  fs.removeSync(project.buildDir)

  async.series [
    # Build
    (done) ->
      p = spawn "#{__dirname}/../bin/muffin", ['build'], {stdio: 'inherit'}
      p.on 'close', done

    # Watch client dir
    (done) ->
      watcher.watchDir(project.clientDir)
      server.startLiveReloadServer()
  ]

# Task - compile coffeescripts and copy assets into `public/` directory
task 'build', 'compile coffeescripts and copy assets into public/ directory', ->
  logging.info 'Building project...'
  project.setEnv (opts.env ? 'development'), opts
  project.loadClientSources()
  project.buildRequireConfig()
  fs.removeSync(project.buildDir)
  watcher.compileDir(project.clientDir)

# Task - optimize js/css files (internal use only)
task 'optimize', 'optimize js/css files', ->
  project.setEnv (opts.env ? 'development'), opts
  fs.removeSync(project.tempBuildDir)
  optimizer.optimizeDir(project.buildDir, project.tempBuildDir)

# Task - minify and concatenate js/css files for production
task 'minify', 'minify and concatenate js/css files for production', ->
  logging.info 'Preparing project files for production...'
  project.setEnv (opts.env ? 'production'), opts
  async.series [
    # Rebuild
    (done) ->
      args = ['build', '-e', 'production']
      if opts.cdn
        args = args.concat ['--cdn', opts.cdn]
      if opts.hash
        args = args.concat ['--hash', opts.hash]

      p = spawn "#{__dirname}/../bin/muffin", args, {stdio: 'inherit'}
      p.on 'exit', (code) ->
        if code isnt 0
          process.exit(code)
        else
          done(null)

    # Minify
    (done) ->
      p =  spawn "#{__dirname}/../bin/muffin", ['optimize', '-e', 'production'], {stdio: 'inherit'}
      p.on 'exit', (code) ->
        if code isnt 0
          process.exit(code)
        else
          done(null)

    # Remove temp directories
    (done) ->
      fs.removeSync(project.buildDir)
      fs.renameSync(project.tempBuildDir, project.buildDir)
      done(null)

    # Concatenate modules
    (done) ->
      for path in project.clientConfig.concat
        logging.info "Concatenating module dependencies: #{path}"
        project.buildRequireConfig()
        optimizer.concatDeps(path)
      done(null)
  ]

# Task - remove the build directory
task 'clean', 'remove the build directory', ->
  fs.removeSync(project.buildDir)
  relativePath = sysPath.relative(process.cwd(), project.buildDir)
  logging.warn "Removed the build directory at #{relativePath}."

# Task - run tests
task 'test', 'run tests', ->
  project.setEnv (opts.env ? 'test'), opts
  mocha = new Mocha
  mocha
    .reporter('spec')
    .ui('bdd')
    .growl()
  mocha.addFile './test/spec'
  mocha.run (failures) ->
    process.exit (if failures > 0 then 1 else 0)

# Task - start the server and watch files
task 'server', 'start a webserver', ->
  project.setEnv (opts.env ? 'development'), opts
  fs.removeSync(project.buildDir)

  async.series [
    # Build
    (done) ->
      p = spawn "#{__dirname}/../bin/muffin", ['build'], {stdio: 'inherit'}
      p.on 'close', done

    # Watch client dir, start servers.
    (done) ->
      project.buildRequireConfig()
      watcher.watchDir(project.clientDir)

      # Start the live reload server
      server.startLiveReloadServer()

      # Start either the dummy web server or real app server
      if fs.existsSync(project.serverDir)
        server.startAppServer()
      else
        server.startDummyWebServer()
  ]

# Task - deploy the app
task 'deploy', 'deploy the app', ->
  dest = opts.arguments[1]
  platforms = ['heroku', 'amazon', 'nodejitsu']
  unless dest and dest.toLowerCase() in platforms
    utils.fatal "Must choose a platform from the following: heroku, amazon, nodejitsu"

# Find file in directory
findFileIn = (dir) ->
  found = []
  for file in fs.readdirSync(dir)
    file = sysPath.join(dir, file)
    if /\.coffee$/.test file
      found.push file
    else
      stats = fs.statSync(file)
      if stats.isDirectory() and not /nls$/.test file
        found = found.concat findFileIn(file)
  return found

# Print the `--help` usage message and exit.
usage = ->
  console.log optionParser.help()

# Print the `--version` message and exit.
version = ->
  json = JSON.parse(fs.readFileSync("#{__dirname}/../package.json"))
  console.log "muffin.io - version #{json.version}"
