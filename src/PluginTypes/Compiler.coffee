
class Compiler

  constructor:
    # Module loader source
    @moduleLoaderSrc = fs.readFileSync(sysPath.join(__dirname, 'client/module-loader.coffee')).toString()
    @moduleLoaderSrc = _.template(@moduleLoaderSrc, {settings: @clientConfig})
    @moduleLoaderSrc = CoffeeScript.compile(@moduleLoaderSrc)

    @liveReloadSrc = fs.readFileSync(sysPath.join(__dirname, 'client/live-reload.coffee')).toString()
    @liveReloadSrc = _.template(@liveReloadSrc, {settings: @clientConfig})
    @liveReloadSrc = CoffeeScript.compile(@liveReloadSrc)

    htmlHelpers =
      link_tag: (link, attrs={}) ->
        "<link href='#{project.clientConfig.assetHost}#{link}#{@cacheBuster(attrs.forceCacheBuster)}' #{("#{k}='#{v}'" for k, v of attrs).join(' ')}>"
      stylesheet_link_tag: (link, attrs={}) ->
        "<link rel='stylesheet' type='text/css' href='#{project.clientConfig.assetHost}#{link}#{@cacheBuster(attrs.forceCacheBuster)}' #{("#{k}='#{v}'" for k, v of attrs).join(' ')}>"
      script_tag: (src, attrs={}) ->
        "<script src='#{project.clientConfig.assetHost}#{src}#{@cacheBuster(attrs.forceCacheBuster)}' #{("#{k}='#{v}'" for k, v of attrs).join(' ')}></script>"
      image_tag: (src, attrs={}) ->
        "<img src='#{project.clientConfig.assetHost}#{src}#{@cacheBuster(attrs.forceCacheBuster)}' #{("#{k}='#{v}'" for k, v of attrs).join(' ')}>"
      include_module_loader: ->
        """
        <script>#{project.moduleLoaderSrc}</script>
        <script>require.config(#{JSON.stringify(project.requireConfig)})</script>
        """
      include_live_reload: ->
        """
        <script>#{project.liveReloadSrc}</script>
        """

  cacheBuster: (env, force) ->
    if env.project.clientConfig.cacheBuster or force
      "?_#{(new Date()).getTime()}"
    else
      ''

module.exports = Compiler
