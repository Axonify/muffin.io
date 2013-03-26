Backbone = require 'Backbone'
User = require 'apps/auth/models/User'

MIN_LENGTH = 1
MAX_LENGTH = 140

class Tweet extends Backbone.Model
  className: 'Tweet'
  urlRoot: ->
    "<?= settings.baseURL ?>/users/#{@creator.id}/tweets"
  
  parse: (res) ->
    if _.isObject(res?.creator)
      @creator = new User(res.creator)
    res
  
  @remainingCharsCount: (value) ->
    MAX_LENGTH - value
  
  @isTextValid: (text) ->
    text and MIN_LENGTH <= text.length <= MAX_LENGTH

module.exports = Tweet