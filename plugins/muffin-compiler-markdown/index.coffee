fs = require 'fs'
sysPath = require 'path'
marked = require 'marked'
hljs = require 'highlight.js'

module.exports = (env, callback) ->

  class MarkdownCompiler extends env.Compiler

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

      # Set highlight option
      marked.setOptions
        highlight: (code, lang) ->
          if lang
            hljs.highlight(lang, code).value
          else
            hljs.highlightAuto(code).value

      html = marked(sourceData)
      fs.writeFileSync path, html
      callback(null, html)

  callback(new MarkdownCompiler())
