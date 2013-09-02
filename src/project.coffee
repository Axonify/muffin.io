#
# Load project settings from config.json
#

fs = require 'fs'
sysPath = require 'path'
CoffeeScript = require 'coffee-script'

pluginsEnv =
  Generator: require('./PluginTypes/Generator')
  Compiler: require('./PluginTypes/Compiler')
  Optimizer: require("./PluginTypes/Optimizer")

class Project

  constructor: ->
    @clientConfig = {}
    @serverConfig = {}

    @requireConfig = {}
    @packageDeps = {}

    # Load config
    try @config = require sysPath.resolve('config.json')
    @parseConfig() if @config

    # Register plugins
    @plugins = []
    @registerPlugins()

  parseConfig: ->
    @muffinDir = sysPath.join(__dirname, '../')

    @clientDir = sysPath.resolve(@config.clientDir ? 'client')
    @serverDir = sysPath.resolve(@config.serverDir ? 'server')
    @buildDir = sysPath.resolve(@config.buildDir ? 'public')

    @clientAssetsDir = sysPath.join(@clientDir, 'assets')
    @clientComponentsDir = sysPath.join(@clientDir, 'components')

    @jsDir = sysPath.join(@buildDir, 'javascripts')
    @tempBuildDir = sysPath.resolve('.tmp-build')

  registerPlugins: ->
    # Register plugins listed in config.json
    for name in @config?.plugins
      @registerPlugin(name)

  registerPlugin: (name) ->
    # Search in the plugins folder
    pluginPath = sysPath.join('../plugins', name)
    done = (plugin) -> @plugins.push plugin
    require(pluginPath)(pluginsEnv, done)

    # Search in global node modules
    pluginPath = sysPath.join(__dirname, "../../#{name}")
    require(pluginPath)(pluginsEnv, done)

  setEnv: (env, opts) ->
    @clientConfig = {env}
    config = {}
    try config = require sysPath.join(@clientDir, 'config.json')
    for key, value of config
      if key in ['development', 'production', 'test']
        if key is env
          _.extend @clientConfig, value
      else
        @clientConfig[key] = value
    @clientConfig.assetHost = opts.cdn ? ''
    @clientConfig.version = opts.hash ? '1.0.0'

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

    # iterate over the components dir and get module deps
    users = fs.readdirSync(project.clientComponentsDir)
    for user in users
      userDir = sysPath.join(project.clientComponentsDir, user)
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

  loadClientSources: ->
    # Module loader source
    @moduleLoaderSrc = fs.readFileSync(sysPath.join(__dirname, 'client/module-loader.coffee')).toString()
    @moduleLoaderSrc = _.template(@moduleLoaderSrc, {@clientConfig})
    @moduleLoaderSrc = CoffeeScript.compile(@moduleLoaderSrc)

    @liveReloadSrc = fs.readFileSync(sysPath.join(__dirname, 'client/live-reload.coffee')).toString()
    @liveReloadSrc = _.template(@liveReloadSrc, {@clientConfig})
    @liveReloadSrc = CoffeeScript.compile(@liveReloadSrc)

module.exports = new Project()
