Backbone = require 'Backbone'
UIKit = require 'UIKit'
User = require 'apps/auth/models/User'

class HomePage extends UIKit.View
  
  template: _.tpl(require '../templates/HomePage.html')
  
  events:
    'click .signin-btn': 'login'
    'click .signup-btn': 'signup'
  
  initialize: ->
    @$el.html @template()
    
    # Create the forms
    @loginForm = new UIKit.Form
      el: @$('.signin-form form')
      model: apps.auth.session
    
    @user = new User
    @signupForm = new UIKit.Form
      el: @$('.signup-form form')
      model: @user
  
  render: => @
  
  login: (e) ->
    return false if apps.base.checkDoubleSubmit()
    
    # Validate the fields and update the model
    errors = @loginForm.commit()
    if errors
      app.layout.flash.error I18n.t('flash.invalidlogin')
    else
      apps.auth.login()
    false
  
  signup: (e) ->
    return false if apps.base.checkDoubleSubmit()
    
    # Validate the fields and update the model
    errors = @signupForm.commit()
    if errors
      app.layout.flash.error I18n.t('flash.failed-to-sign-up')
    else
      @user.save {},
        success: (model, response) ->
          console.log 'created user'
          apps.auth.onLoginSuccess()
        error: (model, xhr) ->
          console.log 'failed to create user'
    false

module.exports = HomePage