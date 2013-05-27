Backbone = require 'Backbone'

# A subclass of Backbone.View that manages view hierarchy
class View extends Backbone.View

  initialize: ->
    @superview = null
    @subviews = []
    $container = null

  addSubview: (v, preposition='in', $element) ->
    switch preposition
      when 'in'
        # Remove existing subview in the DOM element
        @subviews = _(@subviews).reject (item) -> item['container'][0] is $element[0]
        
        # Push the new view into subviews
        @subviews.push {'container': $element, 'view': v}
        
        # Set up relationships
        v.superview = @
        v.$container = $element
        
        # Render the subview
        $element.html v.render().el
      
      when 'before'
        console.log 'add sub view before'
      when 'after'
        console.log 'add sub view after'
    
    # Inform the subview that it has now appeareds
    v.viewDidAppear()
  
  presentModal: (modal) ->
    $(modal.render().el).lightbox_me
      centered: false
      modalCSS:
        top: "22px"
      overlayCSS:
        background: "black"
        opacity: .6
      closeSelector: ".close"
      onLoad: ->
        modal.viewDidAppear()
  
  dismiss: ->
    @$el.trigger 'close'
  
  viewDidAppear: -> {}

module.exports = View
