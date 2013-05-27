mongoose = require 'mongoose'
Schema = mongoose.Schema
ObjectId = Schema.ObjectId

SessionSchema = new Schema
  created_at: { type: Date, default: Date.now }
  updated_at: Date

Session = mongoose.model('Session', SessionSchema)
module.exports = Session
