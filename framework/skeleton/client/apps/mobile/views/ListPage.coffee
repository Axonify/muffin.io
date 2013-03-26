Backbone = require 'Backbone'
Page = require 'UIKit/Page'
DetailPage = require './DetailPage'
SettingsPage = require './SettingsPage'

class ListPage extends Page
  
  template: _.tpl(require '../templates/ListPage.html')
  
  events:
    'press .next': 'showNext'
    'press .menu': 'showSettings'
  
  initialize: ->
  
  showSettings: =>
    page = new SettingsPage
    @changePage page, {transition: 'slideup'}
  
  showNext: =>
    page = new DetailPage
    @changePage(page)
  
  render: ->
    @$el.html @template()
    @

module.exports = ListPage