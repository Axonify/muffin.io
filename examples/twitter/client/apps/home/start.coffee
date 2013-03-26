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
    
    # Create home app
    HomeApp = require './app'
    window.app = apps.home = new HomeApp
    apps.home.initialize()
    
    # Create auth app
    AuthApp = require '../auth/app'
    apps.auth = new AuthApp
    apps.auth.initialize()
    
    # Create routers and dispatch routes
    apps.auth.createRouter()
    
    # Start dispatching routes
    Backbone.history.start()

module.exports = start