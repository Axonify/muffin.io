Backbone = require 'Backbone'
UIKit = require 'UIKit'
Tweet = require '../models/Tweet'

class ProfileSummaryCard extends UIKit.View
  
  className: 'card'
  template: _.tpl(require '../templates/ProfileSummaryCard.html')
  
  events:
    'click .tweet-button': 'sendTweet'
    'keyup textarea': 'updateCounter'
    'keypress textarea': 'onKeypress'
  
  initialize: ->
  
  render: =>
    data = {user: @model.toJSON(), isCurrentUser: -> true}
    @$el.html @template(data)
    @
  
  updateCounter: (e) ->
    $counter = @$('.status-character-count')
    $tweetButton = @$('.tweet-button')
    
    text = @$('.status-text').val().trim()
    valid = Tweet.isTextValid(text)
    
    remaining = Tweet.remainingCharsCount(text.length)
    $counter.text remaining
    
    if valid
      $counter.removeClass 'invalid'
      $tweetButton.removeAttr 'disabled'
    else if text.length is 0
      $counter.removeClass 'invalid'
      $tweetButton.attr 'disabled', 'disabled'
    else
      $counter.addClass 'invalid'
      $tweetButton.attr 'disabled', 'disabled'
  
  onKeypress: (e) ->
    if e.which is 13
      @sendTweet()
      false
  
  sendTweet: (e) ->
    text = @$('.status-text').val()
    tweet = new Tweet
    tweet.creator = app.currentUser
    tweet.save {text},
      success: (model, response) =>
        @$('.status-text').val('').trigger('keyup')
        @trigger 'send:tweet', model
        logging.debug "Sent Tweet."
      error: (model, response) =>
        logging.debug "Failed to send Tweet."
    false

module.exports = ProfileSummaryCard