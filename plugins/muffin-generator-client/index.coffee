# A Muffin plugin that generates client models and views.

fs = require 'fs'
sysPath = require 'path'

module.exports = (env, callback) ->

  class ClientGenerator extends env.Generator

    templatesDir: sysPath.join(__dirname, './templates')

    constructor: ->
      @project = env.project
      @clientDir = @project.clientDir

    generateModel: (model, app, args) ->
      # Rails-style inflection on the model name
      _ = env._
      classified = _.classify(model)
      underscored = _.underscored(model)
      underscored_plural = _.underscored(_.pluralize(model))

      # Parse args for model attributes
      attrs = @parseAttrs(args)

      # Mapping from template files to project files
      mapping =
        'models/model.coffee': "#{@clientDir}/apps/#{app}/models/#{classified}.coffee"
        'models/collection.coffee': "#{@clientDir}/apps/#{app}/models/#{classified}List.coffee"

      # Copy template files
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
      classified = _.classify(view)
      mapping =
        'views/view.coffee': "#{@clientDir}/apps/#{app}/views/#{classified}.coffee"
        'templates/view.html': "#{@clientDir}/apps/#{app}/templates/#{classified}.html"
      @copyTemplate {view, classified, _}, mapping

    destroyView: (view, app) ->
      _ = env._
      classified = _.classify(view)
      files = [
        "#{@clientDir}/apps/#{app}/views/#{classified}.coffee"
        "#{@clientDir}/apps/#{app}/templates/#{classified}.html"
      ]
      @removeFiles(files)

    generateScaffold: (model, app, args) ->
      # Rails-style inflection on the model name
      _ = env._
      classified = _.classify(model)
      underscored = _.underscored(model)
      underscored_plural = _.underscored(_.pluralize(model))

      # Parse args for model attributes
      attrs = @parseAttrs(args)

      # Mapping from template files to project files
      mapping =
        'models/model.coffee': "#{@clientDir}/apps/#{app}/models/#{classified}.coffee"
        'models/collection.coffee': "#{@clientDir}/apps/#{app}/models/#{classified}List.coffee"
        'views/index.coffee': "#{@clientDir}/apps/#{app}/views/#{classified}IndexView.coffee"
        'templates/index.html': "#{@clientDir}/apps/#{app}/templates/#{classified}IndexView.html"
        'templates/table.html': "#{@clientDir}/apps/#{app}/templates/#{classified}ListTable.html"
        'views/show.coffee': "#{@clientDir}/apps/#{app}/views/#{classified}ShowView.coffee"
        'templates/show.html': "#{@clientDir}/apps/#{app}/templates/#{classified}ShowView.html"
        'views/new.coffee': "#{@clientDir}/apps/#{app}/views/#{classified}NewView.coffee"
        'templates/new.html': "#{@clientDir}/apps/#{app}/templates/#{classified}NewView.html"
        'views/edit.coffee': "#{@clientDir}/apps/#{app}/views/#{classified}EditView.coffee"
        'templates/edit.html': "#{@clientDir}/apps/#{app}/templates/#{classified}EditView.html"
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
        "#{@clientDir}/apps/#{app}/templates/#{classified}IndexView.html"
        "#{@clientDir}/apps/#{app}/templates/#{classified}ListTable.html"
        "#{@clientDir}/apps/#{app}/views/#{classified}ShowView.coffee"
        "#{@clientDir}/apps/#{app}/templates/#{classified}ShowView.html"
        "#{@clientDir}/apps/#{app}/views/#{classified}NewView.coffee"
        "#{@clientDir}/apps/#{app}/templates/#{classified}NewView.html"
        "#{@clientDir}/apps/#{app}/views/#{classified}EditView.coffee"
        "#{@clientDir}/apps/#{app}/templates/#{classified}EditView.html"
      ]
      @removeFiles(files)

  callback(new ClientGenerator())
