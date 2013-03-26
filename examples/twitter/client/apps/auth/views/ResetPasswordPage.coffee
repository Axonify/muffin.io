Backbone = require 'Backbone'
UIKit = require 'UIKit'

class ResetPasswordPage extends UIKit.View
  
  template: _.tpl(require '../templates/ResetPasswordPage.html')
  
  events: {}
  
  initialize: ->
    @$el.html @template()
  
  render: => @

module.exports = ResetPasswordPage