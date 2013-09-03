#
# watcher.coffee
#

fs = require 'fs-extra'
sysPath = require 'path'
os = require 'os'
{spawn} = require 'child_process'
_ = require 'underscore'
chokidar = require 'chokidar'
CoffeeScript = require 'coffee-script'
logging = require './utils/logging'
project = require './project'
server = require './server'

# Underscore template settings
_.templateSettings =
  evaluate    : /<\?([\s\S]+?)\?>/g,
  interpolate : /<\?=([\s\S]+?)\?>/g,
  escape      : /<\?-([\s\S]+?)\?>/g

# Files to ignore
ignored = (file) ->
  /^\.|~$/.test(file) or /\.swp/.test(file)


class Watcher

  # Watch a directory
  watchDir: (dir) ->
    watcher = chokidar.watch dir, {ignored: ignored, persistent: true, ignoreInitial: true}
    watcher.on 'add', @compileFile
    watcher.on 'change', @compileFile
    watcher.on 'unlink', @removeFile
    watcher.on 'error', (error) ->
      logging.error "Error occurred while watching files: #{error}"

  # Recursively compile all files in a directory and its subdirectories
  compileDir: (source) ->
    stats = fs.statSync(source)
    if stats.isDirectory()
      files = fs.readdirSync(source)
      files = files.filter (file) -> not ignored(file)
      @compileDir sysPath.join(source, file) for file in files
    else if stats.isFile()
      @compileFile source, yes

  destDirForFile: (source) ->
    inAssetsDir = !!~ source.indexOf project.clientAssetsDir
    inComponentsDir = !!~ source.indexOf project.clientComponentsDir

    if inAssetsDir
      relativePath = sysPath.relative(project.clientAssetsDir, source)
      dest = sysPath.join(project.buildDir, relativePath)
    else if inComponentsDir
      relativePath = sysPath.relative(project.clientDir, source)
      dest = sysPath.join(project.buildDir, relativePath)
    else
      relativePath = sysPath.relative(project.clientDir, source)
      dest = sysPath.join(project.jsDir, relativePath)
    return sysPath.dirname(dest)

  destForFile: (source) ->
    destDir = @destDirForFile(source)
    extension = sysPath.extname(source)

    # Run through the compiler plugins
    for compiler in project.plugins.compilers
      if extension in compiler.extensions
        return compiler.destForFile(source)

    # Handle the rest
    if extension is '.coffee'
      filename = sysPath.basename(source, sysPath.extname(source)) + '.js'
    else
      filename = sysPath.basename(source)
    return sysPath.join(destDir, filename)

  # Compile a single file
  compileFile: (source, abortOnError=no) ->
    destDir = @destDirForFile(source)
    fs.mkdirSync(destDir) unless fs.existsSync(destDir)

    extension = sysPath.extname(source)
    try
      switch extension
        when '.coffee'
          # Run the source file through template engine
          sourceData = _.template(fs.readFileSync(source).toString(), {settings: project.clientConfig})
          filename = sysPath.basename(source, sysPath.extname(source)) + '.js'
          path = sysPath.join destDir, filename

          # Wrap the file into AMD module format
          js = CoffeeScript.compile(sourceData, {bare: true})

          # Strip the .js suffix
          modulePath = sysPath.relative(project.buildDir, path).replace(/\.js$/, '')
          deps = @parseDeps(js)

          # Concat package deps
          match = modulePath.match(/^components\/(.*)\/(.*)\//)
          if match
            extraDeps = project.packageDeps["#{match[1]}/#{match[2]}"]
            if extraDeps?.length > 0
              deps = deps.concat(extraDeps)

          js = "define('#{modulePath}', #{JSON.stringify(deps)}, function(require, exports, module) {#{js}});"
          fs.writeFileSync path, js
          logging.info "compiled #{source}"

        when '.html', '.htm'
          # Run the source file through template engine
          sourceData = _.template(fs.readFileSync(source).toString(), _.extend({}, {settings: project.clientConfig}, htmlHelpers))
          filename = sysPath.basename(source)
          path = sysPath.join(destDir, filename)
          fs.writeFileSync(path, sourceData)
          logging.info "copied #{source}"

        when '.appcache'
          sourceData = _.template(fs.readFileSync(source).toString(), {settings: project.clientConfig})
          filename = sysPath.basename(source)
          path = sysPath.join(destDir, filename)
          fs.writeFileSync(path, sourceData)
          logging.info "copied #{source}"

        when '.js'
          js = fs.readFileSync(source).toString()
          filename = sysPath.basename(source)
          path = sysPath.join(destDir, filename)

          # Strip the .js suffix
          modulePath = sysPath.relative(project.buildDir, path).replace(/\.js$/, '')
          deps = @parseDeps(js)

          # Concat package deps
          match = modulePath.match(/^components\/(.*)\/(.*)\//)
          if match
            extraDeps = project.packageDeps["#{match[1]}/#{match[2]}"]
            if extraDeps?.length > 0
              deps = deps.concat(extraDeps)

          js = "define('#{modulePath}', #{JSON.stringify(deps)}, function(require, exports, module) {#{js}});"
          fs.writeFileSync path, js
          logging.info "copied #{source}"

        else
          # Run through the compiler plugins
          compiled = no
          for compiler in project.plugins.compilers
            if extension in compiler.extensions
              compiler.compile(source, destDir)
              compiled = yes
              break

          # Copy to the destination when everything else fails.
          unless compiled
            filename = sysPath.basename(source)
            path = sysPath.join(destDir, filename)
            fs.copyFileSync source, path
            logging.info "copied #{source}"

      server.reloadBrowser(path)
    catch err
      logging.error "#{err.message} (#{source})"
      process.exit(1) if abortOnError

  # Remove a file
  removeFile: (source) ->
    dest = destForFile(source)
    stats = fs.statSync(dest)
    if stats.isFile()
      fs.unlinkSync(dest)
      logging.info "removed #{source}"

  # Print an error and exit.
  fatalError: (message) ->
    logging.error message + '\n'
    process.exit 1

  parseDeps: (content) ->
    commentRegex = /(\/\*([\s\S]*?)\*\/|([^:]|^)\/\/(.*)$)/mg
    cjsRequireRegex = /[^.]\s*require\s*\(\s*["']([^'"\s]+)["']\s*\)/g
    deps = []

    # Find all the require calls and push them into dependencies.
    content
      .replace(commentRegex, '') # remove comments
      .replace(cjsRequireRegex, (match, dep) -> deps.push(dep) if dep not in deps)
    deps

module.exports = new Watcher()
