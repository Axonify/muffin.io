Backbone = require 'Backbone'
Tweet = require './Tweet'

class TweetList extends Backbone.Collection
  model: Tweet
  
  initialize: ->
    @type = 'tweets'
  
  url: ->
    switch @type
      when 'timeline'
        "<?= settings.baseURL ?>/users/#{@user.id}/timeline"
      when 'tweets'
        "<?= settings.baseURL ?>/users/#{@user.id}/tweets"
  
  comparator: (model) ->
    -(new Date(model.get('created_at'))).getTime()

module.exports = TweetList