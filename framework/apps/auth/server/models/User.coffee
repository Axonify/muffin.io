mongoose = require 'mongoose'
Schema = mongoose.Schema
ObjectId = Schema.ObjectId
crypto = require 'crypto'

setPassword = (password) ->
  @salt = @makeSalt()
  @encryptPassword(password)

UserSchema = new Schema
  email: {type: String, required: true, unique: true, set: (v) -> v.toLowerCase()}
  password: {type: String, required: true, set: setPassword}
  salt: {type: String, required: true}
  name: {type: String, required: true}
  created_at: { type: Date, default: Date.now }
  updated_at: Date

UserSchema.methods =
  encryptPassword: (password) ->
    crypto.createHmac('sha1', @salt).update(password).digest('hex')
  
  makeSalt: ->
    Math.round((new Date().valueOf() * Math.random())) + ''
  
  authenticate: (plainText) ->
    @encryptPassword(plainText) is @password

# Add additional keys
UserSchema.plugin(require('../../main/models/_User'))

User = mongoose.model('User', UserSchema)
module.exports = User