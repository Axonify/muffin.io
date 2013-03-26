Backbone = require 'Backbone'
Page = require 'UIKit/Page'
DetailPage = require './DetailPage'

class ListPage extends Page
  
  template: _.tpl(require '../templates/ListPage.html')
  
  events:
    'press .next': 'showNext'
  
  initialize: ->
  
  showNext: =>
    page = new DetailPage
    @changePage(page)
  
  render: ->
    @$el.html @template()
    @

module.exports = ListPage