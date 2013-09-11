# A Muffin plugin that compiles CoffeeScript and wraps it into a module.

fs = require 'fs'
sysPath = require 'path'
CoffeeScript = require 'coffee-script'

module.exports = (env, callback) ->

  class CoffeeScriptCompiler extends env.Compiler

    extensions: ['.coffee']

    constructor: ->
      @project = env.project

    destForFile: (path, destDir) ->
      ext = sysPath.extname(path)
      filename = sysPath.basename(path, ext) + '.js'
      sysPath.join(destDir, filename)

    compile: (path, destDir, callback) ->
      _ = env._

      # Run the file through the template engine
      data = _.template(fs.readFileSync(path).toString(), {settings: @project.clientConfig})

      # Compile the file
      js = CoffeeScript.compile(data, {bare: true})

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

      # Wrap the file into an AMD module
      js = "define('#{modulePath}', #{JSON.stringify(deps)}, function(require, exports, module) {#{js}});"
      fs.writeFileSync dest, js
      callback(null, js)

  callback(new CoffeeScriptCompiler())
