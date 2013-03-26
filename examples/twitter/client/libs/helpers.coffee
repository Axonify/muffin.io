I18n = require 'libs/I18n'

helpers =
  I18n: I18n
  
  # Check client version in ajaxSuccess global handler
  getClientVersion: (xhr) ->
    parseInt(xhr.getResponseHeader("X-Client-Version"), 10)

  supportsCanvas: ->
    document.createElement("canvas").getContext?('2d')?
  
  supportsLocalStorage: -> 'localStorage' of window
  
  isValidEmail: (email) ->
    email.match /^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}$/i
  
  hideAddressBar: ->
    if document.height <= window.outerHeight
      document.body.style.height = "#{window.outerHeight + 60}px"
      window.scrollTo(0, 1)
    else
      window.scrollTo(0, 1)
  
  getAppHost: ->
    location = window.location
    port = parseInt(location.port, 10)
    port = null if isNaN(port) or port <= 0
    {protocol: location.protocol, host: location.hostname, port}
  
  isTouchDevice: ->
    !!("ontouchstart" of window) or !!("onmsgesturechange" of window)

module.exports = helpers