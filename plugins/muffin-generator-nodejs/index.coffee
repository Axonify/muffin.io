sysPath = require 'path'
fs = require 'fs'

module.exports = (env, callback) ->

  class NodeJSGenerator extends env.Generator

    templatesDir: sysPath.join(__dirname, './templates')

    constructor: ->
      @project = env.project
      @serverDir = @project.serverDir

    generateModel: (model, app, args) ->
      _ = env._
      attrs = @parseAttrs(args)
      classified = _.classify(model)
      underscored = _.underscored(model)
      underscored_plural = _.underscored(_.pluralize(model))

      mapping =
        'models/model.coffee': "#{@serverDir}/apps/#{app}/models/#{classified}.coffee"
        'controllers/controller.coffee': "#{@serverDir}/apps/#{app}/controllers/#{classified}Controller.coffee"
      @copyTemplate {model, classified, underscored, underscored_plural, attrs, _}, mapping

    destroyModel: (model, app) ->
      _ = env._
      classified = _.classify(model)
      files = [
        "#{@serverDir}/apps/#{app}/models/#{classified}.coffee"
        "#{@serverDir}/apps/#{app}/controllers/#{classified}Controller.coffee"
      ]
      @removeFiles(files)

    generateScaffold: (model, app, args) ->
      _ = env._
      attrs = @parseAttrs(args)
      classified = _.classify(model)
      underscored = _.underscored(model)
      underscored_plural = _.underscored(_.pluralize(model))

      mapping =
        'models/model.coffee': "#{@serverDir}/apps/#{app}/models/#{classified}.coffee"
        'controllers/controller.coffee': "#{@serverDir}/apps/#{app}/controllers/#{classified}Controller.coffee"
      @copyTemplate {model, classified, underscored, underscored_plural, attrs, _}, mapping

      # Inject routes into server router
      _.templateSettings =
        evaluate    : /<\$([\s\S]+?)\$>/g,
        interpolate : /<\$=([\s\S]+?)\$>/g,
        escape      : /<\$-([\s\S]+?)\$>/g

      routes = fs.readFileSync(sysPath.join(@templatesDir, 'router.coffee')).toString()
      lines = _.template(routes, {model, classified, underscored, underscored_plural, _}).split('\n')
      @injectIntoFile "#{@serverDir}/apps/#{app}/router.coffee", lines[0] + '\n\n', "# Router", null
      @injectIntoFile "#{@serverDir}/apps/#{app}/router.coffee", lines[2..7].join('\n') + '\n\n', "module.exports", null

    destroyScaffold: (model, app) ->
      _ = env._
      classified = _.classify(model)
      files = [
        "#{@serverDir}/apps/#{app}/models/#{classified}.coffee"
        "#{@serverDir}/apps/#{app}/controllers/#{classified}Controller.coffee"
      ]
      @removeFiles(files)

  callback(new NodeJSGenerator())
