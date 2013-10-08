#
# BaseApp is in charge of logging, CSRF, JSON caching, etc.
#

Backbone = require 'Backbone'
Logger = require 'muffin/Logger'

class App

  initialize: ->
    # Create logger
    window.logging = new Logger(logLevel = '<?- settings.logLevel ?>')

    # Alias "_id" to "id" globally to work with MongoDB
    Backbone.Model.prototype.idAttribute = "_id";

    # Cancel the default actions for links with href '#'
    $(document).on 'click', "a[href$='#']", @cancelAction

    # Ajax setup
    $.ajaxSetup
      headers:
        "X-XSRF-Header": "X" # Prevent CSRF attacks
        "cache-control": "no-cache" # Prevent iOS6 from caching AJAX POST requests
      cache: false # Disable JSON caching on IE

  # Cancel default event handling
  cancelAction: (e) ->
    e.stopPropagation()
    e.preventDefault()
    false

module.exports = App
