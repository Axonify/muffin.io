Backbone = require 'Backbone'
I18n = require 'libs/I18n'
helpers = require 'libs/helpers'
Router = require './router'
ListPage = require './views/ListPage'
DetailPage = require './views/DetailPage'

class App
  
  initialize: ->
    super
    
    # Detect OS
    helpers.detectOS()
    
    # Show the list page
    @currentPage = new ListPage
    $('#wrapper').html(@currentPage.render().el)

module.exports = App