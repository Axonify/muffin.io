sysPath = require 'path'

module.exports = (env, callback) ->

  class ClientGenerator extends env.Generator

    type: 'generator'
    templatesDir: sysPath.join(__dirname, './templates')

    generateModel: (model, app, opts) ->
      attrs = @parseAttrs(opts.arguments[3..])
      classified = _.classify(model)
      underscored = _.underscored(model)
      underscored_plural = _.underscored(_.pluralize(model))

      mapping =
        'models/model.coffee': "#{env.project.clientDir}/apps/#{app}/models/#{classified}.coffee"
        'models/collection.coffee': "#{env.project.clientDir}/apps/#{app}/models/#{classified}List.coffee"
      @copyTemplate {model, classified, underscored, underscored_plural, attrs, _}, mapping

    destroyModel: (model, app) ->
      classified = _.classify(model)
      files = [
        "#{env.project.clientDir}/apps/#{app}/models/#{classified}.coffee"
        "#{env.project.clientDir}/apps/#{app}/models/#{classified}List.coffee"
      ]
      @removeFiles(files)

    generateView: (view, app) ->
      mapping =
        'views/view.coffee': "#{env.project.clientDir}/apps/#{app}/views/#{_.classify(view)}.coffee"
        'templates/view.jade': "#{env.project.clientDir}/apps/#{app}/templates/#{_.classify(view)}.jade"
      @copyTemplate {view, _}, mapping

    destroyView: (view, app) ->
      files = [
        "#{env.project.clientDir}/apps/#{app}/views/#{_.classify(view)}.coffee"
        "#{env.project.clientDir}/apps/#{app}/templates/#{_.classify(view)}.jade"
      ]
      @removeFiles(files)

    generateScaffold: (model, app, opts) ->
      attrs = @parseAttrs(opts.arguments[3..])
      classified = _.classify(model)
      underscored = _.underscored(model)
      underscored_plural = _.underscored(_.pluralize(model))

      mapping =
        'models/model.coffee': "#{env.project.clientDir}/apps/#{app}/models/#{classified}.coffee"
        'models/collection.coffee': "#{env.project.clientDir}/apps/#{app}/models/#{classified}List.coffee"
        'views/index.coffee': "#{env.project.clientDir}/apps/#{app}/views/#{classified}IndexView.coffee"
        'templates/index.jade': "#{env.project.clientDir}/apps/#{app}/templates/#{classified}IndexView.jade"
        'templates/table.jade': "#{env.project.clientDir}/apps/#{app}/templates/#{classified}ListTable.jade"
        'views/show.coffee': "#{env.project.clientDir}/apps/#{app}/views/#{classified}ShowView.coffee"
        'templates/show.jade': "#{env.project.clientDir}/apps/#{app}/templates/#{classified}ShowView.jade"
        'views/new.coffee': "#{env.project.clientDir}/apps/#{app}/views/#{classified}NewView.coffee"
        'templates/new.jade': "#{env.project.clientDir}/apps/#{app}/templates/#{classified}NewView.jade"
        'views/edit.coffee': "#{env.project.clientDir}/apps/#{app}/views/#{classified}EditView.coffee"
        'templates/edit.jade': "#{env.project.clientDir}/apps/#{app}/templates/#{classified}EditView.jade"
      @copyTemplate {model, classified, underscored, underscored_plural, attrs, _}, mapping

      # Inject routes into client router
      _.templateSettings =
        evaluate    : /<\$([\s\S]+?)\$>/g,
        interpolate : /<\$=([\s\S]+?)\$>/g,
        escape      : /<\$-([\s\S]+?)\$>/g

      routes = fs.readFileSync(sysPath.join(@templatesDir, 'router.coffee')).toString()
      lines = _.template(routes, {model, classified, underscored, underscored_plural, _}).split('\n')
      @injectIntoFile "#{env.project.clientDir}/apps/#{app}/router.coffee", '\n' + lines[0..4].join('\n') + '\n', null, "routes:"
      @injectIntoFile "#{env.project.clientDir}/apps/#{app}/router.coffee", lines[6..24].join('\n') + '\n\n', "module.exports", null

    destroyScaffold: (model, app) ->
      classified = _.classify(model)
      files = [
        "#{env.project.clientDir}/apps/#{app}/models/#{classified}.coffee"
        "#{env.project.clientDir}/apps/#{app}/models/#{classified}List.coffee"
        "#{env.project.clientDir}/apps/#{app}/views/#{classified}IndexView.coffee"
        "#{env.project.clientDir}/apps/#{app}/templates/#{classified}IndexView.jade"
        "#{env.project.clientDir}/apps/#{app}/templates/#{classified}ListTable.jade"
        "#{env.project.clientDir}/apps/#{app}/views/#{classified}ShowView.coffee"
        "#{env.project.clientDir}/apps/#{app}/templates/#{classified}ShowView.jade"
        "#{env.project.clientDir}/apps/#{app}/views/#{classified}NewView.coffee"
        "#{env.project.clientDir}/apps/#{app}/templates/#{classified}NewView.jade"
        "#{env.project.clientDir}/apps/#{app}/views/#{classified}EditView.coffee"
        "#{env.project.clientDir}/apps/#{app}/templates/#{classified}EditView.jade"
      ]
      @removeFiles(files)

  callback(new ClientGenerator())
