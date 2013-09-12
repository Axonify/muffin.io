# Watch the client folder for file changes and recompile as needed.

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
  filename = sysPath.basename(file)
  /^\.|~$/.test(filename) or /\.swp/.test(filename)

# The `Watcher` class can watch for file changes, compile files, and remove files.
class Watcher

  # Watch a directory
  watchDir: (dir) ->
    # Use `chokidar` for more reliable cross-platform file watching.
    # Turn polling off to reduce CPU usage.
    watcher = chokidar.watch dir, {ignored: ignored, persistent: true, ignoreInitial: true, usePolling: false}
    watcher.on 'add', @compileFile
    watcher.on 'change', @compileFile
    watcher.on 'unlink', @removeFile
    watcher.on 'error', (error) ->
      logging.error "Error occurred while watching files: #{error}"

  # Compile all the files in a directory and its subdirectories
  compileDir: (dir, callback) ->
    # Use a queue-based implementation to iterate over all files
    queue = []
    queue.push dir

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

  # Compile a single file
  compileFile: (path, abortOnError=no, callback) =>
    destDir = @destDirForFile(path)
    dest = @destForFile(path)

    # Create destDir if it doesn't exist
    fs.mkdirSync(destDir) unless fs.existsSync(destDir)

    try
      # Find a compiler plugin that can handle this file extension
      ext = sysPath.extname(path)
      compiler = @compilerForExt(ext)

      if compiler
        # Let the compiler plugin handle it.
        compiler.compile path, destDir, ->
          logging.info "compiled #{path}"
          server.reloadBrowser(dest)
          callback?(null)
      else
        # No plugins can handle this file. Simply copy it over.
        fs.copy path, dest, ->
          logging.info "copied #{path}"
          server.reloadBrowser(dest)
          callback?(null)

    catch err
      logging.error "#{err.message} (#{path})"
      process.exit(1) if abortOnError

  # Remove a file
  removeFile: (path) =>
    dest = @destForFile(path)
    stats = fs.statSync(dest)
    if stats.isFile()
      fs.unlinkSync(dest)
      logging.info "removed #{path}"

  # Find a compiler plugin that can handle this file extension
  compilerForExt: (ext) ->
    for compiler in project.plugins.compilers
      if ext in compiler.extensions
        return compiler
    return null

  # The destDir for a file depends on where the file is located.
  destDirForFile: (path) ->
    inAssetsDir = (path.indexOf(project.clientAssetsDir) > -1)
    inComponentsDir = (path.indexOf(project.clientComponentsDir) > -1)

    if inAssetsDir
      # If the file is in the `assets` folder, copy it to the buildDir.
      relativePath = sysPath.relative(project.clientAssetsDir, path)
      dest = sysPath.join(project.buildDir, relativePath)
    else if inComponentsDir
      # If the file is in the `components` folder, copy it to the buildDir.
      relativePath = sysPath.relative(project.clientDir, path)
      dest = sysPath.join(project.buildDir, relativePath)
    else
      # Otherwise, copy it to the jsDir.
      relativePath = sysPath.relative(project.clientDir, path)
      dest = sysPath.join(project.jsDir, relativePath)

    return sysPath.dirname(dest)

  # The dest for a file depends on the compiler that handles it.
  destForFile: (path) ->
    destDir = @destDirForFile(path)

    # Find a compiler that can handle this file extension
    ext = sysPath.extname(path)
    compiler = @compilerForExt(ext)

    if compiler
      compiler.destForFile(path, destDir)
    else
      filename = sysPath.basename(path)
      sysPath.join(destDir, filename)

module.exports = new Watcher()
