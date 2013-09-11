fs = require 'fs'
sysPath = require 'path'

module.exports = (env, callback) ->

  class ClientGenerator extends env.Generator

    templatesDir: sysPath.join(__dirname, './templates')

    constructor: ->
      @project = env.project
      @clientDir = @project.clientDir

    generateModel: (model, app, args) ->
      _ = env._
      attrs = @parseAttrs(args)
      classified = _.classify(model)
      underscored = _.underscored(model)
      underscored_plural = _.underscored(_.pluralize(model))

      mapping =
        'models/model.coffee': "#{@clientDir}/apps/#{app}/models/#{classified}.coffee"
        'models/collection.coffee': "#{@clientDir}/apps/#{app}/models/#{classified}List.coffee"
      @copyTemplate {model, classified, underscored, underscored_plural, attrs, _}, mapping

    destroyModel: (model, app) ->
      _ = env._
      classified = _.classify(model)
      files = [
        "#{@clientDir}/apps/#{app}/models/#{classified}.coffee"
        "#{@clientDir}/apps/#{app}/models/#{classified}List.coffee"
      ]
      @removeFiles(files)

    generateView: (view, app) ->
      _ = env._
      mapping =
        'views/view.coffee': "#{@clientDir}/apps/#{app}/views/#{_.classify(view)}.coffee"
        'templates/view.jade': "#{@clientDir}/apps/#{app}/templates/#{_.classify(view)}.jade"
      @copyTemplate {view, _}, mapping

    destroyView: (view, app) ->
      _ = env._
      files = [
        "#{@clientDir}/apps/#{app}/views/#{_.classify(view)}.coffee"
        "#{@clientDir}/apps/#{app}/templates/#{_.classify(view)}.jade"
      ]
      @removeFiles(files)

    generateScaffold: (model, app, args) ->
      _ = env._
      attrs = @parseAttrs(args)
      classified = _.classify(model)
      underscored = _.underscored(model)
      underscored_plural = _.underscored(_.pluralize(model))

      mapping =
        'models/model.coffee': "#{@clientDir}/apps/#{app}/models/#{classified}.coffee"
        'models/collection.coffee': "#{@clientDir}/apps/#{app}/models/#{classified}List.coffee"
        'views/index.coffee': "#{@clientDir}/apps/#{app}/views/#{classified}IndexView.coffee"
        'templates/index.jade': "#{@clientDir}/apps/#{app}/templates/#{classified}IndexView.jade"
        'templates/table.jade': "#{@clientDir}/apps/#{app}/templates/#{classified}ListTable.jade"
        'views/show.coffee': "#{@clientDir}/apps/#{app}/views/#{classified}ShowView.coffee"
        'templates/show.jade': "#{@clientDir}/apps/#{app}/templates/#{classified}ShowView.jade"
        'views/new.coffee': "#{@clientDir}/apps/#{app}/views/#{classified}NewView.coffee"
        'templates/new.jade': "#{@clientDir}/apps/#{app}/templates/#{classified}NewView.jade"
        'views/edit.coffee': "#{@clientDir}/apps/#{app}/views/#{classified}EditView.coffee"
        'templates/edit.jade': "#{@clientDir}/apps/#{app}/templates/#{classified}EditView.jade"
      @copyTemplate {model, classified, underscored, underscored_plural, attrs, _}, mapping

      # Inject routes into client router
      _.templateSettings =
        evaluate    : /<\$([\s\S]+?)\$>/g,
        interpolate : /<\$=([\s\S]+?)\$>/g,
        escape      : /<\$-([\s\S]+?)\$>/g

      routes = fs.readFileSync(sysPath.join(@templatesDir, 'router.coffee')).toString()
      lines = _.template(routes, {model, classified, underscored, underscored_plural, _}).split('\n')
      @injectIntoFile "#{@clientDir}/apps/#{app}/router.coffee", '\n' + lines[0..4].join('\n') + '\n', null, "routes:"
      @injectIntoFile "#{@clientDir}/apps/#{app}/router.coffee", lines[6..24].join('\n') + '\n\n', "module.exports", null

    destroyScaffold: (model, app) ->
      _ = env._
      classified = _.classify(model)
      files = [
        "#{@clientDir}/apps/#{app}/models/#{classified}.coffee"
        "#{@clientDir}/apps/#{app}/models/#{classified}List.coffee"
        "#{@clientDir}/apps/#{app}/views/#{classified}IndexView.coffee"
        "#{@clientDir}/apps/#{app}/templates/#{classified}IndexView.jade"
        "#{@clientDir}/apps/#{app}/templates/#{classified}ListTable.jade"
        "#{@clientDir}/apps/#{app}/views/#{classified}ShowView.coffee"
        "#{@clientDir}/apps/#{app}/templates/#{classified}ShowView.jade"
        "#{@clientDir}/apps/#{app}/views/#{classified}NewView.coffee"
        "#{@clientDir}/apps/#{app}/templates/#{classified}NewView.jade"
        "#{@clientDir}/apps/#{app}/views/#{classified}EditView.coffee"
        "#{@clientDir}/apps/#{app}/templates/#{classified}EditView.jade"
      ]
      @removeFiles(files)

  callback(new ClientGenerator())
