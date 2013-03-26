Tweet = require '../models/Tweet'
User = require '../../auth/models/User'

TweetController = 
  # GET /users/:id/tweets
  index: (req, res) ->
    Tweet
    .find({creator: req.params.id})
    .populate('creator', 'email name username')
    .exec (err, tweets) ->
      if err
        res.send(404)
      else
        res.send(tweets)
  
  # GET /users/:id/timeline
  timeline: (req, res) ->
    User.findById req.params.id, (err, user) ->
      if user
        Tweet
        .find({$or: [{creator: req.params.id}, {creator: {$in: user.friends}}]})
        .populate('creator', 'email name username')
        .exec (err, tweets) ->
          if err
            res.send(404)
          else
            res.send(tweets)
      else
        res.send(404)
  
  # POST /users/:id/tweets
  create: (req, res) ->
    User.findById req.params.id, (err, user) ->
      if user
        # Make sure the user id matches that of current user
        if req.currentUser?.id is user.id
          tweet = new Tweet(req.body)
          tweet.creator = user.id
          tweet.created_at = tweet.updated_at = new Date
          tweet.save (err) ->
            if err
              res.send(err, 422)
            else
              user.tweets ?= []
              user.tweets.push tweet
              user.tweetsCount += 1
              user.save (err) ->
                if err then res.send(err, 422) else res.send(tweet)
        else
          res.send(403)
      else
        res.send(404)
  
  # DELETE /users/:id/tweets/:tid
  destroy: (req, res) ->
    Tweet.findById req.params.tid, (err, tweet) ->
      if tweet
        tweet.remove -> res.send(200)
      else
        res.send(404)

module.exports = TweetController