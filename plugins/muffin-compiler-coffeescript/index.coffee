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
      settings = @project.clientConfig

      # Generate source map in development mode
      generateSourceMap = (settings.env is 'development')

      # Filenames
      srcFilename = sysPath.basename(path)
      destFilename = sysPath.basename(path, sysPath.extname(path)) + '.js'

      # Run the file through the template engine
      data = _.template(fs.readFileSync(path).toString(), {settings})

      # CoffeeScript compile options
      coffeeOpts =
        bare: true
        sourceMap: generateSourceMap
        filename: srcFilename

      # Copy the CoffeeScript file to the build directory so it's accessible
      if generateSourceMap
        to = sysPath.join(destDir, srcFilename)
        fs.writeFileSync to, data

        coffeeOpts = _.extend coffeeOpts,
          generatedFile: destFilename
          sourceFiles: [srcFilename]

      # Compile the file
      compiled = CoffeeScript.compile(data, coffeeOpts)
      if generateSourceMap
        js = compiled.js
      else
        js = compiled

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
      unless @nowrap
        js = "define('#{modulePath}', #{JSON.stringify(deps)}, function(require, exports, module) {#{js}});"

      # Add souce map URL
      if generateSourceMap
        js = "#{js}\n//# sourceMappingURL=#{srcFilename}.map\n"
        fs.writeFileSync sysPath.join(destDir, "#{srcFilename}.map"), compiled.v3SourceMap

      fs.writeFileSync dest, js
      callback(null, js)

  callback(new CoffeeScriptCompiler())
