# A Muffin plugin that handles HTML files.

fs = require 'fs'
sysPath = require 'path'

module.exports = (env, callback) ->

  class HtmlCompiler extends env.Compiler

    extensions: ['.html', '.htm']

    constructor: ->
      @project = env.project

    destForFile: (path, destDir) ->
      ext = sysPath.extname(path)
      filename = sysPath.basename(path, ext) + '.html'
      sysPath.join(destDir, filename)

    compile: (path, destDir, callback) ->
      _ = env._

      # Run the file through the template engine
      data = _.template(fs.readFileSync(path).toString(), _.extend({}, {settings: @project.clientConfig}, @project.htmlHelpers))

      # Write to dest
      dest = @destForFile(path, destDir)
      fs.writeFileSync dest, data
      callback(null, data)

  callback(new HtmlCompiler())
