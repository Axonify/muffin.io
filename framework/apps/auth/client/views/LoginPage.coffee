Backbone = require 'Backbone'
UIKit = require 'UIKit'

class LoginPage extends UIKit.View
  
  template: _.tpl(require '../templates/LoginPage.html')
  
  events: {}
  
  initialize: ->
    @$el.html @template(helpers)
  
  render: => @

module.exports = LoginPage