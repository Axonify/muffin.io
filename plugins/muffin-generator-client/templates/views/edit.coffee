Backbone = require 'Backbone'
Form = require 'muffin/forms'
<$- classified $> = require '../models/<$- classified $>'

class <$- classified $>EditView extends Backbone.View

  template: _.tpl(require '../templates/<$- classified $>EditView.html')

  events:
    'click form .btn-primary': 'onSubmit'
    'click form .btn.cancel': 'onCancel'

  initialize: (@options) ->
    @$el.html @template()

    # Set up data structures backing the view
    @model = new <$- classified $>()
    @model.id = @options.id
    @model.on 'change', @render
    @model.fetch()

    # Set up form
    @form = new Form
      el: @$('form')
      model: @model

  render: =>
    @form.update(@model)
    @

  onSubmit: (e) ->
    # Validate the fields and update the model
    errors = @form.commit()
    return false if errors

    @model.save {},
      sender: @model
      success: (model, response) =>
        logging.debug "Updated <$- classified $>."
        Backbone.history.navigate '#<$- underscored_plural $>', true
      error: (model, response) =>
        logging.debug "Failed to update <$- classified $>."
    false

  onCancel: (e) ->
    Backbone.history.navigate '#<$- underscored_plural $>', true
    false

module.exports = <$- classified $>EditView
