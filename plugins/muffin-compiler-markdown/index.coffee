# A Muffin plugin that compiles markdown into html.
# Syntax highlighting is provided by `highlight.js`.

fs = require 'fs'
sysPath = require 'path'
marked = require 'marked'
hljs = require 'highlight.js'

module.exports = (env, callback) ->

  class MarkdownCompiler extends env.Compiler

    # Support all common markdown suffixes
    extensions: ['.md', '.markdown', '.mdown', '.mkd', '.mkdn']

    constructor: ->
      @project = env.project

    destForFile: (path, destDir) ->
      ext = sysPath.extname(path)
      filename = sysPath.basename(path, ext) + '.html'
      sysPath.join(destDir, filename)

    compile: (path, destDir, callback) ->
      # Read the source file
      data = fs.readFileSync(path).toString()

      # Set highlight option
      marked.setOptions
        highlight: (code, lang) ->
          if lang
            hljs.highlight(lang, code).value
          else
            hljs.highlightAuto(code).value

      # Compile markdown into html
      html = marked(data)

      # Write to dest
      dest = @destForFile(path, destDir)
      fs.writeFileSync dest, html
      callback(null, html)

  callback(new MarkdownCompiler())
