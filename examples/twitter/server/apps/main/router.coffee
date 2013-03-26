TweetController = require './controllers/TweetController'
FriendController = require './controllers/FriendController'
FollowerController = require './controllers/FollowerController'
RecommendedController = require './controllers/RecommendedController'

# Router
router = (app) ->
  app.namespace '/users/:id', ->
    # Tweets
    app.get '/tweets', app.authenticate, TweetController.index
    app.get '/timeline', app.authenticate, TweetController.timeline
    app.post '/tweets', app.authenticate, TweetController.create
    app.delete '/tweets/:tid', app.authenticate, TweetController.destroy
    
    # Friends
    app.get '/friends', app.authenticate, FriendController.index
    app.post '/follow/:fid', app.authenticate, FriendController.create
    app.delete '/unfollow/:fid', app.authenticate, FriendController.destroy
    
    # Followers
    app.get '/followers', app.authenticate, FollowerController.index
    
    # Recommended people to follow
    app.get '/recommended', app.authenticate, RecommendedController.index

module.exports = router