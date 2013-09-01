sysPath = require 'path'
Generator = require(sysPath.join(__dirname, '../src/generator'))

class ClientGenerator extends Generator

  type: 'generator'
  templatesDir: './templates'

  generateModel: (model, app, opts) ->
    attrs = @parseAttrs(opts.arguments[3..])
    classified = _.classify(model)
    underscored = _.underscored(model)
    underscored_plural = _.underscored(_.pluralize(model))

    mapping =
      'models/model.coffee': "apps/#{app}/models/#{classified}.coffee"
      'models/collection.coffee': "apps/#{app}/models/#{classified}List.coffee"
    @copyTemplate {model, classified, underscored, underscored_plural, attrs, _}, mapping

  destroyModel: (model, app) ->
    classified = _.classify(model)
    files = [
      "apps/#{app}/models/#{classified}.coffee"
      "apps/#{app}/models/#{classified}List.coffee"
    ]
    @removeFiles(files)

  generateView: (view, app) ->
    mapping =
      'views/view.coffee': "apps/#{app}/views/#{_.classify(view)}.coffee"
      'templates/view.jade': "apps/#{app}/templates/#{_.classify(view)}.jade"
    @copyTemplate {view, _}, mapping

  destroyView: (view, app) ->
    files = [
      "apps/#{app}/views/#{_.classify(view)}.coffee"
      "apps/#{app}/templates/#{_.classify(view)}.jade"
    ]
    @removeFiles(files)

  generateScaffold: (model, app, opts) ->
    attrs = @parseAttrs(opts.arguments[3..])
    classified = _.classify(model)
    underscored = _.underscored(model)
    underscored_plural = _.underscored(_.pluralize(model))

    mapping =
      'models/model.coffee': "apps/#{app}/models/#{classified}.coffee"
      'models/collection.coffee': "apps/#{app}/models/#{classified}List.coffee"
      'views/index.coffee': "apps/#{app}/views/#{classified}IndexView.coffee"
      'templates/index.jade': "apps/#{app}/templates/#{classified}IndexView.jade"
      'templates/table.jade': "apps/#{app}/templates/#{classified}ListTable.jade"
      'views/show.coffee': "apps/#{app}/views/#{classified}ShowView.coffee"
      'templates/show.jade': "apps/#{app}/templates/#{classified}ShowView.jade"
      'views/new.coffee': "apps/#{app}/views/#{classified}NewView.coffee"
      'templates/new.jade': "apps/#{app}/templates/#{classified}NewView.jade"
      'views/edit.coffee': "apps/#{app}/views/#{classified}EditView.coffee"
      'templates/edit.jade': "apps/#{app}/templates/#{classified}EditView.jade"
    @copyTemplate {model, classified, underscored, underscored_plural, attrs, _}, mapping

    # Inject routes into client router
    _.templateSettings =
      evaluate    : /<\$([\s\S]+?)\$>/g,
      interpolate : /<\$=([\s\S]+?)\$>/g,
      escape      : /<\$-([\s\S]+?)\$>/g

    routes = fs.readFileSync(sysPath.join(templatesDir, 'router.coffee')).toString()
    lines = _.template(routes, {model, classified, underscored, underscored_plural, _}).split('\n')
    @injectIntoFile "apps/#{app}/router.coffee", '\n' + lines[0..4].join('\n') + '\n', null, "routes:"
    @injectIntoFile "apps/#{app}/router.coffee", lines[6..24].join('\n') + '\n\n', "module.exports", null

  destroyScaffold: (model, app) ->
    classified = _.classify(model)
    files = [
      "apps/#{app}/models/#{classified}.coffee"
      "apps/#{app}/models/#{classified}List.coffee"
      "apps/#{app}/views/#{classified}IndexView.coffee"
      "apps/#{app}/templates/#{classified}IndexView.jade"
      "apps/#{app}/templates/#{classified}ListTable.jade"
      "apps/#{app}/views/#{classified}ShowView.coffee"
      "apps/#{app}/templates/#{classified}ShowView.jade"
      "apps/#{app}/views/#{classified}NewView.coffee"
      "apps/#{app}/templates/#{classified}NewView.jade"
      "apps/#{app}/views/#{classified}EditView.coffee"
      "apps/#{app}/templates/#{classified}EditView.jade"
    ]
    @removeFiles(files)

module.exports = ClientGenerator
