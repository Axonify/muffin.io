fs = require 'fs'
sysPath = require 'path'

module.exports = (env, callback) ->

  class AppCacheCompiler extends env.Compiler

    extensions: ['.appcache']

    constructor: ->
      @project = env.project

    destForFile: (source, destDir) ->
      filename = sysPath.basename(source)
      return sysPath.join(destDir, filename)

    compile: (source, destDir, callback) ->
      _ = env._
      sourceData = _.template(fs.readFileSync(source).toString(), {settings: @project.clientConfig})
      filename = sysPath.basename(source)
      path = sysPath.join(destDir, filename)
      fs.writeFileSync(path, sourceData)
      callback(null, sourceData)

  callback(new AppCacheCompiler())
