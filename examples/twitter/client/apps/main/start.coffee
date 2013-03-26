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
    
    # Create main app
    MainApp = require './app'
    window.app = apps.main = new MainApp
    apps.main.initialize()
    
    # Create auth app
    AuthApp = require '../auth/app'
    apps.auth = new AuthApp
    apps.auth.initialize()
    
    # Create routers and dispatch routes
    apps.main.createRouter()
    apps.auth.createRouter()
    
    # Ignore initial route. Let AuthApp redirect.
    Backbone.history.start {silent: true}
    
    # Get session info and redirect.
    apps.auth.getSession()

module.exports = start