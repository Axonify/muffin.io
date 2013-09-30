# The `muffin` command line tool.

fs = require 'fs-extra'
sysPath = require 'path'
_ = require 'underscore'
async = require 'async'
{spawn} = require 'child_process'
logging = require './utils/logging'
optparse = require './utils/optparse'
project = require './project'
watcher = require './watcher'
server = require './server'
pkgmgr = require './pkgmgr'
optimizer = require './optimizer'

# Underscore template settings
_.templateSettings =
  evaluate    : /<\?([\s\S]+?)\?>/g,
  interpolate : /<\?=([\s\S]+?)\?>/g,
  escape      : /<\?-([\s\S]+?)\?>/g

# The help banner
BANNER = '''
  Usage:

    Create a new project:
      * muffin new <project-name> (the frontend stack only)
      * muffin new <project-name> -s nodejs (frontend and Node.js server stack)
      * muffin new <project-name> -s gae (frontend and Google App Engine server stack)

    Code generators:
      * muffin generate model user (use --app option to generate inside a specific app)
      * muffin generate view UserListView
      * muffin generate scaffold user name:string email:string age:number --app auth

    Remove generated code:
      * muffin destroy model user
      * muffin destroy view UserListView
      * muffin destroy scaffold user --app auth

    Package management:
      * muffin install <package-name> (install a Muffin package and save in config.json)
      * muffin install (install all packages listed in config.json)
      * muffin update <package-name> (update a Muffin package and save in config.json)
      * muffin update  (update all packages listed in config.json)

    Watch mode:
      * muffin watch (watch the client files and recompile as needed)
      * muffin watch -s (watch the client files and start a web server/app server)
      * muffin watch -s -p 4001 (use --port or -p to specify the server port)

    Build:
      * muffin build (env is set to 'development', files are compiled but not minified)
      * muffin minify (env is set to 'production', files are minified and concatenated)
      * muffin server (run the server without watching client files, useful for testing the production build, use --port or -p to specify the server port)
      * muffin clean (remove the build directory)

    Run tests:
      * muffin test (tests are written in Mocha)

    Deploy:
      * muffin deploy [heroku|jitsu|gae|gh-pages]

    -h, --help         display this help message
    -v, --version      display the version number

'''

# The list of all the valid option flags that `muffin` supports.
SWITCHES = [
  ['-h', '--help',            'display this help message']
  ['-v', '--version',         'display the version number']
  ['-s', '--server',          'choose the server stack or start the server']
  ['-p', '--port',            'specify the server port']
  ['-a', '--app',             'set the app (default to main)']
  ['-m', '--map',             'generate source maps']
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
  # Remove the first two arguments because they are generic.
  # `process.argv = ['node', '/usr/local/lib/node_modules/muffin.io/bin/muffin', ...]`
  opts = optparse.parse(process.argv[2..], SWITCHES)
  return version() if opts.version
  return usage() if opts.help or opts.arguments.length is 0

  # The task name may consist of one or two words.
  for len in [1..2]
    name = opts.arguments[...len].join(' ')
    if tasks[name] then return invoke name

  # The task name is not recognized.
  logging.fatal "Muffin can't run the task '#{opts.arguments.join(' ')}'."

# Task - create a new project
task 'new', 'create a new project', ->
  projectName = opts.arguments[1]
  logging.fatal "You must provide a name for the project." unless projectName
  projectDir = sysPath.join(process.cwd(), projectName)
  logging.fatal "The application '#{projectName}' already exists." if fs.existsSync(projectDir)

  # Create the project directory
  createProjectDir = (done) ->
    fs.mkdir projectDir, done

  # Copy client boilerplate
  copyClientSkeleton = (done) ->
    from = sysPath.join(__dirname, '../skeletons/client')
    to = sysPath.join(projectDir, 'client')
    fs.copy from, to, done

  # Copy Node.js/MongoDB boilerplate
  copyNodeJSSkeleton = (done) ->
    from = sysPath.join(__dirname, '../skeletons/nodejs')
    to = sysPath.join(projectDir, 'server')
    fs.copy from, to, done

  # Copy Google App Engine boilerplate
  copyGAESkeleton = (done) ->
    from = sysPath.join(__dirname, '../skeletons/gae')
    to = sysPath.join(projectDir, 'server')
    fs.copy from, to, done

  # Write `config.json` in the project directory
  writeJSONConfig = (done) ->
    from = sysPath.join(__dirname, '../skeletons/config.json')
    json = JSON.parse(fs.readFileSync(from))
    switch opts.server
      when 'nodejs'
        json.serverDir = 'server'
        json.serverType = 'nodejs'
        json.buildDir = 'server/public'
        json.plugins.push 'muffin-generator-nodejs'
      when 'gae'
        json.serverDir = 'server'
        json.serverType = 'gae'
        json.buildDir = 'server/public'
        json.plugins.push 'muffin-generator-gae'
    to = sysPath.join(projectDir, 'config.json')
    fs.writeFileSync(to, JSON.stringify(json, null, 2))
    done(null)

  # Write .gitignore files
  writeGitIgnore = (done) ->
    switch opts.server
      when 'none'
        from = sysPath.join(__dirname, '../skeletons/_gitignore')
        to = sysPath.join(projectDir, '.gitignore')
        fs.copy from, to, done
      when 'nodejs', 'gae'
        from = sysPath.join(projectDir, 'server/_gitignore')
        to = sysPath.join(projectDir, 'server/.gitignore')
        fs.rename from, to, done

  # Print the completion message
  printMessage = (done) ->
    logging.info "The application '#{projectName}' has been created."
    logging.info "You need to run `muffin install` inside the project directory to install dependencies."

  # Use `async` to run these subtasks in series.
  opts.server ?= 'none'
  switch opts.server
    when 'none'
      async.series [createProjectDir, copyClientSkeleton, writeJSONConfig, writeGitIgnore, printMessage]
    when 'nodejs'
      async.series [createProjectDir, copyClientSkeleton, copyNodeJSSkeleton, writeJSONConfig, writeGitIgnore, printMessage]
    when 'gae'
      async.series [createProjectDir, copyClientSkeleton, copyGAESkeleton, writeJSONConfig, writeGitIgnore, printMessage]

# Task - create a new model
task 'generate model', 'create a new model', ->
  model = opts.arguments[2]
  logging.fatal "You must provide a name for the model." unless model
  app = opts.app ? 'main'

  # Invoke each generator to do its job.
  project.setEnv 'development'
  for generator in project.plugins.generators
    generator.generateModel?(model, app, opts.arguments[3..])

# Task - remove a generated model
task 'destroy model', 'remove a generated model', ->
  model = opts.arguments[2]
  logging.fatal "You must provide a name for the model." unless model
  app = opts.app ? 'main'

  # Invoke each generator to do its job.
  project.setEnv 'development'
  for generator in project.plugins.generators
    generator.destroyModel?(model, app)

# Task - create a new view
task 'generate view', 'create a new view', ->
  view = opts.arguments[2]
  logging.fatal "You must provide a name for the view." unless view
  app = opts.app ? 'main'

  # Invoke each generator to do its job.
  project.setEnv 'development'
  for generator in project.plugins.generators
    generator.generateView?(view, app)

# Task - remove a generated view
task 'destroy view', 'remove a generated view', ->
  view = opts.arguments[2]
  logging.fatal "You must provide a name for the view." unless view
  app = opts.app ? 'main'

  # Invoke each generator to do its job.
  project.setEnv 'development'
  for generator in project.plugins.generators
    generator.destroyView?(view, app)

# Task - create scaffolding for a resource
task 'generate scaffold', 'create scaffolding for a resource', ->
  model = opts.arguments[2]
  logging.fatal "You must provide a name for the model." unless model
  app = opts.app ? 'main'

  # Invoke each generator to do its job.
  project.setEnv 'development'
  for generator in project.plugins.generators
    generator.generateScaffold?(model, app, opts.arguments[3..])

# Task - remove generated scaffolding for a resource
task 'destroy scaffold', 'remove generated scaffolding for a resource', ->
  model = opts.arguments[2]
  logging.fatal "You must provide a name for the model." unless model
  app = opts.app ? 'main'

  # Invoke each generator to do its job.
  project.setEnv 'development'
  for generator in project.plugins.generators
    generator.destroyScaffold?(model, app)

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

    # Call `npm install` in the serverDir if using the Node.js stack
    if project.config.serverType is 'nodejs'
      spawn 'npm', ['install'], {cwd: project.serverDir, stdio: 'inherit'}

# Task - update packages
task 'update', 'update packages', ->

# Common subtask: build
build = (done) ->
  fs.removeSync(project.buildDir)
  project.loadHtmlHelpers()
  watcher.compileDir(project.clientDir, done)

# Common subtask: startServer
startServer = (done) ->
  if project.config.serverType in ['nodejs', 'gae'] and fs.existsSync(project.serverDir)
    server.startAppServer {port: opts.port}
  else
    server.startDummyWebServer {port: opts.port}

# Task - watch files and compile as needed
task 'watch', 'watch files and compile as needed', ->
  logging.info 'Watching project...'
  project.setEnv 'development'

  # Watch the client directory
  watch = (done) ->
    watcher.watchDir(project.clientDir)
    server.startLiveReloadServer()
    done(null)

  if opts.server
    async.series [server.testLiveReloadPort, build, watch, startServer]
  else
    async.series [server.testLiveReloadPort, build, watch]

# Task - compile coffeescripts and copy assets into `public/` directory
task 'build', 'compile coffeescripts and copy assets into public/ directory', ->
  logging.info 'Building project...'
  project.setEnv 'development'
  build -> {}

# Task - minify and concatenate js/css files for production
task 'minify', 'minify and concatenate js/css files for production', ->
  logging.info 'Preparing project files for production...'
  project.setEnv 'production'

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

  async.series [build, minify, removeTempDirs, concat]

# Task - start a server without watching client files
task 'server', 'start a server without watching client files', ->
  startServer -> {}

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
  dest = opts.arguments[1]?.toLowerCase()
  platforms = ['heroku', 'jitsu', 'gae', 'gh-pages']
  deployScriptExists = fs.existsSync('deploy.sh')

  createDeployScript = ->
    buildDir = sysPath.relative(process.cwd(), project.buildDir)
    serverDir = sysPath.relative(process.cwd(), project.serverDir)

    from = sysPath.join(__dirname, "deploy/#{dest}.sh")
    to = sysPath.join(process.cwd(), 'deploy.sh')
    deployScript = _.template(fs.readFileSync(from).toString(), {buildDir, serverDir})
    fs.writeFileSync(to, deployScript)

  invokeScript = ->
    deploy = spawn 'sh', ['deploy.sh'], {stdio: 'inherit'}
    deploy.on 'close', (code) ->
      if code is 0
        logging.info "The application has been successfully deployed."
      else
        logging.error "Failed to deploy the application."

  fatal = ->
    logging.fatal "Must choose a platform from the following: heroku, jitsu, gae, gh-pages"

  if dest
    if dest in platforms
      createDeployScript()
      invokeScript()
    else
      fatal()
  else
    if deployScriptExists
      invokeScript()
    else
      fatal()

# Print the `--help` usage message and exit.
usage = ->
  console.log BANNER

# Print the `--version` message and exit.
version = ->
  path = sysPath.join(__dirname, '../package.json')
  json = JSON.parse(fs.readFileSync(path))
  console.log "muffin.io - version #{json.version}"
