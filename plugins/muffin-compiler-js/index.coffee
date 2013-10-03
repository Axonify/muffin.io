# A Muffin plugin that wraps JavaScript files into modules.

fs = require 'fs'
sysPath = require 'path'

module.exports = (env, callback) ->

  class JavaScriptCompiler extends env.Compiler

    extensions: ['.js']

    constructor: ->
      @project = env.project

    destForFile: (path, destDir) ->
      filename = sysPath.basename(path)
      sysPath.join(destDir, filename)

    compile: (path, destDir, callback) ->
      # Read the source file
      js = fs.readFileSync(path).toString()

      # Strip the `.js` suffix from the module path
      dest = @destForFile(path, destDir)
      modulePath = sysPath.relative(@project.buildDir, dest).replace(/\.js$/, '')

      # Inspect the JavaScript content to infer dependencies
      deps = @parseDeps(js)

      # Concat package deps
      match = modulePath.match(/^components\/(.*)\/(.*)\//)
      if match
        extraDeps = @project.packageDeps["#{match[1]}/#{match[2]}"]
        if extraDeps?.length > 0
          deps = deps.concat(extraDeps)

      # Concat local deps
      if @project.localDeps[modulePath]
        extraDeps = @project.localDeps[modulePath]
        if extraDeps.length > 0
          deps = deps.concat(extraDeps)

      # Wrap the file into an AMD module
      js = "define('#{modulePath}', #{JSON.stringify(deps)}, function(require, exports, module) {#{js}});"
      fs.writeFileSync dest, js
      callback(null, js)

  callback(new JavaScriptCompiler())
