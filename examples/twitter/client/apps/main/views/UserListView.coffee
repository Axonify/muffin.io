Backbone = require 'Backbone'
UIKit = require 'UIKit'

class UserListView extends UIKit.View
  
  template: _.tpl(require '../templates/UserListView.html')
  userTemplate: _.tpl(require '../templates/_user.html')
  
  events: {}
  
  initialize: ->
    @$el.html @template()
    
    # Set header
    @type = @options.type
    switch @type
      when 'friends'
        @$('.users-header h3').text 'Following'
      when 'followers'
        @$('.users-header h3').text 'Followers'
    
    # Set up data structures backing the view
    @collection.on 'reset', @render
    @collection.fetch()
  
  render: =>
    $list = @$('.users').empty()
    @collection.each (user) =>
      $list.append @userTemplate({user: user.toJSON(), type: @type})
    @

module.exports = UserListView