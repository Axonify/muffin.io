#
# Variables
#

loader = @
modules = {}
inProgressModules = {}
justDefinedModules = {}
aliases = {}
head = document.getElementsByTagName('head')[0]


#
# Global methods
#

window.require = (deps, callback) ->
  # The global require function only supports asynchronous module loading.
  # require ['module/1/path', 'module/2/path'], (module1, module2) -> {}
  # The local require function supports both asynchronous and synchronous (preloaded) module loading.
  return unless isArray(deps)
  loadAll deps, ->
    args = []
    for path in deps
      [path, format] = moduleFormatFromPath(path)
      exports = evaluate(modules[path], format)
      args.push exports
    callback.apply(loader, args)

window.define = (path, deps, factory) ->
  module = inProgressModules[path] ? {path}

  # Set module dependencies and factory function
  base = baseOfPath(path)
  module.deps = (normalize(p, base) for p in deps)
  module.factory = factory
  inProgressModules[path] = module

  if /\.(html|htm|json|css)$/.test(path)
    # If it's a text file wrapper, evaluate right away.
    module.exports = factory()
    delete module.factory

    # Inject CSS right away
    if /\.css$/.test(path) then injectCSS(module.exports, path)

  # Load dependencies after all other modules in the file are defined.
  # Some dependencies might be among those modules.
  justDefinedModules[path] = module

# Load configurations
require.aliases = (als) ->
  aliases = als

# Undefine a module
require.undef = (path) ->
  delete modules[path]


#
# Loader
#

# Fetch a JavaScript module asynchronously from its path
fetchJS = (path, callback) ->
  tag = document.createElement('script')
  tag.type = 'text/javascript'
  tag.async = true
  tag.src = (if /\.js$/.test(path) then path else path + '.js')
<? if (settings.env === 'development') { ?>
  tag.src += "?_#{(new Date()).getTime()}" # Add cache buster
<? } else if (settings.env === 'production') { ?>
  tag.src = tag.src + "?_" + "<?- (new Date()).getTime() ?>"
<? } ?>

  done = false
  tag.onload = tag.onreadystatechange = (e) ->
    readyState = tag.readyState
    if !done and (!readyState or /^(complete|loaded)$/.test(readyState))
      done = true
      # Handle memory leak in IE
      tag.onload = tag.onreadystatechange = null
      head.removeChild(tag)
      callback()
  head.appendChild(tag)

# Fetch a text file (.html, .json, .css, ...)
fetchText = (path, callback) ->
  xhr = createXHR()
<? if (settings.env === 'development') { ?>
  path += "?_#{(new Date()).getTime()}" # Add cache buster
<? } else if (settings.env === 'production') { ?>
  path = path + '?_' + "<?- (new Date()).getTime() ?>"
<? } ?>
  xhr.open 'GET', path, true
  xhr.onreadystatechange = ->
    if /^(complete|loaded|4)$/.test(xhr.readyState)
      callback(xhr.responseText)
  xhr.send(null)

createXHR = ->
  if window.ActiveXObject
    # Microsoft failed to properly implement the XMLHttpRequest
    # in IE7 (can't request local files), so we use the ActiveXObject
    # when it is available. Additionally XMLHttpRequest can be disabled
    # in IE7/IE8 so we need a fallback.
    createStandardXHR() ? createActiveXHR()
  else
    # For all other browsers, use the standard XMLHttpRequest object
    createStandardXHR()

createStandardXHR = ->
  try return new window.XMLHttpRequest()

createActiveXHR = ->
  try return new window.ActiveXObject('Microsoft.XMLHTTP')

# Inject CSS with a style tag
injectCSS = (css, path) ->
  # Skip if already applied
  return if getElementByAttributeValue('data-path', path)
  tag = document.createElement('style')
  tag.type = 'text/css'
  tag.setAttribute('data-path', path)
  if tag.styleSheet?
    # IE workaround
    tag.styleSheet.cssText = css
  else
    tag.innerHTML = css
  head.appendChild(tag)

# Load a module
load = (path, callback) ->
  [path, format] = moduleFormatFromPath(path)

  # Skip if the module is already loaded
  if modules[path]
    callback(modules[path])
    return

  # Skip if the module is being loaded
  if inProgressModules[path]
    inProgressModules[path].callbacks ?= []
    inProgressModules[path].callbacks.push callback
    return

  # Otherwise, fetch the module from its path
  inProgressModules[path] = {path, format, callbacks: [callback]}

  if /\.(html|htm|json|css)$/.test(path)
    fetchText path, (text) ->
      module = inProgressModules[path]
      module.exports = text
      if /\.css/.test(path) then injectCSS(text, path)
      didLoadModule(module)
  else
    fetchJS path, ->
      for p, module of justDefinedModules
        # Get around the stupid JavaScript scoping issue using blocks.
        # Note that if we use "loadAll module.deps -> didLoadModules(module)",
        # didLoadModules will not call on the original module, but the module in the current loop.
        loadDeps = (m) ->
          loadAll m.deps, -> didLoadModule(m)
        loadDeps(module)
        delete justDefinedModules[p]

# Load multiple modules and trigger callback after all loaded.
loadAll = (deps, callback) ->
  if deps?.length
    completed = 0
    done = (module) ->
      completed++
      if completed >= deps.length
        callback()
    load(path, done) for path in deps
  else
    callback()

didLoadModule = (module) ->
  path = module.path

  # Save the module in memory
  modules[path] = module

  # Fire all the callbacks
  unless module.callbacks
    console.error "Failed to load module #{module.path}"

  cbk(module) for cbk in module.callbacks
  delete module.callbacks
  delete inProgressModules[path]

# Evaluate a module by running its factory function
evaluate = (module, format) ->
  if module.factory?
    module.exports = {}
    path = module.path
    base = baseOfPath(path)

    # Handle relative paths with a local require function
    localRequire = (deps, callback) ->
      if isArray(deps)
        _deps = (normalize(p, base) for p in deps)
        # Call the global require
        return require(_deps, callback)
      else if typeof deps is 'string'
        # Synchronous require:
        # module = require 'module/path'
        p = normalize(deps, base)
        [p, fmt] = moduleFormatFromPath(p)
        m = modules[p]
        if m
          return evaluate(m, fmt)
        else
          console.log "module #{p} not found"
          return null

    for own prop, value of require
      localRequire[prop] = value

    if format is 'module'
      module.factory.call(window, localRequire, module.exports, module)
    else
      module.factory.call(window)
    delete module.factory
  return module.exports


#
# Helpers
#

isArray = (obj) -> Object.prototype.toString.call(obj) == '[object Array]'

baseOfPath = (path) ->
  path.split('/')[0...-1].join('/')

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
  else if aliases[path]
    path = aliases[path]
  else if aliases[parts[0]]
    alias = aliases[parts[0]]
    path = [alias].concat(parts[1..]).join('/')
  return path

# Get module format
moduleFormatFromPath = (path) ->
  if /\.(html|htm|json|css)$/.test(path)
    format = 'text'
  else if /\.js$/.test(path)
    # If path ends with '.js', it's considered as a traditional script; otherwise a module.
    path = path[...-3]
    format = 'script'
  else
    format = 'module'
  return [path, format]

# Get any one element by a certain attribute value
getElementByAttributeValue = (attribute, value) ->
  for element in document.getElementsByTagName('*')
    return element if element.getAttribute(attribute) is value
