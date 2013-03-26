fs = require 'fs-extra'
sysPath = require 'path'
optparse = require 'coffee-script/lib/coffee-script/optparse'
async = require 'async'
Mocha = require 'mocha'
{spawn, exec} = require 'child_process'
watch = require './watch'
logging = require './logging'
optimizer = require './optimizer'
_ = require './_inflection'

try config = require sysPath.join(process.cwd(), 'config')
try buildConfig = require sysPath.join(process.cwd(), 'client/config/config')

# The help banner that is printed when `muffin` is called without arguments.
BANNER = '''
  Usage:
    
    muffin new PROJECT_NAME
      - create a new project
    
    Code generators:
      * muffin generate model user
      * muffin generate view UserListView
      * muffin generate scaffold user name:string email:string age:number --app auth
    
    Remove generated code:
      * muffin destroy model user
      * muffin destroy view UserListView
      * muffin destroy scaffold user --app auth
    
    Install reusable apps or widgets:
      * muffin install app auth
      * muffin install widget ProgressBar
    
    muffin watch
      - watch the current project and recompile as needed
    
    muffin build
      - compile coffeescripts into javascripts and copy assets to `public/` directory
    
    muffin minify
      - minify and concatenate js/css files, optimize png/jpeg images, build for production
    
    muffin clean
      - remove all files inside `public/` directory
    
    muffin test
      - run tests written in Mocha or Zombie.js
    
    muffin doc
      - generate documentation via docco
    
    muffin server
      - serve the app on port 3000 while watching static files
    
    muffin deploy [heroku | amazon | nodejitsu]
      - deploy to Heroku, Amazon or Nodejitsu
    
'''

# The list of all the valid option flags that `muffin` supports.
SWITCHES = [
  ['-h', '--help',            'display this help message']
  ['-v', '--version',         'display the version number']
  ['-e', '--env',             'set environment (development|production)']
  ['-a', '--app',             'set the app (default to main)']
  ['--cdn',                   'set CDN prefix']
]

# Top-level objects shared by all the functions.
tasks = {}
opts = {}
optionParser = null
cwd = process.cwd()
muffinDir = sysPath.join(__dirname, '../')
templatesDir = sysPath.join(muffinDir, 'framework/templates')
cwd = process.cwd()
clientDir = sysPath.join(cwd, 'client')
serverDir = sysPath.join(cwd, 'server')
publicDir = sysPath.join(cwd, 'public')
buildDir = sysPath.join(cwd, 'build')
jsDir = sysPath.join(cwd, 'public/javascripts')

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
    fatalError e
  
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
  
  if '--cdn' in opts.arguments
    opts.cdn = opts.arguments[opts.arguments.indexOf('--cdn') + 1]
    watch.setCDN opts.cdn
  
  for len in [1..2]
    name = opts.arguments[0...len].join(' ')
    return invoke name if tasks[name]

# Task - create a new project
task 'new', 'create a new project', ->
  projectName = opts.arguments[1]
  fatalError "Must supply a name for the new project" unless projectName
  projectDir = sysPath.join cwd, projectName
  fatalError "The application #{projectName} already exists." if fs.existsSync(projectDir)
  
  async.series [
    # Copy skeleton files
    (done) ->
      skeletonPath = sysPath.join muffinDir, 'framework/skeleton'
      fs.copy skeletonPath, projectDir, done
    
    # Set up .gitignore
    (done) ->
      fs.copy sysPath.join(projectDir, '.npmignore'), sysPath.join(projectDir, '.gitignore'), done
    
    # Print logs
    (done) ->
      logging.info "The application '#{projectName}' has been created."
      logging.info "You need to run `npm install` inside the project directory to install dependencies."
  ] 

# Task - create a new model
task 'generate model', 'create a new model', ->
  model = opts.arguments[2]
  fatalError "Must supply a name for the model" unless model
  
  app = opts.app ? 'main'
  classified = _.classify(model)
  underscored = _.underscored(model)
  underscored_plural = _.underscored(_.pluralize(model))
  attrs = parseAttrs(opts.arguments[3..])
  
  copyTemplate {model, classified, underscored, underscored_plural, attrs, _},
    'client/models/model.coffee': "client/apps/#{app}/models/#{classified}.coffee"
    'client/models/collection.coffee': "client/apps/#{app}/models/#{classified}List.coffee"
    'server/models/model.coffee': "server/apps/#{app}/models/#{classified}.coffee"
    'server/controllers/controller.coffee': "server/apps/#{app}/controllers/#{classified}Controller.coffee"

# Task - remove a generated model
task 'destroy model', 'remove a generated model', ->
  model = opts.arguments[2]
  fatalError "Must supply a name for the model" unless model
  
  app = opts.app ? 'main'
  classified = _.classify(model)
  files = [
    "client/apps/#{app}/models/#{classified}.coffee"
    "client/apps/#{app}/models/#{classified}List.coffee"
    "server/apps/#{app}/models/#{classified}.coffee"
    "server/apps/#{app}/controllers/#{classified}Controller.coffee"
  ]
  removeFiles(files)

# Task - create a new view
task 'generate view', 'create a new view', ->
  view = opts.arguments[2]
  fatalError "Must supply a name for the view" unless view
  
  app = opts.app ? 'main'
  copyTemplate {view, _},
    'client/views/view.coffee': "client/apps/#{app}/views/#{_.classify(view)}.coffee"
    'client/templates/view.jade': "client/apps/#{app}/templates/#{_.classify(view)}.jade"

# Task - remove a generated view
task 'destroy view', 'remove a generated view', ->
  view = opts.arguments[2]
  fatalError "Must supply a name for the view" unless view
  
  app = opts.app ? 'main'
  files = [
    "client/apps/#{app}/views/#{_.classify(view)}.coffee"
    "client/apps/#{app}/templates/#{_.classify(view)}.jade"
  ]
  removeFiles(files)

# Task - create scaffold for a resource, including client models, views, templates, tests, and server models, RESTful APIs
task 'generate scaffold', 'create scaffold for a resource', ->
  model = opts.arguments[2]
  fatalError "Must supply a name for the model" unless model
  
  app = opts.app ? 'main'
  classified = _.classify(model)
  underscored = _.underscored(model)
  underscored_plural = _.underscored(_.pluralize(model))
  attrs = parseAttrs(opts.arguments[3..])
  
  copyTemplate {model, classified, underscored, underscored_plural, attrs, _},
    'client/models/model.coffee': "client/apps/#{app}/models/#{classified}.coffee"
    'client/models/collection.coffee': "client/apps/#{app}/models/#{classified}List.coffee"
    'client/views/index.coffee': "client/apps/#{app}/views/#{classified}IndexView.coffee"
    'client/templates/index.jade': "client/apps/#{app}/templates/#{classified}IndexView.jade"
    'client/templates/table.jade': "client/apps/#{app}/templates/#{classified}ListTable.jade"
    'client/views/show.coffee': "client/apps/#{app}/views/#{classified}ShowView.coffee"
    'client/templates/show.jade': "client/apps/#{app}/templates/#{classified}ShowView.jade"
    'client/views/new.coffee': "client/apps/#{app}/views/#{classified}NewView.coffee"
    'client/templates/new.jade': "client/apps/#{app}/templates/#{classified}NewView.jade"
    'client/views/edit.coffee': "client/apps/#{app}/views/#{classified}EditView.coffee"
    'client/templates/edit.jade': "client/apps/#{app}/templates/#{classified}EditView.jade"
    'server/models/model.coffee': "server/apps/#{app}/models/#{classified}.coffee"
    'server/controllers/controller.coffee': "server/apps/#{app}/controllers/#{classified}Controller.coffee"
  
  # Inject routes into client router
  _.templateSettings =
    evaluate    : /<\$([\s\S]+?)\$>/g,
    interpolate : /<\$=([\s\S]+?)\$>/g,
    escape      : /<\$-([\s\S]+?)\$>/g
  
  routes = fs.readFileSync(sysPath.join(templatesDir, 'client/router.coffee')).toString()
  lines = _.template(routes, {model, classified, underscored, underscored_plural, _}).split('\n')
  injectIntoFile "client/apps/#{app}/router.coffee", '\n' + lines[0..4].join('\n') + '\n', null, "routes:"
  injectIntoFile "client/apps/#{app}/router.coffee", lines[6..24].join('\n') + '\n\n', "module.exports", null
  
  # Inject routes into server router
  routes = fs.readFileSync(sysPath.join(templatesDir, 'server/router.coffee')).toString()
  lines = _.template(routes, {model, classified, underscored, underscored_plural, _}).split('\n')
  injectIntoFile "server/apps/#{app}/router.coffee", lines[0] + '\n\n', "# Router", null
  injectIntoFile "server/apps/#{app}/router.coffee", lines[2..7].join('\n') + '\n\n', "module.exports", null

# Task - remove generated scaffold for a resource
task 'destroy scaffold', 'remove generated scaffold for a resource', ->
  model = opts.arguments[2]
  fatalError "Must supply a name for the model" unless model
  
  app = opts.app ? 'main'
  classified = _.classify(model)
  files = [
    "client/apps/#{app}/models/#{classified}.coffee"
    "client/apps/#{app}/models/#{classified}List.coffee"
    "client/apps/#{app}/views/#{classified}IndexView.coffee"
    "client/apps/#{app}/templates/#{classified}IndexView.jade"
    "client/apps/#{app}/templates/#{classified}ListTable.jade"
    "client/apps/#{app}/views/#{classified}ShowView.coffee"
    "client/apps/#{app}/templates/#{classified}ShowView.jade"
    "client/apps/#{app}/views/#{classified}NewView.coffee"
    "client/apps/#{app}/templates/#{classified}NewView.jade"
    "client/apps/#{app}/views/#{classified}EditView.coffee"
    "client/apps/#{app}/templates/#{classified}EditView.jade"
    "server/apps/#{app}/models/#{classified}.coffee"
    "server/apps/#{app}/controllers/#{classified}Controller.coffee"
  ]
  removeFiles(files)

# Task - install reusable apps or widgets
task 'install', 'install reusable apps or widgets', ->
  installApp = (app) ->
    fs.copy sysPath.join(muffinDir, "framework/apps/#{app}/client"), sysPath.join(clientDir, "apps/#{app}"), -> {}
    fs.copy sysPath.join(muffinDir, "framework/apps/#{app}/server"), sysPath.join(serverDir, "apps/#{app}"), -> {}
    readme = sysPath.join(muffinDir, "framework/apps/#{app}/README.md")
    if fs.existsSync(readme)
      logging.info '\n' + fs.readFileSync(readme).toString()
  
  installWidget = (widget) ->
    fs.copy sysPath.join(muffinDir, "framework/widgets/#{widget}"), sysPath.join(clientDir, "widgets/#{widget}"), -> {}
    readme = sysPath.join(muffinDir, "framework/widgets/#{widget}/README.md")
    if fs.existsSync(readme)
      logging.info '\n' + fs.readFileSync(readme).toString()
  
  if opts.arguments.length is 1
    # Install all the apps and widgets specified in config.coffee
    installApp(app) for app in config.installed_apps
    installWidget(widget) for widget in config.installed_widgets
  else
    switch opts.arguments[1]
      when 'app'
        app = opts.arguments[2]
        fatalError "Must specify the app to install" unless app
        installApp(app)
      when 'widget'
        widget = opts.arguments[2]
        fatalError "Must specify the widget to install" unless widget
        installWidget(widget)
      else
        fatalError "Unknown type. Supported types are: app, widget."

# Task - watch files and compile as needed
task 'watch', 'watch files and compile as needed', ->
  logging.info "Watching project..."
  watch.setEnv (opts.env ? 'development')
  fs.removeSync publicDir
  
  async.series [
    # Build
    (done) ->
      p = spawn "#{__dirname}/../bin/muffin", ['build']
      p.stdout.on 'data', (data) -> logging.info data
      p.stderr.on 'data', (data) -> logging.error data
      p.on 'exit', done
    
    # Watch client dir
    (done) ->
      watch.watchDir clientDir
  ]

# Task - compile coffeescripts and copy assets into `public/` directory
task 'build', 'compile coffeescripts and copy assets into public/ directory', ->
  logging.info "Building project..."
  watch.setEnv (opts.env ? 'development')
  fs.removeSync publicDir
  watch.compileDir clientDir

# Task - optimize js/css files (internal use only)
task 'optimize', 'optimize js/css files', ->
  watch.setEnv (opts.env ? 'development')
  fs.removeSync buildDir
  optimizer.optimizeDir publicDir, buildDir

# Task - minify and concatenate js/css files for production
task 'minify', 'minify and concatenate js/css files for production', ->
  logging.info "Preparing project files for production..."
  watch.setEnv (opts.env ? 'production')
  async.series [
    # Rebuild
    (done) ->
      if opts.cdn? and opts.cdn isnt ''
        p = spawn "#{__dirname}/../bin/muffin", ['build', '-e', 'production', '--cdn', opts.cdn]
      else
        p = spawn "#{__dirname}/../bin/muffin", ['build', '-e', 'production']
      p.stdout.on 'data', (data) -> logging.info data
      p.stderr.on 'data', (data) -> logging.error data
      p.on 'exit', done
    
    # Minify
    (done) ->
      p =  spawn "#{__dirname}/../bin/muffin", ['optimize', '-e', 'production']
      p.stdout.on 'data', (data) -> logging.info data
      p.stderr.on 'data', (data) -> logging.error data
      p.on 'exit', done
    
    # Remove temp directories
    (done) ->
      fs.removeSync publicDir
      fs.renameSync 'build', publicDir
      done(null)
    
    # Concatenate modules
    (done) ->
      for path in buildConfig.build
        logging.info "Concatenating module dependencies: #{path}"
        optimizer.concatDeps(path, buildConfig.paths)
      done(null)
    
    # Inline scripts
    (done) ->
      watch.inlineScriptsInDir publicDir
      done(null)
  ]

# Task - remove the `public/` directory
task 'clean', 'remove the public/ directory', ->
  fs.removeSync publicDir
  logging.warn "Removed the public/ directory."

# Task - run tests
task 'test', 'run tests', ->
  watch.setEnv (opts.env ? 'test')
  mocha = new Mocha
  mocha
    .reporter('spec')
    .ui('bdd')
    .growl()
  mocha.addFile './test/spec'
  mocha.run (failures) ->
    process.exit (if failures > 0 then 1 else 0)

# Task - generate documentation
task 'doc', 'generate documentation', ->
  found = findFileIn(clientDir)
  spawn "#{__dirname}/../node_modules/docco/bin/docco", found, {stdio: 'inherit'}

# Task - start the server and watch files
task 'server', 'start a webserver', ->
  watch.setEnv (opts.env ? 'development')
  fs.removeSync publicDir
  
  async.series [
    # Build
    (done) ->
      p = spawn "#{__dirname}/../bin/muffin", ['build']
      p.stdout.on 'data', (data) -> logging.info data
      p.stderr.on 'data', (data) -> logging.error data
      p.on 'exit', done
    
    # Dump versions.json, watch client dir, start server.
    (done) ->
      watch.watchDir clientDir
      
      if fs.existsSync(serverDir)
        watch.startAndWatchServer()
      else
        watch.startDummyServer()
  ]

# Task - deploy the app
task 'deploy', 'deploy the app', ->
  dest = opts.arguments[1]
  platforms = ['heroku', 'amazon', 'nodejitsu']
  unless dest and dest.toLowerCase() in platforms
    fatalError "Must choose a platform from the following: heroku, amazon, nodejitsu"
  
  switch dest.toLowerCase()
    when 'heroku'
      script =
      '''
        git checkout -b temp_branch_for_deployment
        cp -f .deploy-gitignore .gitignore
        muffin build
        git add .
        git commit -m"Commit for deployment"
        git push heroku temp_branch_for_deployment:master
        git checkout master
        git branch -D temp_branch_for_deployment
        heroku open
      '''
      script = script.replace /\n/g, '; '
      exec script, (err, stdout, stderr) ->
        logging.info stdout
        logging.error stderr

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

# Create new models/collections from templates
copyTemplate = (data, mapping) ->
  for from, to of mapping
    ejs = fs.readFileSync(sysPath.join(templatesDir, from)).toString()
    destDir = sysPath.dirname(to)
    fs.mkdirSync destDir
    
    _.templateSettings =
      evaluate    : /<\$([\s\S]+?)\$>/g,
      interpolate : /<\$=([\s\S]+?)\$>/g,
      escape      : /<\$-([\s\S]+?)\$>/g
    
    fs.writeFileSync to, _.template(ejs, data)
    logging.info " * Create #{to}"

# Inject code into file
injectIntoFile = (path, code, before, after) ->
  data = fs.readFileSync(path).toString()
  if before?
    index = data.indexOf(before)
    return if index is -1
  else if after?
    index = data.indexOf(after)
    return if index is -1
    index += after.length
  data = data[0...index] + code + data[index..]
  fs.writeFileSync path, data
  logging.info " * Update #{path}"

# Remove files
removeFiles = (files) ->
  _(files).each (file) ->
    fs.unlink file, (err) ->
      logging.info " * Removed #{file}" unless err

# Convenience for cleaner setTimeouts.
wait = (milliseconds, func) -> setTimeout func, milliseconds

# Print an error and exit.
fatalError = (message) ->
  logging.error message + '\n'
  process.exit 1

# Retrieve the model attributes
parseAttrs = (args) ->
  attrs = {}
  validTypes = ['String', 'Number', 'Date', 'Buffer', 'Boolean', 'Mixed', 'ObjectId', 'Array']
  for attr in args
    [key, value] = attr.split(':')
    if value then value = _(validTypes).find (type) -> type.toLowerCase() is value.toLowerCase()
    fatalError "Must supply a valid schema type for the attribute '#{key}'.\nValid types are: #{validTypes.join(', ')}." unless value?
    attrs[key] = value
  return attrs

# Print the `--help` usage message and exit.
usage = ->
  console.log optionParser.help()

# Print the `--version` message and exit.
version = ->
  json = JSON.parse(fs.readFileSync("#{__dirname}/../package.json"))
  console.log "Muffin version #{json.version}"