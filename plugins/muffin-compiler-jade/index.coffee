fs = require 'fs'
sysPath = require 'path'
jade = require 'jade'

module.exports = (env, callback) ->

  class JadeCompiler extends env.Compiler

    extensions: ['.jade']

    constructor: ->
      @project = env.project

    destForFile: (source, destDir) ->
      filename = sysPath.basename(source, sysPath.extname(source)) + '.html'
      return sysPath.join(destDir, filename)

    compile: (source, destDir, callback) ->
      _ = env._

      # Compile Jade into html
      sourceData = fs.readFileSync(source).toString()
      filename = sysPath.basename(source, sysPath.extname(source)) + '.html'
      path = sysPath.join(destDir, filename)
      fn = jade.compile sourceData, {filename: source, compileDebug: false, pretty: true}
      html = fn()

      # Run through the template engine and write to the output file
      html = _.template(html, _.extend({}, {settings: env.project.clientConfig}, @project.htmlHelpers))
      fs.writeFileSync path, html
      callback(null, html)

  callback(new JadeCompiler())
