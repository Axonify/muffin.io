#
# BaseApp is in charge of logging, CSRF, JSON caching, etc.
#

Backbone = require 'Backbone'
ViewHelpers = require './ViewHelpers'
Logger = require 'muffin/Logger'
utils = require 'muffin/utils'
$.os = utils.detectOS()

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

    # Cancel the default actions for links with href '#'
    $(document).on 'click', "a[href$='#']", @cancelAction

    if $.os.mobile and 'ontouchstart' of window
      # Trigger 'press' events on tap
      $(document).on 'tap', 'body', (e) ->
        $(e.target).trigger('press')

      # Enable button pressed state on touchstart
      $(document).on 'touchstart', 'a', (e) -> $(e.target).addClass('pressed')
      $(document).on 'touchend', 'a', (e) -> $(e.target).removeClass('pressed')
    else
      # Trigger 'press' events on click
      $(document).on 'click', 'body', (e) ->
        $(e.target).trigger('press')

      # Enable button pressed state on mousedown
      $(document).on 'mousedown', 'a', (e) -> $(e.target).addClass('pressed')
      $(document).on 'mouseup', 'a', (e) -> $(e.target).removeClass('pressed')

  # Cancel default event handling
  cancelAction: (e) ->
    e.stopPropagation()
    e.preventDefault()
    false

  # Avoid double submits
  checkDoubleSubmit: ->
    if @lastClick and Date.now() - @lastClick < 2000
      # It's a double submit!
      return true
    else
      @lastClick = Date.now()
      return false

module.exports = App
