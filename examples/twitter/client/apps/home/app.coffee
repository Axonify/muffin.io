#
# HomeApp shows the homepage before the user logs in.
#

I18n = require 'libs/I18n'
LayoutView = require './views/LayoutView'
Router = require './router'

class App
  
  initialize: ->
    # Set title
    document.title = I18n.t('title')
    
    # Create the router
    @router = new Router
    
    # Set up application layout
    @layout = new LayoutView {el: 'body'}

module.exports = App