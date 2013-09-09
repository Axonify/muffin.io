# The `muffin` command line tool.

fs = require 'fs-extra'
sysPath = require 'path'
async = require 'async'
logging = require './utils/logging'
optparse = require './utils/optparse'
project = require './project'
watcher = require './watcher'
server = require './server'
pkgmgr = require './pkgmgr'
optimizer = require './optimizer'

# The help banner that is printed when `muffin` is called without arguments.
BANNER = '''
  Usage:

    muffin new <project-name>
      - create a new project
      - you can specify a server stack with: --server [nodejs|gae]

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
      - env is set to 'development'
      - watch the current project and recompile as needed
      - you can specify --server or -s to start a web server (auto detected from server type)

    muffin build
      - make a development build, env is set to 'development'
      - compile coffeescripts into javascripts and copy assets to `public/` directory

    muffin minify
      - make a production build, env is set to 'production'
      - minify and concatenate js/css files, build for production

    muffin clean
      - remove the build directory

    muffin test
      - run tests written in Mocha or Zombie.js

    muffin deploy [heroku | amazon | nodejitsu]
      - deploy to Heroku, Amazon or Nodejitsu

    -h, --help         display this help message
    -v, --version      display the version number

'''

# The list of all the valid option flags that `muffin` supports.
SWITCHES = [
  ['-h', '--help',            'display this help message']
  ['-v', '--version',         'display the version number']
  ['-s', '--server',          'choose the server stack']
  ['-a', '--app',             'set the app (default to main)']
]

# Top-level objects shared by all the functions.
tasks = {}
opts = {}

# Define a task with a short name, a description, and the function to run.
task = (name, description, action) ->
  tasks[name] = {name, description, action}

# Invoke a task
invoke = (name) ->
  tasks[name].action opts

# Run `muffin`
exports.run = ->
  opts = optparse.parse(process.argv[2..], SWITCHES)
  return usage() if opts.help or opts.arguments.length is 0
  return version() if opts.version

  for len in [1..2]
    name = opts.arguments[0...len].join(' ')
    return invoke name if tasks[name]

# Task - create a new project
task 'new', 'create a new project', ->
  projectName = opts.arguments[1]
  logging.fatal "Must supply a name for the new project" unless projectName
  projectDir = sysPath.join(process.cwd(), projectName)
  logging.fatal "The application #{projectName} already exists." if fs.existsSync(projectDir)

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

  writeGitIgnore = (done) ->
    from = sysPath.join(project.muffinDir, 'skeletons/.gitignore')
    to = sysPath.join(projectDir, '.gitignore')
    fs.copy from, to, done

  printMessage = (done) ->
    logging.info "The application '#{projectName}' has been created."
    logging.info "You need to run `muffin install` inside the project directory to install dependencies."

  opts.server ?= 'none'
  switch opts.server
    when 'none'
      async.series [createProjectDir, copyClientSkeleton, writeJSONConfig, writeGitIgnore, printMessage]
    when 'nodejs'
      async.series [createProjectDir, copyClientSkeleton, copyNodeJSSkeleton, writeJSONConfig, printMessage]
    when 'gae'
      async.series [createProjectDir, copyClientSkeleton, copyGAESkeleton, writeJSONConfig, printMessage]

# Task - create a new model
task 'generate model', 'create a new model', ->
  model = opts.arguments[2]
  logging.fatal "Must supply a name for the model" unless model
  app = opts.app ? 'main'
  for generator in project.plugins.generators
    generator.generateModel(model, app, opts)

# Task - remove a generated model
task 'destroy model', 'remove a generated model', ->
  model = opts.arguments[2]
  logging.fatal "Must supply a name for the model" unless model
  app = opts.app ? 'main'
  for generator in project.plugins.generators
    generator.destroyModel(model, app)

# Task - create a new view
task 'generate view', 'create a new view', ->
  view = opts.arguments[2]
  logging.fatal "Must supply a name for the view" unless view
  app = opts.app ? 'main'
  for generator in project.plugins.generators
    generator.generateView(view, app)

# Task - remove a generated view
task 'destroy view', 'remove a generated view', ->
  view = opts.arguments[2]
  logging.fatal "Must supply a name for the view" unless view
  app = opts.app ? 'main'
  for generator in project.plugins.generators
    generator.destroyView(view, app)

# Task - create scaffold for a resource, including client models, views, templates, tests, and server models, RESTful APIs
task 'generate scaffold', 'create scaffold for a resource', ->
  model = opts.arguments[2]
  logging.fatal "Must supply a name for the model" unless model
  app = opts.app ? 'main'
  for generator in project.plugins.generators
    generator.generateScaffold(model, app, opts)

# Task - remove generated scaffold for a resource
task 'destroy scaffold', 'remove generated scaffold for a resource', ->
  model = opts.arguments[2]
  logging.fatal "Must supply a name for the model" unless model
  app = opts.app ? 'main'
  for generator in project.plugins.generators
    generator.destroyScaffold(model, app)

# Task - install packages
task 'install', 'install packages', ->
  project.setEnv 'development'

  pkgs = opts.arguments[1..]
  if pkgs.length > 0
    # install the packages
    for pkg in pkgs
      [repo, version] = pkg.split('@')
      pkgmgr.install repo, version

    # save to config.json
    config = project.clientConfig
    config.dependencies ?= {}
    for pkg in pkgs
      [repo, version] = pkg.split('@')
      config.dependencies[repo] = version ? '*'
    fs.writeFileSync(sysPath.join(project.clientDir, 'config.json'), JSON.stringify(config, null, 2))
  else
    # install all dependencies listed in config.json
    for repo, version of project.clientConfig.dependencies
      pkgmgr.install repo, version

# Task - update packages
task 'update', 'update packages', ->

# Task - watch files and compile as needed
task 'watch', 'watch files and compile as needed', ->
  logging.info 'Watching project...'
  project.setEnv 'development'

  # Rebuild
  rebuild = (done) ->
    project.buildRequireConfig()
    fs.removeSync(project.buildDir)
    watcher.compileDir(project.clientDir, done)

  # Watch the client directory
  watch = (done) ->
    watcher.watchDir(project.clientDir)
    server.startLiveReloadServer()
    done(null)

  # Start either the dummy web server or real app server
  startServer = (done) ->
    if project.serverType in ['nodejs', 'gae'] and fs.existsSync(project.serverDir)
      server.startAppServer()
    else
      server.startDummyWebServer()

  if opts.server
    async.series [rebuild, watch, startServer]
  else
    async.series [rebuild, watch]

# Task - compile coffeescripts and copy assets into `public/` directory
task 'build', 'compile coffeescripts and copy assets into public/ directory', ->
  logging.info 'Building project...'
  project.setEnv 'development'
  project.buildRequireConfig()
  fs.removeSync(project.buildDir)
  watcher.compileDir project.clientDir, -> {}

# Task - minify and concatenate js/css files for production
task 'minify', 'minify and concatenate js/css files for production', ->
  logging.info 'Preparing project files for production...'
  project.setEnv 'production'

  rebuild = (done) ->
    logging.info 'Building project...'
    project.buildRequireConfig()
    fs.removeSync(project.buildDir)
    watcher.compileDir(project.clientDir, done)

  minify = (done) ->
    logging.info 'Minifying project files...'
    fs.removeSync(project.tempBuildDir)
    optimizer.optimizeDir(project.buildDir, project.tempBuildDir, done)

  # Remove temp directories
  removeTempDirs = (done) ->
    fs.removeSync(project.buildDir)
    fs.renameSync(project.tempBuildDir, project.buildDir)
    done(null)

  # Concatenate modules
  concat = (done) ->
    for path in project.clientConfig.concat
      logging.info "Concatenating module dependencies: #{path}"
      optimizer.concatDeps(path)
    done(null)

  async.series [rebuild, minify, removeTempDirs, concat]

# Task - remove the build directory
task 'clean', 'remove the build directory', ->
  fs.removeSync(project.buildDir)
  relativePath = sysPath.relative(process.cwd(), project.buildDir)
  logging.warn "Removed the build directory at #{relativePath}."

# Task - run tests
task 'test', 'run tests', ->
  project.setEnv 'test'
  mocha = new Mocha
  mocha
    .reporter('spec')
    .ui('bdd')
    .growl()
  mocha.addFile './test/spec'
  mocha.run (failures) ->
    process.exit (if failures > 0 then 1 else 0)

# Task - deploy the app
task 'deploy', 'deploy the app', ->
  dest = opts.arguments[1]
  platforms = ['heroku', 'amazon', 'nodejitsu']
  unless dest and dest.toLowerCase() in platforms
    logging.fatal "Must choose a platform from the following: heroku, amazon, nodejitsu"

# Print the `--help` usage message and exit.
usage = ->
  console.log BANNER

# Print the `--version` message and exit.
version = ->
  json = JSON.parse(fs.readFileSync("#{__dirname}/../package.json"))
  console.log "muffin.io - version #{json.version}"
