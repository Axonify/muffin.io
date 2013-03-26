Backbone = require 'Backbone'
User = require 'apps/auth/models/User'

class RecommendedList extends Backbone.Collection
  model: User
  
  url: ->
    "<?= settings.baseURL ?>/users/#{@user.id}/recommended"

module.exports = RecommendedList