Backbone = require 'Backbone'
UIKit = require 'UIKit'
TweetList = require '../models/TweetList'
TweetListView = require './TweetListView'
FriendList = require '../models/FriendList'
FollowerList = require '../models/FollowerList'
UserListView = require './UserListView'
WhoToFollowCard = require './WhoToFollowCard'

class ProfileIndexView extends UIKit.View
  
  template: _.tpl(require '../templates/ProfileIndexView.html')
  
  events:
    'click #sidebar-container li': 'onSelectRow'
  
  initialize: ->
    @$el.html @template()
    
    # Show "Who to Follow" card in the sidebar
    @whoToFollowCard = new WhoToFollowCard
    @addSubview @whoToFollowCard, 'in', @$('#sidebar-container')
  
  render: => @
  
  showTweets: ->
    @$("[data-row='tweets']").click()
  
  showFriends: ->
    @$("[data-row='friends']").click()
  
  showFollowers: ->
    @$("[data-row='followers']").click()
  
  onSelectRow: (e) ->
    $li = $(e.currentTarget)
    $li.siblings().removeClass('active')
    $li.addClass('active')
    
    switch $li.attr('data-row')
      when 'tweets'
        # Create a TweetList collection
        tweets = new TweetList
        tweets.type = 'tweets'
        tweets.user = app.currentUser
        
        # Show the tweets
        v = new TweetListView {collection: tweets}
        @addSubview v, 'at', @$('#content-container')
      when 'friends'
        # Show the friends
        friends = new FriendList
        friends.user = app.currentUser
        v = new UserListView {collection: friends, type: 'friends'}
        @addSubview v, 'at', @$('#content-container')
      when 'followers'
        # Show the followers
        followers = new FollowerList
        followers.user = app.currentUser
        v = new UserListView {collection: followers, type: 'followers'}
        @addSubview v, 'at', @$('#content-container')
    false

module.exports = ProfileIndexView