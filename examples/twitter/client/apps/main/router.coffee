Backbone = require 'Backbone'
HomeIndexView = require './views/HomeIndexView'
ProfileIndexView = require './views/ProfileIndexView'
ProfileEditView = require './views/ProfileEditView'

class Router extends Backbone.Router
  
  routes:
    'home':                   'showHome'
    'me':                     'showTweets'
    'tweets':                 'showTweets'
    'friends':                'showFriends'
    'followers':              'showFollowers'
    'me/edit':                'editProfile'
    
    # Default action
    '*path':                  'default'
  
  initialize: ->
  
  showHome: ->
    if apps.auth.session.user.get('username').length > 0
      v = new HomeIndexView
      app.layout.selectTab('Home')
      app.layout.setView(v)
    else
      @editProfile()
  
  showTweets: ->
    v = new ProfileIndexView
    app.layout.selectTab('Me')
    app.layout.setView(v)
    v.showTweets()
  
  showFriends: ->
    v = new ProfileIndexView
    app.layout.selectTab('Me')
    app.layout.setView(v)
    v.showFriends()
  
  showFollowers: ->
    v = new ProfileIndexView
    app.layout.selectTab('Me')
    app.layout.setView(v)
    v.showFollowers()
  
  editProfile: ->
    v = new ProfileEditView
    app.layout.selectTab('Me')
    app.layout.setView v
  
  default: ->
    @navigate '#home', {trigger: true, replace: true}

module.exports = Router