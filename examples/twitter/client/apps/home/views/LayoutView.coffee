Backbone = require 'Backbone'
UIKit = require 'UIKit'

class LayoutView extends UIKit.View
  
  template: _.tpl(require '../templates/LayoutView.html')
  
  events: {}
  
  initialize: ->
    @$el.html @template()
  
  render: => @
  
  setView: (v) ->
    $c = $('#content-container')
    $c.animate {opacity: 0}, 100, ->
      $c.html v.render().el
      $c.animate {opacity: 1}, 100

module.exports = LayoutView