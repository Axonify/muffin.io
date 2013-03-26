Backbone = require 'Backbone'

class Router extends Backbone.Router
  
  routes:
    '':                       'index'
    
    # Default action
    '*path':                  'default'
  
  initialize: ->
  
  index: ->
    HomePage = require './views/HomePage'
    v = new HomePage
    app.layout.setView(v)
  
  default: ->
    # Redirect to login page
    @navigate '#login', {trigger: true, replace: true}

module.exports = Router