#
# BaseApp is in charge of logging, CSRF, JSON caching, etc.
#

Backbone = require 'Backbone'
ViewHelpers = require './ViewHelpers'
Logger = require 'muffin/Logger'

# Add ViewHelpers to underscore template function
_.mixin
  tpl: (templateString) ->
    (data={}) -> _.template(templateString)(_.extend(data, ViewHelpers))

class App

  initialize: ->
    # Create logger
    window.logging = new Logger()

    # Alias "_id" to "id" globally to work with MongoDB
    Backbone.Model.prototype.idAttribute = "_id";

    $.ajaxSetup
      headers:
        "X-XSRF-Header": "X" # Prevent CSRF attacks
        "cache-control": "no-cache" # Prevent iOS6 from caching AJAX POST requests
      cache: false # Disable JSON caching on IE

module.exports = App
