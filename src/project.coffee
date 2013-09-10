#
# Load project settings from config.json
#

fs = require 'fs'
sysPath = require 'path'
_ = require './utils/_inflection'
Generator = require('./PluginTypes/Generator')
Compiler = require('./PluginTypes/Compiler')
Optimizer = require("./PluginTypes/Optimizer")

class Project

  constructor: ->
    @clientConfig = {}
    @serverConfig = {}

    @requireConfig = {}
    @packageDeps = {}

    @muffinDir = sysPath.join(__dirname, '../')

    # Load config
    try
      @config = require sysPath.resolve('config.json')
      @parseConfig()
    catch e
      return

    @plugins = {'compilers': [], 'generators': [], 'optimizers': []}

    # Register mandatory plugins
    mandatoryPlugins = [
      'muffin-compiler-js'
      'muffin-compiler-html'
      'muffin-compiler-coffeescript'
      'muffin-compiler-appcache'
    ]
    @registerPlugin(name) for name in mandatoryPlugins

    # Register optional plugins
    @registerPlugin(name) for name in @config.plugins

  parseConfig: ->
    @clientDir = sysPath.resolve(@config.clientDir ? 'client')
    @serverDir = sysPath.resolve(@config.serverDir ? 'server')
    @buildDir = sysPath.resolve(@config.buildDir ? 'public')

    @clientAssetsDir = sysPath.join(@clientDir, 'assets')
    @clientComponentsDir = sysPath.join(@clientDir, 'components')

    @jsDir = sysPath.join(@buildDir, 'javascripts')
    @tempBuildDir = sysPath.resolve('.tmp-build')

  registerPlugin: (name) ->
    # Save the plugin in @plugins
    done = (plugin) =>
      switch plugin.type
        when 'compiler'
          @plugins['compilers'].push plugin
        when 'generator'
          @plugins['generators'].push plugin
        when 'optimizer'
          @plugins['optimizers'].push plugin

    pluginsEnv = {Generator, Compiler, Optimizer, project: @, _}

    # Search in Muffin's built-in plugins folder
    pluginPath = sysPath.join(__dirname, "../plugins/#{name}")
    try return require(pluginPath)(pluginsEnv, done)

    # Search in global node modules
    pluginPath = sysPath.join(__dirname, "../../#{name}")
    try return require(pluginPath)(pluginsEnv, done)

  setEnv: (env) ->
    @clientConfig = {env}
    config = {}
    try config = require sysPath.join(@clientDir, 'config.json')
    for key, value of config
      if key in ['development', 'production', 'test']
        if key is env
          _.extend @clientConfig, value
      else
        @clientConfig[key] = value

    @serverConfig = {env}
    config = {}
    try config = require sysPath.join(@serverDir, 'config.json')
    for key, value of config
      if key in ['development', 'production', 'test']
        if key is env
          _.extend @serverConfig, value
      else
        @serverConfig[key] = value

  buildRequireConfig: ->
    _aliases = @clientConfig.aliases
    _scripts = []
    _exports = {}

    isDirectory = (path) ->
      stats = fs.statSync(path)
      stats.isDirectory()

    # iterate over the components dir and get module deps
    users = fs.readdirSync(@clientComponentsDir)
    for user in users
      userDir = sysPath.join(@clientComponentsDir, user)
      if isDirectory(userDir)
        projects = fs.readdirSync(userDir)
        for p in projects
          projectDir = sysPath.join(userDir, p)
          if isDirectory(projectDir)
            # parse component.json
            json = fs.readFileSync(sysPath.join(projectDir, 'component.json'))
            json = JSON.parse(json)
            repo = "#{user}/#{p}"

            # Strip the .js or .coffee suffix
            if json.main
              indexFile = json.main.replace(/\.coffee$/, '').replace(/\.js$/, '')
            else
              indexFile = 'index'

            indexPath = "components/#{repo}/#{indexFile}"
            _aliases[json.name] = _aliases[repo] = indexPath

            if json.type is 'script'
              _scripts.push indexPath

            if json.exports
              _exports[indexPath] = json.exports

            if json.dependencies
              @packageDeps[repo] = Object.keys(json.dependencies)

    @requireConfig = {aliases: _aliases, scripts: _scripts, exports: _exports}

module.exports = new Project()
