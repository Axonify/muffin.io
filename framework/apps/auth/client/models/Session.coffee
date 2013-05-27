Backbone = require 'Backbone'
User = require './User'

class Session extends Backbone.Model
  className: 'Session'
  urlRoot: "<?= settings.baseURL ?>/sessions"
  
  validators:
    user: 'required'
    passwd: 'password'
  
  initialize: ->
    app.currentUser = @user = new User
  
  parse: (res) ->
    if res?.user
      @user.set(res.user)
    res._id = 0 # Set a fake id so the session object can be properly saved.
    res
  
  clear: ->
    super
    @user.clear()
  
  sync: (method, model, options) =>
    options ?= {}
    methodName = method.toLowerCase()
    
    switch methodName
      when 'create', 'read', 'delete'
        options.url = "<?= settings.baseURL ?>/sessions"
    
    Backbone.sync method, model, options

module.exports = Session
