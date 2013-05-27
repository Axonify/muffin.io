Backbone = require 'Backbone'

class Router extends Backbone.Router
  
  routes:
    'login':                  'login'
    'reset-password':         'resetPassword'
  
  login: ->
    LoginPage = require './views/LoginPage'
    v = new LoginPage
    app.layout.setView(v)
  
  resetPassword: ->
    ResetPasswordPage = require './views/ResetPasswordPage'
    v = new ResetPasswordPage
    app.layout.setView(v)

module.exports = Router
