fs = require 'fs'
sysPath = require 'path'
CoffeeScript = require 'coffee-script'

module.exports = (env, callback) ->

  class CoffeeScriptCompiler extends env.Compiler

    extensions: ['.coffee']

    constructor: ->
      @project = env.project

    destForFile: (source, destDir) ->
      filename = sysPath.basename(source, sysPath.extname(source)) + '.js'
      return sysPath.join(destDir, filename)

    compile: (source, destDir, callback) ->
      _ = env._

      # Run the source file through template engine
      sourceData = _.template(fs.readFileSync(source).toString(), {settings: @project.clientConfig})
      filename = sysPath.basename(source, sysPath.extname(source)) + '.js'
      path = sysPath.join destDir, filename

      # Wrap the file into AMD module format
      js = CoffeeScript.compile(sourceData, {bare: true})

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

  callback(new CoffeeScriptCompiler())
