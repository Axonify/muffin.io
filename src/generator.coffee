fs = require 'fs-extra'
sysPath = require 'path'
_ = require './utils/_inflection'

class Generator

  constructor: ->
    @templatesDir = sysPath.resolve('templates')

  generateModel: (model, app, opts) ->
    attrs = @parseAttrs(opts.arguments[3..])
    classified = _.classify(model)
    underscored = _.underscored(model)
    underscored_plural = _.underscored(_.pluralize(model))

    mapping =
      'client/models/model.coffee': "client/apps/#{app}/models/#{classified}.coffee"
      'client/models/collection.coffee': "client/apps/#{app}/models/#{classified}List.coffee"
      'server/models/model.coffee': "server/apps/#{app}/models/#{classified}.coffee"
      'server/controllers/controller.coffee': "server/apps/#{app}/controllers/#{classified}Controller.coffee"
    @copyTemplate {model, classified, underscored, underscored_plural, attrs, _}, mapping

  destroyModel: (model, app) ->
    classified = _.classify(model)
    files = [
      "client/apps/#{app}/models/#{classified}.coffee"
      "client/apps/#{app}/models/#{classified}List.coffee"
      "server/apps/#{app}/models/#{classified}.coffee"
      "server/apps/#{app}/controllers/#{classified}Controller.coffee"
    ]
    @removeFiles(files)

  generateView: (view, app) ->
    mapping =
      'client/views/view.coffee': "client/apps/#{app}/views/#{_.classify(view)}.coffee"
      'client/templates/view.jade': "client/apps/#{app}/templates/#{_.classify(view)}.jade"
    @copyTemplate {view, _}, mapping

  destroyView: (view, app) ->
    files = [
      "client/apps/#{app}/views/#{_.classify(view)}.coffee"
      "client/apps/#{app}/templates/#{_.classify(view)}.jade"
    ]
    @removeFiles(files)

  generateScaffold: (model, app, opts) ->
    attrs = @parseAttrs(opts.arguments[3..])
    classified = _.classify(model)
    underscored = _.underscored(model)
    underscored_plural = _.underscored(_.pluralize(model))

    mapping =
      'client/models/model.coffee': "client/apps/#{app}/models/#{classified}.coffee"
      'client/models/collection.coffee': "client/apps/#{app}/models/#{classified}List.coffee"
      'client/views/index.coffee': "client/apps/#{app}/views/#{classified}IndexView.coffee"
      'client/templates/index.jade': "client/apps/#{app}/templates/#{classified}IndexView.jade"
      'client/templates/table.jade': "client/apps/#{app}/templates/#{classified}ListTable.jade"
      'client/views/show.coffee': "client/apps/#{app}/views/#{classified}ShowView.coffee"
      'client/templates/show.jade': "client/apps/#{app}/templates/#{classified}ShowView.jade"
      'client/views/new.coffee': "client/apps/#{app}/views/#{classified}NewView.coffee"
      'client/templates/new.jade': "client/apps/#{app}/templates/#{classified}NewView.jade"
      'client/views/edit.coffee': "client/apps/#{app}/views/#{classified}EditView.coffee"
      'client/templates/edit.jade': "client/apps/#{app}/templates/#{classified}EditView.jade"
      'server/models/model.coffee': "server/apps/#{app}/models/#{classified}.coffee"
      'server/controllers/controller.coffee': "server/apps/#{app}/controllers/#{classified}Controller.coffee"
    @copyTemplate {model, classified, underscored, underscored_plural, attrs, _}, mapping

    # Inject routes into client router
    _.templateSettings =
      evaluate    : /<\$([\s\S]+?)\$>/g,
      interpolate : /<\$=([\s\S]+?)\$>/g,
      escape      : /<\$-([\s\S]+?)\$>/g

    routes = fs.readFileSync(sysPath.join(templatesDir, 'client/router.coffee')).toString()
    lines = _.template(routes, {model, classified, underscored, underscored_plural, _}).split('\n')
    @injectIntoFile "client/apps/#{app}/router.coffee", '\n' + lines[0..4].join('\n') + '\n', null, "routes:"
    @injectIntoFile "client/apps/#{app}/router.coffee", lines[6..24].join('\n') + '\n\n', "module.exports", null

    # Inject routes into server router
    routes = fs.readFileSync(sysPath.join(templatesDir, 'server/router.coffee')).toString()
    lines = _.template(routes, {model, classified, underscored, underscored_plural, _}).split('\n')
    @injectIntoFile "server/apps/#{app}/router.coffee", lines[0] + '\n\n', "# Router", null
    @injectIntoFile "server/apps/#{app}/router.coffee", lines[2..7].join('\n') + '\n\n', "module.exports", null

  destroyScaffold: (model, app) ->
    classified = _.classify(model)
    files = [
      "client/apps/#{app}/models/#{classified}.coffee"
      "client/apps/#{app}/models/#{classified}List.coffee"
      "client/apps/#{app}/views/#{classified}IndexView.coffee"
      "client/apps/#{app}/templates/#{classified}IndexView.jade"
      "client/apps/#{app}/templates/#{classified}ListTable.jade"
      "client/apps/#{app}/views/#{classified}ShowView.coffee"
      "client/apps/#{app}/templates/#{classified}ShowView.jade"
      "client/apps/#{app}/views/#{classified}NewView.coffee"
      "client/apps/#{app}/templates/#{classified}NewView.jade"
      "client/apps/#{app}/views/#{classified}EditView.coffee"
      "client/apps/#{app}/templates/#{classified}EditView.jade"
      "server/apps/#{app}/models/#{classified}.coffee"
      "server/apps/#{app}/controllers/#{classified}Controller.coffee"
    ]
    @removeFiles(files)

  # Create new models/collections from templates
  copyTemplate: (data, mapping) ->
    for from, to of mapping
      ejs = fs.readFileSync(sysPath.join(templatesDir, from)).toString()
      destDir = sysPath.dirname(to)
      fs.mkdirSync destDir

      _.templateSettings =
        evaluate    : /<\$([\s\S]+?)\$>/g,
        interpolate : /<\$=([\s\S]+?)\$>/g,
        escape      : /<\$-([\s\S]+?)\$>/g

      fs.writeFileSync to, _.template(ejs, data)
      logging.info " * Create #{to}"

  # Inject code into file
  injectIntoFile: (path, code, before, after) ->
    data = fs.readFileSync(path).toString()
    if before?
      index = data.indexOf(before)
      return if index is -1
    else if after?
      index = data.indexOf(after)
      return if index is -1
      index += after.length
    data = data[0...index] + code + data[index..]
    fs.writeFileSync path, data
    logging.info " * Update #{path}"

  # Remove files
  removeFiles: (files) ->
    _(files).each (file) ->
      fs.unlink file, (err) ->
        logging.info " * Removed #{file}" unless err

  # Retrieve the model attributes
  parseAttrs: (args) ->
    attrs = {}
    validTypes = ['String', 'Number', 'Date', 'Buffer', 'Boolean', 'Mixed', 'ObjectId', 'Array']
    for attr in args
      [key, value] = attr.split(':')
      if value then value = _(validTypes).find (type) -> type.toLowerCase() is value.toLowerCase()
      utils.fatal "Must supply a valid schema type for the attribute '#{key}'.\nValid types are: #{validTypes.join(', ')}." unless value?
      attrs[key] = value
    return attrs

module.exports = new Generator()
