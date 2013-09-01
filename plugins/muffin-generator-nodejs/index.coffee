sysPath = require 'path'
Generator = require(sysPath.join(__dirname, '../src/generator'))

class NodeJSGenerator extends Generator

  type: 'generator'
  templatesDir: './templates'

  generateModel: (model, app, opts) ->
    attrs = @parseAttrs(opts.arguments[3..])
    classified = _.classify(model)
    underscored = _.underscored(model)
    underscored_plural = _.underscored(_.pluralize(model))

    mapping =
      'models/model.coffee': "apps/#{app}/models/#{classified}.coffee"
      'controllers/controller.coffee': "apps/#{app}/controllers/#{classified}Controller.coffee"
    @copyTemplate {model, classified, underscored, underscored_plural, attrs, _}, mapping

  destroyModel: (model, app) ->
    classified = _.classify(model)
    files = [
      "apps/#{app}/models/#{classified}.coffee"
      "apps/#{app}/controllers/#{classified}Controller.coffee"
    ]
    @removeFiles(files)

  generateScaffold: (model, app, opts) ->
    attrs = @parseAttrs(opts.arguments[3..])
    classified = _.classify(model)
    underscored = _.underscored(model)
    underscored_plural = _.underscored(_.pluralize(model))

    mapping =
      'models/model.coffee': "apps/#{app}/models/#{classified}.coffee"
      'controllers/controller.coffee': "apps/#{app}/controllers/#{classified}Controller.coffee"
    @copyTemplate {model, classified, underscored, underscored_plural, attrs, _}, mapping

    # Inject routes into server router
    _.templateSettings =
      evaluate    : /<\$([\s\S]+?)\$>/g,
      interpolate : /<\$=([\s\S]+?)\$>/g,
      escape      : /<\$-([\s\S]+?)\$>/g

    routes = fs.readFileSync(sysPath.join(templatesDir, 'router.coffee')).toString()
    lines = _.template(routes, {model, classified, underscored, underscored_plural, _}).split('\n')
    @injectIntoFile "apps/#{app}/router.coffee", lines[0] + '\n\n', "# Router", null
    @injectIntoFile "apps/#{app}/router.coffee", lines[2..7].join('\n') + '\n\n', "module.exports", null

  destroyScaffold: (model, app) ->
    classified = _.classify(model)
    files = [
      "apps/#{app}/models/#{classified}.coffee"
      "apps/#{app}/controllers/#{classified}Controller.coffee"
    ]
    @removeFiles(files)

module.exports = NodeJSGenerator
