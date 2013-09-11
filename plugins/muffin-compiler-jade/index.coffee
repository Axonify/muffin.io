# A Muffin plugin that compiles Jade files into HTML files.

fs = require 'fs'
sysPath = require 'path'
jade = require 'jade'

module.exports = (env, callback) ->

  class JadeCompiler extends env.Compiler

    extensions: ['.jade']

    constructor: ->
      @project = env.project

    destForFile: (path, destDir) ->
      ext = sysPath.extname(path)
      filename = sysPath.basename(path, ext) + '.html'
      sysPath.join(destDir, filename)

    compile: (path, destDir, callback) ->
      _ = env._

      # Read the source file
      data = fs.readFileSync(path).toString()

      # Compile Jade into html
      fn = jade.compile data, {filename: path, compileDebug: false, pretty: true}
      html = fn()

      # Run the file through the template engine
      html = _.template(html, _.extend({}, {settings: @project.clientConfig}, @project.htmlHelpers))

      # Write to dest
      dest = @destForFile(path, destDir)
      fs.writeFileSync dest, html
      callback(null, html)

  callback(new JadeCompiler())
