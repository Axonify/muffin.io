#
# watcher.coffee
#

fs = require 'fs-extra'
sysPath = require 'path'
_ = require 'underscore'
async = require 'async'
chokidar = require 'chokidar'
logging = require './utils/logging'
project = require './project'
server = require './server'

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
  compileDir: (source, callback) ->
    queue = []
    queue.push source

    test = -> queue.length > 0

    fn = (done) =>
      from = queue.pop()
      stats = fs.statSync(from)
      if stats.isDirectory()
        files = fs.readdirSync(from)
        files = files.filter (file) -> not ignored(file)
        for file in files
          queue.push sysPath.join(from, file)
        done(null)
      else if stats.isFile()
        @compileFile from, yes, done

    async.whilst test, fn, callback

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
    filename = sysPath.basename(source)
    return sysPath.join(destDir, filename)

  # Compile a single file
  compileFile: (source, abortOnError=no, callback) ->
    destDir = @destDirForFile(source)
    fs.mkdirSync(destDir) unless fs.existsSync(destDir)

    extension = sysPath.extname(source)
    try
      # Run through the compiler plugins
      for compiler in project.plugins.compilers
        if extension in compiler.extensions
          compiler.compile source, destDir, ->
            logging.info "compiled #{source}"
            server.reloadBrowser(path)
            callback(null)
          return

      # Otherwise, copy to the destination
      filename = sysPath.basename(source)
      path = sysPath.join(destDir, filename)
      fs.copy source, path, ->
        logging.info "copied #{source}"
        server.reloadBrowser(path)
        callback(null)

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

module.exports = new Watcher()
