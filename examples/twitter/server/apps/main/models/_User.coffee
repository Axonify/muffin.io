mongoose = require 'mongoose'
Schema = mongoose.Schema
ObjectId = Schema.ObjectId
Tweet = require './Tweet'

UserPlugin = (schema, options) ->
  schema.add
    username: [type: String, required: true]
    profileImageUrl: String
    
    tweets: [{type: ObjectId, ref: 'Tweet'}]
    tweetsCount: {type: Number, default: 0}
    
    friends: [{type: ObjectId, ref: 'User'}]
    friendsCount: {type: Number, default: 0}
    
    followers: [{type: ObjectId, ref: 'User'}]
    followersCount: {type: Number, default: 0}

module.exports = UserPlugin