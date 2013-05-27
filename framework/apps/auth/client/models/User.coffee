Backbone = require 'Backbone'

class User extends Backbone.Model
  className: 'User'
  urlRoot: "<?= settings.baseURL ?>/users"

module.exports = User
