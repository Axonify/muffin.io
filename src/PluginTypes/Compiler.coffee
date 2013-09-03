fs = require 'fs'
sysPath = require 'path'
_ = require 'underscore'
CoffeeScript = require 'coffee-script'

class Compiler

  loadHtmlHelpers: ->
    # Underscore template settings
    _.templateSettings =
      evaluate    : /<\?([\s\S]+?)\?>/g,
      interpolate : /<\?=([\s\S]+?)\?>/g,
      escape      : /<\?-([\s\S]+?)\?>/g

    # Module loader source
    moduleLoaderSrc = fs.readFileSync(sysPath.join(__dirname, '../client/module-loader.coffee')).toString()
    moduleLoaderSrc = _.template(moduleLoaderSrc, {settings: @project.clientConfig})
    moduleLoaderSrc = CoffeeScript.compile(moduleLoaderSrc)

    liveReloadSrc = fs.readFileSync(sysPath.join(__dirname, '../client/live-reload.coffee')).toString()
    liveReloadSrc = _.template(liveReloadSrc, {settings: @project.clientConfig})
    liveReloadSrc = CoffeeScript.compile(liveReloadSrc)

    @htmlHelpers =
      link_tag: (link, attrs={}) =>
        "<link href='#{@project.clientConfig.assetHost}#{link}#{@cacheBuster(attrs.forceCacheBuster)}' #{("#{k}='#{v}'" for k, v of attrs).join(' ')}>"
      stylesheet_link_tag: (link, attrs={}) ->
        "<link rel='stylesheet' type='text/css' href='#{@project.clientConfig.assetHost}#{link}#{@cacheBuster(attrs.forceCacheBuster)}' #{("#{k}='#{v}'" for k, v of attrs).join(' ')}>"
      script_tag: (src, attrs={}) =>
        "<script src='#{@project.clientConfig.assetHost}#{src}#{@cacheBuster(attrs.forceCacheBuster)}' #{("#{k}='#{v}'" for k, v of attrs).join(' ')}></script>"
      image_tag: (src, attrs={}) =>
        "<img src='#{@project.clientConfig.assetHost}#{src}#{@cacheBuster(attrs.forceCacheBuster)}' #{("#{k}='#{v}'" for k, v of attrs).join(' ')}>"
      include_module_loader: =>
        """
        <script>#{moduleLoaderSrc}</script>
        <script>require.config(#{JSON.stringify(@project.requireConfig)})</script>
        """
      include_live_reload: =>
        """
        <script>#{liveReloadSrc}</script>
        """

  cacheBuster: (env, force) ->
    if @project.clientConfig.cacheBuster or force
      "?_#{(new Date()).getTime()}"
    else
      ''

  parseDeps: (content) ->
    commentRegex = /(\/\*([\s\S]*?)\*\/|([^:]|^)\/\/(.*)$)/mg
    cjsRequireRegex = /[^.]\s*require\s*\(\s*["']([^'"\s]+)["']\s*\)/g
    deps = []

    # Find all the require calls and push them into dependencies.
    content
      .replace(commentRegex, '') # remove comments
      .replace(cjsRequireRegex, (match, dep) -> deps.push(dep) if dep not in deps)
    deps

module.exports = Compiler
