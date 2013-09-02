jade = require 'jade'

module.exports = (env, callback) ->

  class JadeCompiler extends env.Compiler

    type: 'compiler'

    compile: ->
      # Compile Jade into html
      sourceData = fs.readFileSync(source).toString()
      filename = sysPath.basename(source, sysPath.extname(source)) + '.html'
      path = sysPath.join destDir, filename
      fn = jade.compile sourceData, {filename: source, compileDebug: false, pretty: true}
      html = fn()

      # Run through the template engine and write to the output file
      html = _.template(html, _.extend({}, {project.clientConfig}, helpers()))
      fs.writeFileSync path, html
      logging.info "compiled #{source}"

    helpers: ->
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

  callback(new JadeCompiler())
