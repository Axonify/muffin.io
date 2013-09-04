Backbone = require 'Backbone'

class Router extends Backbone.Router

  routes:
    '':                       'index'

    # Default action
    '*actions':                 'index'

  initialize: -> {}

  index: ->
    logging.debug 'show index page'

module.exports = Router
