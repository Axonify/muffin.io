Backbone = require 'Backbone'
Page = require 'UIKit/Page'

class SettingsPage extends Page
  
  template: _.tpl(require '../templates/SettingsPage.html')
  
  events:
    'press .done': 'dismiss'
  
  initialize: ->
  
  render: ->
    @$el.html @template()
    @

module.exports = SettingsPage
