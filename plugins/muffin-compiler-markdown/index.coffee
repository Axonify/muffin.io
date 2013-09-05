fs = require 'fs'
sysPath = require 'path'
_ = require 'underscore'
marked = require 'marked'

module.exports = (env, callback) ->

  class MarkdownCompiler extends env.Compiler

    type: 'compiler'
    extensions: ['.md', '.markdown', '.mdown', '.mkd', '.mkdn']

    constructor: ->
      @project = env.project

    destForFile: (source, destDir) ->
      filename = sysPath.basename(source, sysPath.extname(source)) + '.html'
      return sysPath.join(destDir, filename)

    compile: (source, destDir, callback) ->
      # Compile markdown into html
      sourceData = fs.readFileSync(source).toString()
      filename = sysPath.basename(source, sysPath.extname(source)) + '.html'
      path = sysPath.join(destDir, filename)

      html = marked(sourceData)
      fs.writeFileSync path, html
      callback(null, html)

  callback(new MarkdownCompiler())
