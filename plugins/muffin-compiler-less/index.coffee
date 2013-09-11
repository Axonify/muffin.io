# A Muffin plugin that compiles LESS into CSS.

fs = require 'fs'
sysPath = require 'path'
less = require 'less'

module.exports = (env, callback) ->

  class LessCompiler extends env.Compiler

    extensions: ['.less']

    constructor: ->
      @project = env.project

    destForFile: (path, destDir) ->
      ext = sysPath.extname(path)
      filename = sysPath.basename(path, ext) + '.css'
      sysPath.join(destDir, filename)

    compile: (path, destDir, callback) ->
      # Read the source file
      data = fs.readFileSync(path).toString()

      # Output file
      dest = @destForFile(path, destDir)

      # Compile LESS into CSS
      options = {paths: [sysPath.dirname(path)]}
      parser = new (less.Parser)(options)
      parser.parse data, (err, tree) ->
        compiledData = tree.toCSS()
        fs.writeFileSync dest, compiledData
        callback(err, compiledData)

  callback(new LessCompiler())
