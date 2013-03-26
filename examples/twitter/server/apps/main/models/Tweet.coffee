mongoose = require 'mongoose'
Schema = mongoose.Schema
ObjectId = Schema.ObjectId

TweetSchema = new Schema
  text: {type: String, required: true}
  creator: {type: ObjectId, ref: 'User'}
  created_at: {type: Date, default: Date.now}
  updated_at: Date

Tweet = mongoose.model('Tweet', TweetSchema)
module.exports = Tweet