Backbone = require 'Backbone'

class Router extends Backbone.Router
  
  routes:
    '':                       'index'
    
    # Default action
    '*path':                  'default'
  
  initialize: ->
  
  index: ->
    logging.debug 'show index page'
  
  default: ->
    # Redirect to login page
    @navigate '#login', {trigger: true, replace: true}

module.exports = Router