#
# optimizer.coffee
#

fs = require 'fs-extra'
sysPath = require 'path'
async = require 'async'
logging = require './utils/logging'
project = require './project'

# Escape js content
jsEscape = (content) ->
  content.replace(/(['\\])/g, '\\$1')
    .replace(/[\f]/g, "\\f")
    .replace(/[\b]/g, "\\b")
    .replace(/[\n]/g, "\\n")
    .replace(/[\t]/g, "\\t")
    .replace(/[\r]/g, "\\r")
    .replace(/[\u2028]/g, "\\u2028")
    .replace(/[\u2029]/g, "\\u2029")

class Optimizer

  # Recursively optimize all the files in a directory and its subdirectories
  optimizeDir: (fromDir, toDir, callback) ->
    queue = []
    queue.push [fromDir, toDir]

    test = -> queue.length > 0

    fn = (done) =>
      [from, to] = queue.pop()
      stats = fs.statSync(from)
      if stats.isDirectory()
        files = fs.readdirSync(from)
        for file in files
          queue.push [sysPath.join(from, file), sysPath.join(to, file)]
        done(null)
      else if stats.isFile()
        @optimizeFile from, to, done

    async.whilst test, fn, callback

  # Optimize a single file
  optimizeFile: (source, dest, callback) ->
    destDir = sysPath.dirname(dest)
    fs.mkdirSync(destDir) unless fs.existsSync(destDir)

    extension = sysPath.extname(source)

    # Run through the optimizer plugins
    for optimizer in project.plugins.optimizers
      if extension in optimizer.extensions
        optimizer.optimize source, dest, ->
          logging.info "minified #{source}"
          callback(null)
        return

    # Othewise, copy to the destination
    fs.copy source, dest, ->
      logging.info "copied #{source}"
      callback(null)

  # Concatenate all the module dependencies
  concatDeps: (path) ->
    content = ''
    modules = {}
    config = project.requireConfig

    baseOfPath = (path) ->
      path.split('/')[0...-1].join('/')

    filePathOf = (path) ->
      fp = sysPath.join(project.buildDir, path)
      fp += '.js' if sysPath.extname(path) not in ['.js', '.css', '.html', '.htm', '.json']
      fp

    # Convert relative path to full path
    normalize = (path, base=null) ->
      parts = path.split('/')
      if path.charAt(0) is '.' and base
        baseParts = base.split('/')
        switch parts[0]
          when '.'
            path = baseParts.concat(parts[1..]).join('/')
          when '..'
            path = baseParts[0...-1].concat(parts[1..]).join('/')
      else if config.aliases[path]
        path = config.aliases[path]
      else if config.aliases[parts[0]]
        alias = config.aliases[parts[0]]
        path = [alias].concat(parts[1..]).join('/')
      return path

    define = (path, deps, factory) ->
      # Load module dependencies
      base = baseOfPath(path)
      deps = (normalize(p, base) for p in deps)
      concat(path) for path in deps

    concat = (path) ->
      # Strip the .js suffix
      path = path.replace(/\.js$/, '')

      # Skip the module if already included
      return if modules[path]

      console.log path
      text = fs.readFileSync(filePathOf(path)).toString()

      # Otherwise, concat the module.
      if /\.(html|htm|json|css)$/.test(path)
        # Wrap the text file into a js module.
        js = "define('#{path}', [], function() {return '#{jsEscape(text)}';});"
        content += js
        modules[path] = {path}
      else
        content += text
        modules[path] = {path}
        eval(text)

    # Concatenate all module dependencies
    concat(path)
    fs.writeFileSync filePathOf(path), content

module.exports = new Optimizer()
