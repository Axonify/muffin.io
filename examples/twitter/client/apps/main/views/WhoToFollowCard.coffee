Backbone = require 'Backbone'
UIKit = require 'UIKit'
RecommendedList = require '../models/RecommendedList'

class WhoToFollowCard extends UIKit.View
  
  className: 'card'
  template: _.tpl(require '../templates/WhoToFollowCard.html')
  userTemplate: _.tpl(require '../templates/_user_to_follow.html')
  
  events:
    'click .follow-link': 'follow'
  
  initialize: ->
    @$el.html @template()
    
    # Set up data structures backing the view
    @collection = new RecommendedList
    @collection.user = app.currentUser
    @collection.on 'reset', @render
    @collection.fetch()
  
  render: =>
    $list = @$('.recommended-users').empty()
    @collection.each (user) =>
      $list.append @userTemplate({user: user.toJSON()})
    @
  
  follow: (e) ->
    $li = $(e.target).closest('.user-to-follow')
    userId = $li.attr('data-id')
    
    $.ajax
      type: 'POST'
      url: "<?= settings.baseURL ?>/users/#{app.currentUser.id}/follow/#{userId}"
      contentType: 'application/json'
      data: JSON.stringify({})
      dataType: 'json'
      success: (data, status, xhr) =>
        logging.error "did follow user #{userId}"
      error: (xhr, status, error) =>
        logging.error "failed to follow user #{userId}"

module.exports = WhoToFollowCard