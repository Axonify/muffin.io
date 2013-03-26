Backbone = require 'Backbone'
I18n = require 'libs/I18n'

start = ->
  # Set default locale
  locale = I18n.getBrowserLocale()
  I18n.setLocale locale, ->
    window.apps = {}
    
    # Create base app
    BaseApp = require '../base/app'
    apps.base = new BaseApp
    apps.base.initialize()
    
    # Create mobile app
    MobileApp = require './app'
    window.app = apps.mobile = new MobileApp
    apps.mobile.initialize()
    
    # Start dispatching routes
    Backbone.history.start()

module.exports = start