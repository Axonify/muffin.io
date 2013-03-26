#
# AuthApp takes care of session management and authentication.
#

Router = require './router'
Session = require './models/Session'
I18n = require 'libs/I18n'

class App
  
  initialize: ->
    @session = new Session
  
  createRouter: ->
    @router = new Router
  
  # Force a redirect by resetting the hash first.
  redirect: (hash) ->
    @router.navigate '#!'
    @router.navigate hash, true
  
  getSession: ->
    @session.fetch
      success: (model, response) =>
        if model.user?.id
          # The session is still valid.
          @redirect window.location.hash
        else
          @clearSession()
          @redirect '#login'
      error: (model, xhr) =>
        @clearSession()
        @redirect '#login'
  
  login: =>
    @session.save {},
      success: (model, response) =>
        @onLoginSuccess()
      error: (model, xhr) =>
        #app.layout.flash.error I18n.t('flash.invalidlogin')
  
  logout: =>
    @session.destroy
      success: (model, response) =>
        @clearSession()
        
        # Reload the app to rectify any memory leaks or caching issues.
        @router.navigate ''
        window.location.reload(true)
      error: (model, xhr) ->
        logging.error "Error signing out"
  
  onLoginSuccess: ->
    document.cookie = 'is_logged_in=true'
    @router.navigate ''
    window.location.reload(true)
  
  clearSession: ->
    document.cookie = "is_logged_in=; expires=Thu, 01 Jan 1970 00:00:01 GMT;"
    @session.clear()

module.exports = App