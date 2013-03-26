Backbone = require 'Backbone'
ListPage = require './ListPage'
SettingsPage = require './SettingsPage'

class LayoutView extends Backbone.View
  
  template: _.tpl(require '../templates/LayoutView.html')
  
  events:
    'tap .next': 'showNext'
    'swipe': 'onSwipe'
    'press .menu': 'showSettings'
  
  initialize: ->
    @$el.html @template()
    
    # Show the list page
    @currentPage = new ListPage
    $('#wrapper').html(@currentPage.render().el)
  
  render: => @
  
  hideNavBar: ->
    @$('.navbar').slideUp()
  
  showNavBar: ->
    @$('.navbar').slideDown()
  
  showSettings: =>
    page = new SettingsPage
    @changePage page, {transition: 'slideup'}

module.exports = LayoutView