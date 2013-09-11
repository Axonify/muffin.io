Backbone = require 'Backbone'
UIKit = require 'UIKit'

class <$- classified $> extends UIKit.View

  template: _.tpl(require '../templates/<$- classified $>.html')

  events: {}

  initialize: ->
    @$el.html @template()

  render: => @

module.exports = <$- classified $>
