Backbone = require 'Backbone'

class <$- classified $> extends Backbone.View

  template: _.tpl(require '../templates/<$- classified $>.html')

  events: {}

  initialize: ->
    @$el.html @template()

  render: => @

module.exports = <$- classified $>
