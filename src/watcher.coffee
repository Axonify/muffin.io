#
# watcher.coffee
#

fs = require 'fs-extra'
sysPath = require 'path'
os = require 'os'
{spawn} = require 'child_process'
_ = require 'underscore'
logging = require './utils/logging'
project = require './project'
chokidar = require 'chokidar'
CoffeeScript = require 'coffee-script'

# Underscore template settings
_.templateSettings =
  evaluate    : /<\?([\s\S]+?)\?>/g,
  interpolate : /<\?=([\s\S]+?)\?>/g,
  escape      : /<\?-([\s\S]+?)\?>/g

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
    fs.stat source, (err, stats) ->
      throw err if err and err.code isnt 'ENOENT'
      return if err?.code is 'ENOENT'
      if stats.isDirectory()
        fs.readdir source, (err, files) ->
          throw err if err and err.code isnt 'ENOENT'
          return if err?.code is 'ENOENT'
          files = files.filter (file) -> not @ignored(file)
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
    switch sysPath.extname(source)
      when '.coffee'
        filename = sysPath.basename(source, sysPath.extname(source)) + '.js'
      when '.jade'
        filename = sysPath.basename(source, sysPath.extname(source)) + '.html'
      else
        filename = sysPath.basename(source)
    return sysPath.join(destDir, filename)

  # Compile a single file
  compileFile: (source, abortOnError=no) ->
    destDir = @destDirForFile(source)
    fs.exists destDir, (exists) ->
      fs.mkdirSync destDir unless exists
      _compile()

    _compile = ->
      try
        switch sysPath.extname(source)
          when '.coffee'
            # Run the source file through template engine
            sourceData = _.template(fs.readFileSync(source).toString(), {project.clientSettings})
            filename = sysPath.basename(source, sysPath.extname(source)) + '.js'
            path = sysPath.join destDir, filename

            # Wrap the file into AMD module format
            js = CoffeeScript.compile(sourceData, {bare: true})

            # Strip the .js suffix
            modulePath = sysPath.relative(project.buildDir, path).replace(/\.js$/, '')
            deps = parseDeps(js)

            # Concat package deps
            match = modulePath.match(/^components\/(.*)\/(.*)\//)
            if match
              extraDeps = project.packageDeps["#{match[1]}/#{match[2]}"]
              if extraDeps?.length > 0
                deps = deps.concat(extraDeps)

            js = "define('#{modulePath}', #{JSON.stringify(deps)}, function(require, exports, module) {#{js}});"
            fs.writeFileSync path, js
            logging.info "compiled #{source}"
            server.reloadBrowser(path)

          when '.html', '.htm'
            # Run the source file through template engine
            sourceData = _.template(fs.readFileSync(source).toString(), _.extend({}, {project.clientSettings}, htmlHelpers))
            filename = sysPath.basename(source)
            path = sysPath.join(destDir, filename)
            fs.writeFileSync(path, sourceData)
            logging.info "copied #{source}"
            server.reloadBrowser(path)

          when '.appcache'
            sourceData = _.template(fs.readFileSync(source).toString(), {project.clientSettings})
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
            deps = parseDeps(js)

            # Concat package deps
            match = modulePath.match(/^components\/(.*)\/(.*)\//)
            if match
              extraDeps = project.packageDeps["#{match[1]}/#{match[2]}"]
              if extraDeps?.length > 0
                deps = deps.concat(extraDeps)

            js = "define('#{modulePath}', #{JSON.stringify(deps)}, function(require, exports, module) {#{js}});"
            fs.writeFileSync path, js
            logging.info "copied #{source}"
            server.reloadBrowser(path)
          else
            filename = sysPath.basename(source)
            path = sysPath.join destDir, filename

            fs.copy source, path, (err) ->
              logging.info "copied #{source}"
              server.reloadBrowser(path)
      catch err
        logging.error "#{err.message} (#{source})"
        process.exit(1) if abortOnError

  # Remove a file
  removeFile: (source) ->
    dest = destForFile(source)
    fs.stat dest, (err, stats) ->
      return if err
      if stats.isDirectory()
        fs.rmdir dest, (err) ->
          return if err
          logging.info "removed #{source}"
      else if stats.isFile()
        fs.unlink dest, (err) ->
          return if err
          logging.info "removed #{source}"

  # Helpers
  isDirectory: (path) ->
    stats = fs.statSync(path)
    stats.isDirectory()

  # Files to ignore
  ignored: (file) ->
    /^\.|~$/.test(file) or /\.swp/.test(file)

  serverIgnored: (file) ->
    /^\.|~$/.test(file) or /\.swp/.test(file) or file.match(project.buildDir)

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
