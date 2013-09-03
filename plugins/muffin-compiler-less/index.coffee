fs = require 'fs'
sysPath = require 'path'
less = require 'less'

module.exports = (env, callback) ->

  class LessCompiler extends env.Compiler

    type: 'compiler'
    extensions: ['.less']

    constructor: ->
      @project = env.project

    destForFile: (source, destDir) ->
      filename = sysPath.basename(source, sysPath.extname(source)) + '.css'
      return sysPath.join(destDir, filename)

    compile: (source, destDir, callback) ->
      sourceData = fs.readFileSync(source).toString()
      filename = sysPath.basename(source, sysPath.extname(source)) + '.css'
      path = sysPath.join destDir, filename

      options = {paths: [sysPath.dirname(source)]}
      parser = new (less.Parser)(options)
      parser.parse sourceData, (err, tree) ->
        compiledData = tree.toCSS()
        fs.writeFileSync path, compiledData
        callback(err, compiledData)

  callback(new LessCompiler())
