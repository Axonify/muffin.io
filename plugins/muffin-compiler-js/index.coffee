fs = require 'fs'
sysPath = require 'path'

module.exports = (env, callback) ->

  class JavaScriptCompiler extends env.Compiler

    extensions: ['.js']

    constructor: ->
      @project = env.project

    destForFile: (source, destDir) ->
      filename = sysPath.basename(source)
      return sysPath.join(destDir, filename)

    compile: (source, destDir, callback) ->
      js = fs.readFileSync(source).toString()
      filename = sysPath.basename(source)
      path = sysPath.join(destDir, filename)

      # Strip the .js suffix
      modulePath = sysPath.relative(@project.buildDir, path).replace(/\.js$/, '')
      deps = @parseDeps(js)

      # Concat package deps
      match = modulePath.match(/^components\/(.*)\/(.*)\//)
      if match
        extraDeps = @project.packageDeps["#{match[1]}/#{match[2]}"]
        if extraDeps?.length > 0
          deps = deps.concat(extraDeps)

      js = "define('#{modulePath}', #{JSON.stringify(deps)}, function(require, exports, module) {#{js}});"
      fs.writeFileSync path, js
      callback(null, js)

  callback(new JavaScriptCompiler())
