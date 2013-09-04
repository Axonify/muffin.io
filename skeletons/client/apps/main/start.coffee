Backbone = require 'Backbone'
I18n = require 'muffin/I18n'

start = ->
  # Set default locale
  locale = I18n.getBrowserLocale()
  I18n.setLocale locale, ->
    window.apps = {}

    # Create base app
    BaseApp = require '../base/app'
    apps.base = new BaseApp()
    apps.base.initialize()

    # Create main app
    MainApp = require './app'
    window.app = apps.main = new MainApp()
    apps.main.initialize()

    # Start dispatching routes
    apps.main.createRouter()
    Backbone.history.start()

module.exports = start
