Backbone = require 'Backbone'

class <$- classified $> extends Backbone.View

  template: _.template(require '../templates/<$- classified $>.html')

  events: {}

  initialize: ->
    @$el.html @template()

  render: => @

module.exports = <$- classified $>
