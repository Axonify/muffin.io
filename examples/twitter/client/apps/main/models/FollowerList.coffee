Backbone = require 'Backbone'
User = require 'apps/auth/models/User'

class FollowerList extends Backbone.Collection
  model: User
  
  url: ->
    "<?= settings.baseURL ?>/users/#{@user.id}/followers"

module.exports = FollowerList