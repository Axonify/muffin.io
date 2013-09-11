# A Muffin plugin that handles appcache files.

fs = require 'fs'
sysPath = require 'path'

module.exports = (env, callback) ->

  class AppCacheCompiler extends env.Compiler

    extensions: ['.appcache']

    constructor: ->
      @project = env.project

    destForFile: (path, destDir) ->
      filename = sysPath.basename(path)
      sysPath.join(destDir, filename)

    compile: (path, destDir, callback) ->
      _ = env._

      # Run the file through the template engine
      data = _.template(fs.readFileSync(path).toString(), {settings: @project.clientConfig})

      # Write to dest
      dest = @destForFile(path, destDir)
      fs.writeFileSync dest, data
      callback(null, data)

  callback(new AppCacheCompiler())
