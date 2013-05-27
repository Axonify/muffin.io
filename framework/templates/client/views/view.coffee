Backbone = require 'Backbone'
UIKit = require 'UIKit'

class <$- _.classify(view) $> extends UIKit.View
  
  template: _.tpl(require '../templates/<$- _.classify(view) $>.html')
  
  events: {}
  
  initialize: ->
    @$el.html @template()
  
  render: => @

module.exports = <$- _.classify(view) $>
