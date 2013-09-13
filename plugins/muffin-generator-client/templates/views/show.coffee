Backbone = require 'Backbone'
<$- classified $> = require '../models/<$- classified $>'

class <$- classified $>ShowView extends Backbone.View

  template: _.tpl(require '../templates/<$- classified $>ShowView.html')

  events: {}

  initialize: (@options) ->
    # Set up data structures backing the view
    @model = new <$- classified $>()
    @model.id = @options.id
    @model.on 'change', @render
    @model.fetch()

  render: =>
    @$el.html @template({model: @model.toJSON()})
    @

module.exports = <$- classified $>ShowView
