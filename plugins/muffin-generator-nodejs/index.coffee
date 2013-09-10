sysPath = require 'path'

module.exports = (env, callback) ->

  class NodeJSGenerator extends env.Generator

    templatesDir: sysPath.join(__dirname, './templates')

    generateModel: (model, app, opts) ->
      _ = env._
      attrs = @parseAttrs(opts.arguments[3..])
      classified = _.classify(model)
      underscored = _.underscored(model)
      underscored_plural = _.underscored(_.pluralize(model))

      mapping =
        'models/model.coffee': "#{env.project.serverDir}/apps/#{app}/models/#{classified}.coffee"
        'controllers/controller.coffee': "#{env.project.serverDir}/apps/#{app}/controllers/#{classified}Controller.coffee"
      @copyTemplate {model, classified, underscored, underscored_plural, attrs, _}, mapping

    destroyModel: (model, app) ->
      _ = env._
      classified = _.classify(model)
      files = [
        "#{env.project.serverDir}/apps/#{app}/models/#{classified}.coffee"
        "#{env.project.serverDir}/apps/#{app}/controllers/#{classified}Controller.coffee"
      ]
      @removeFiles(files)

    generateScaffold: (model, app, opts) ->
      _ = env._
      attrs = @parseAttrs(opts.arguments[3..])
      classified = _.classify(model)
      underscored = _.underscored(model)
      underscored_plural = _.underscored(_.pluralize(model))

      mapping =
        'models/model.coffee': "#{env.project.serverDir}/apps/#{app}/models/#{classified}.coffee"
        'controllers/controller.coffee': "#{env.project.serverDir}/apps/#{app}/controllers/#{classified}Controller.coffee"
      @copyTemplate {model, classified, underscored, underscored_plural, attrs, _}, mapping

      # Inject routes into server router
      _.templateSettings =
        evaluate    : /<\$([\s\S]+?)\$>/g,
        interpolate : /<\$=([\s\S]+?)\$>/g,
        escape      : /<\$-([\s\S]+?)\$>/g

      routes = fs.readFileSync(sysPath.join(templatesDir, 'router.coffee')).toString()
      lines = _.template(routes, {model, classified, underscored, underscored_plural, _}).split('\n')
      @injectIntoFile "#{env.project.serverDir}/apps/#{app}/router.coffee", lines[0] + '\n\n', "# Router", null
      @injectIntoFile "#{env.project.serverDir}/apps/#{app}/router.coffee", lines[2..7].join('\n') + '\n\n', "module.exports", null

    destroyScaffold: (model, app) ->
      _ = env._
      classified = _.classify(model)
      files = [
        "#{env.project.serverDir}/apps/#{app}/models/#{classified}.coffee"
        "#{env.project.serverDir}/apps/#{app}/controllers/#{classified}Controller.coffee"
      ]
      @removeFiles(files)

  callback(new NodeJSGenerator())
