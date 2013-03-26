Backbone = require 'Backbone'
User = require 'apps/auth/models/User'

class FriendList extends Backbone.Collection
  model: User
  
  url: ->
    "<?= settings.baseURL ?>/users/#{@user.id}/friends"

module.exports = FriendList