Backbone = require 'Backbone'
UIKit = require 'UIKit'

class LayoutView extends UIKit.View
  
  template: _.tpl(require '../templates/LayoutView.html')
  
  events: {}
  
  initialize: ->
    @$el.html @template()
  
  render: => @
  
  setView: (v) ->
    $('#content-container').html v.render().el

module.exports = LayoutView