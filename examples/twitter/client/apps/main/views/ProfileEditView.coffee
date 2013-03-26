Backbone = require 'Backbone'
UIKit = require 'UIKit'

class ProfileEditView extends UIKit.View
  
  className: 'edit-profile-page'
  template: _.tpl(require '../templates/ProfileEditView.html')
  
  events:
    'click .save-button': 'saveProfile'
  
  initialize: ->
    @$el.html @template()
  
  render: => @
  
  saveProfile: (e) ->
    app.currentUser.save {username: @$('#username').val().trim()},
      success: (model, response) ->
        app.router.navigate '#!'
        app.router.navigate '#home', true
      error: (model, xhr) ->
        logging.error 'Failed to save the username.'

module.exports = ProfileEditView