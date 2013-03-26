Backbone = require 'Backbone'

class Router extends Backbone.Router
  
  routes:
    '':                       'index'
    
    # Default action
    '*path':                  'default'
  
  initialize: -> {}
  
  index: ->
    logging.debug 'show index page'
  
  default: ->
    @navigate '', {trigger: true, replace: true}

module.exports = Router