Backbone = require 'Backbone'
UIKit = require 'UIKit'
<$- classified $> = require '../models/<$- classified $>'

class <$- classified $>NewView extends UIKit.View
  
  template: _.tpl(require '../templates/<$- classified $>NewView.html')
  
  events:
    'click form .btn-primary': 'onSubmit'
    'click form .btn.cancel': 'onCancel'
  
  initialize: ->
    @$el.html @template()
    
    # Set up data structures backing the view
    @model = new <$- classified $>
    
    # Set up form
    @form = new UIKit.Form
      el: @$('form')
      model: @model
  
  render: => @
  
  onSubmit: (e) ->
    # Validate the fields and update the model
    errors = @form.commit()
    return false if errors
    
    @model.save {},
      sender: @model
      success: (model, response) =>
        logging.debug "Created <$- classified $>."
        Backbone.history.navigate '#<$- underscored_plural $>', true
      error: (model, response) =>
        logging.debug "Failed to create <$- classified $>."
    false
  
  onCancel: (e) ->
    Backbone.history.navigate '#<$- underscored_plural $>', true
    false

module.exports = <$- classified $>NewView
