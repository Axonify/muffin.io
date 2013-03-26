Backbone = require 'Backbone'

class LayoutView extends Backbone.View
  
  template: _.tpl(require '../templates/LayoutView.html')
  
  events:
    'tap .next': 'showNext'
    'swipe': 'onSwipe'
  
  initialize: ->
  
  render: -> @

module.exports = LayoutView