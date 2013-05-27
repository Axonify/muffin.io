deepMerge = (target, objects...) ->
  for object in objects
    for key, value of object
      if typeof value is 'object'
        target[key] ?= {}
        deepMerge target[key], value
      else
        target[key] = value
  return target

I18n =
  locale: 'en'
  mapping: {}
  
  # Support stringId in dot notation, like 'a.b.c'.
  # Support interpolation via underscore template.
  t: (stringId, context={}) ->
    str = @mapping
    _(stringId.split('.')).each (part) -> str = str[part]
    if str?
      _.template(str)(context)
    else
      console.error "Can't find '#{stringId}' in the strings file."
      undefined
  
  register: (mapping) ->
    deepMerge @mapping, mapping
  
  clear: ->
    @mapping = {}
  
  getBrowserLocale: ->
    if navigator
      locale = navigator.language or navigator.browserLanguage or navigator.systemLanguage or navigator.userLanguage
      locale = locale.replace('_', '-').replace(/\W/, '-').toLowerCase() if locale
    locale ?= 'en'
    return locale
  
  setLocale: (locale, callback) ->
    supportedLocales = '<?- settings.supportedLocales ?>'.split(',') ? []
    paths = [@pathForLocale('en')]
    
    # Find the best fit in supported locales
    parts = locale.split('-')
    for i in [0...parts.length]
      current = parts[0..i].join('-')
      if current in supportedLocales
        @locale = current
        path = @pathForLocale(current)
        paths.push(path) unless path in paths
    
    require paths, ->
      I18n.clear()
      
      for path in paths
        str = require path
        I18n.register str
      
      # All done
      callback()
  
  pathForLocale: (locale) -> "strings/#{locale}/str"

module.exports = I18n
