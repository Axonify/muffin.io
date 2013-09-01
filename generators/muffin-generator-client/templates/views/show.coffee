Backbone = require 'Backbone'
UIKit = require 'UIKit'
<$- classified $> = require '../models/<$- classified $>'

class <$- classified $>ShowView extends UIKit.View
  
  template: _.tpl(require '../templates/<$- classified $>ShowView.html')
  
  events: {}
  
  initialize: ->
    # Set up data structures backing the view
    @model = new <$- classified $>
    @model.id = @options.id
    @model.on 'change', @render
    @model.fetch()
  
  render: =>
    @$el.html @template({model: @model.toJSON()})
    @

module.exports = <$- classified $>ShowView
