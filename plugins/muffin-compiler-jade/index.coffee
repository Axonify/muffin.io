fs = require 'fs'
sysPath = require 'path'
_ = require 'underscore'
jade = require 'jade'

module.exports = (env, callback) ->

  class JadeCompiler extends env.Compiler

    type: 'compiler'
    extensions: ['.jade']

    destForFile: (source, destDir) ->
      filename = sysPath.basename(source, sysPath.extname(source)) + '.html'
      return sysPath.join(destDir, filename)

    compile: (source, destDir, callback) ->
      # Compile Jade into html
      sourceData = fs.readFileSync(source).toString()
      filename = sysPath.basename(source, sysPath.extname(source)) + '.html'
      path = sysPath.join(destDir, filename)
      fn = jade.compile sourceData, {filename: source, compileDebug: false, pretty: true}
      html = fn()

      # Run through the template engine and write to the output file
      html = _.template(html, _.extend({}, {settings: env.project.clientConfig}, @htmlHelpers))
      fs.writeFileSync path, html
      logging.info "compiled #{source}"
      callback(null, html)

  callback(new JadeCompiler())
