Backbone = require 'Backbone'
Page = require 'UIKit/Page'

class DetailPage extends Page
  
  template: _.tpl(require '../templates/DetailPage.html')
  
  events:
    'press .prev': 'pop'
  
  initialize: ->
  
  render: ->
    @$el.html @template()
    @

module.exports = DetailPage
