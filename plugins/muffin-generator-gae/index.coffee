# A Muffin plugin that generates GAE models and controllers.

fs = require 'fs'
sysPath = require 'path'

module.exports = (env, callback) ->

  class GAEGenerator extends env.Generator

    templatesDir: sysPath.join(__dirname, './templates')

    constructor: ->
      @project = env.project
      @serverDir = @project.serverDir

    generateModel: (model, app, args) -> {}

    destroyModel: (model, app) -> {}

    generateScaffold: (model, app, args) -> {}

    destroyScaffold: (model, app) -> {}

  callback(new GAEGenerator())
