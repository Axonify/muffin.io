Backbone = require 'Backbone'
UIKit = require 'UIKit'
TweetList = require '../models/TweetList'
TweetListView = require '../views/TweetListView'
ProfileSummaryCard = require '../views/ProfileSummaryCard'
WhoToFollowCard = require '../views/WhoToFollowCard'

class HomeIndexView extends UIKit.View
  
  template: _.tpl(require '../templates/HomeIndexView.html')
  
  events: {}
  
  initialize: ->
    @$el.html @template()
    
    # Show profile summary card in the sidebar
    @profileSummaryCard = new ProfileSummaryCard {model: app.currentUser}
    @profileSummaryCard.on 'send:tweet', @onSendTweet
    @addSubview @profileSummaryCard, 'in', @$('#sidebar-container')
    
    # Show "Who to Follow" card in the sidebar
    @whoToFollowCard = new WhoToFollowCard
    @addSubview @whoToFollowCard, 'in', @$('#sidebar-container')
    
    # Create a TweetList collection
    tweets = new TweetList
    tweets.type = 'timeline'
    tweets.user = app.currentUser
    
    # Show tweets in the content area
    @tweetsView = new TweetListView {collection: tweets}
    @addSubview @tweetsView, 'at', @$('#content-container')
  
  render: => @
  
  onSendTweet: (tweet) =>
    @tweetsView.collection.fetch {update: true}

module.exports = HomeIndexView