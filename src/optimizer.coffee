fs = require 'fs-extra'
sysPath = require 'path'
{execFile} = require 'child_process'
logging = require './logging'
uglify = require 'uglify-js'

cwd = process.cwd()
publicDir = sysPath.join(cwd, 'public')

# Recursively optimize all the files in a directory and its subdirectories
optimizeDir = (fromDir, toDir) ->
  # Minify the js files
  fs.stat fromDir, (err, stats) ->
    throw err if err and err.code isnt 'ENOENT'
    return if err?.code is 'ENOENT'
    if stats.isDirectory()
      fs.readdir fromDir, (err, files) ->
        throw err if err and err.code isnt 'ENOENT'
        return if err?.code is 'ENOENT'
        optimizeDir sysPath.join(fromDir, file), sysPath.join(toDir, file) for file in files
    else if stats.isFile()
      optimizeFile(fromDir, toDir)

# Optimize a single file
optimizeFile = (source, dest) ->
  destDir = sysPath.dirname(dest)
  fs.exists destDir, (exists) ->
    fs.mkdirSync destDir unless exists
    _optimize()

  _optimize = ->
    switch sysPath.extname(source)
      when '.js'
        # Use uglifyjs to minify the js file
        result = uglify.minify([source], {compress: {comparisons: false}})
        fs.writeFileSync dest, result.code
        logging.info "minified #{source}"
      else
        fs.copy source, dest, (err) ->
          logging.info "copied #{source}"

# Concatenate all the module dependencies
concatDeps = (path, mapping) ->
  content = ''
  modules = {}

  baseOfPath = (path) ->
    path.split('/')[0...-1].join('/')

  filePathOf = (path) ->
    fp = sysPath.join(publicDir, path)
    fp += '.js' if sysPath.extname(path) not in ['.js', '.css', '.html', '.htm', '.json']
    fp

  # Convert relative path to full path
  normalize = (path, base=null) ->
    parts = path.split('/')
    alias = mapping[parts[0]]

    if path[0] is '.' and base
      baseParts = base.split('/')
      switch parts[0]
        when '.'
          path = baseParts.concat(parts[1..]).join('/')
        when '..'
          path = baseParts[0...-1].concat(parts[1..]).join('/')
    else if alias
      path = [alias].concat(parts[1..]).join('/')
    return path

  define = (path, deps, factory) ->
    # Load module dependencies
    base = baseOfPath(path)
    deps = (normalize(p, base) for p in deps)
    concat(path) for path in deps

  concat = (path) ->
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
      if /^define/.test(text)
        content += text
        modules[path] = {path}
        eval(text)
      else
        # Wrap the js file into a js module.
        js = "define('#{path}', [], function() {#{text}});"
        content += js
        modules[path] = {path}

  # Concatenate all module dependencies
  concat(path)
  fs.writeFileSync filePathOf(path), content


#
# Helpers
#

jsEscape = (content) ->
  content.replace(/(['\\])/g, '\\$1')
    .replace(/[\f]/g, "\\f")
    .replace(/[\b]/g, "\\b")
    .replace(/[\n]/g, "\\n")
    .replace(/[\t]/g, "\\t")
    .replace(/[\r]/g, "\\r")
    .replace(/[\u2028]/g, "\\u2028")
    .replace(/[\u2029]/g, "\\u2029")

module.exports = {optimizeDir, concatDeps}
