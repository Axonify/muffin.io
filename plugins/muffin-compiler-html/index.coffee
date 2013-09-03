fs = require 'fs'
sysPath = require 'path'
_ = require 'underscore'

module.exports = (env, callback) ->

  class HtmlCompiler extends env.Compiler

    type: 'compiler'
    extensions: ['.html', '.htm']

    constructor: ->
      @project = env.project
      @loadHtmlHelpers()

    destForFile: (source, destDir) ->
      filename = sysPath.basename(source, sysPath.extname(source)) + '.html'
      return sysPath.join(destDir, filename)

    compile: (source, destDir, callback) ->
      # Run the source file through template engine
      sourceData = _.template(fs.readFileSync(source).toString(), _.extend({}, {settings: @project.clientConfig}, @htmlHelpers))
      filename = sysPath.basename(source)
      path = sysPath.join(destDir, filename)
      fs.writeFileSync(path, sourceData)
      callback(null, sourceData)

  callback(new HtmlCompiler())
