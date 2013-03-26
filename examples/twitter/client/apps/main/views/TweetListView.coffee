Backbone = require 'Backbone'
UIKit = require 'UIKit'

class TweetListView extends UIKit.View
  
  template: _.tpl(require '../templates/TweetListView.html')
  tweetTemplate: _.tpl(require '../templates/_tweet.html')
  
  events: {}
  
  initialize: ->
    @$el.html @template()
    
    # Set up data structures backing the view
    @collection.on 'reset', @render
    @collection.on 'add', @addItem
    @collection.on 'remove', @removeItem
    @collection.fetch()
  
  addItem: (tweet) =>
    $list = @$('.tweets')
    $list.prepend @tweetTemplate({tweet: tweet.toJSON(), creator: tweet.creator.toJSON()})
  
  render: =>
    $list = @$('.tweets').empty()
    @collection.each (tweet) =>
      $list.append @tweetTemplate({tweet: tweet.toJSON(), creator: tweet.creator.toJSON()})
    @

module.exports = TweetListView