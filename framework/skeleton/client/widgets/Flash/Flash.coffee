Backbone = require 'Backbone'
View = require './View'

class Flash extends View
  
  template: _.template('') # (require 'text!./flash.html')
  
  events:
    'click .close': 'onClose'
  
  initialize: ->
  
  show: (type, message, data) ->
    return unless message?
    
    if data
      tpl = _.template(message)
      message = tpl(data)
    
    @$el.html @template({message})
    switch type
      when 'success'
        @$('.alert').addClass 'alert-success'
      when 'error'
        @$('.alert').addClass 'alert-error'
      when 'info'
        @$('.alert').addClass 'alert-info'
    
    # Scroll the window to top so the error message can be seen.
    $('html, body').animate {scrollTop: 0}, 'normal'
    
    @$el.delay(10000).fadeOut => @remove()
  
  success: (message, data) =>
    @show 'success', message, data
  
  error: (message) =>
    @show 'error', message, data
  
  info: (message, data) =>
    @show 'info', message, data
  
  onClose: (e) ->
    @remove()

module.exports = Flash
