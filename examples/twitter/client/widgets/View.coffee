Backbone = require 'Backbone'

# A subclass of Backbone.View that manages view hierarchy
class View extends Backbone.View
  
  addSubview: (v, preposition='in', $c, transition='none') ->
    switch preposition
      when 'at'
        # Remove existing subview in the DOM element
        @subviews = _(@subviews).reject (item) -> item['container'][0] is $c[0]
        
        # Push the new view into subviews
        @subviews.push {'container': $c, 'view': v}
        
        # Set up relationships
        v.superview = @
        v.$container = $c
        
        # Render the subview
        switch transition
          when 'none'
            $c.html v.render().el
          when 'fade'
            $c.animate {opacity: 0}, 100, ->
              $c.html v.render().el
              $c.animate {opacity: 1}, 100
      
      when 'in'
        # Push the new view into subviews
        @subviews ?= []
        @subviews.push {'container': $c, 'view': v}
        
        # Set up relationships
        v.superview = @
        v.$container = $c
        
        # Render the subview
        switch transition
          when 'none'
            $c.append v.render().el
          when 'fade'
            $c.append v.render().el
            v.$el.fadeIn(100)
      
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