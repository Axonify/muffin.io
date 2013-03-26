Backbone = require 'Backbone'

# Pages are modeled after jQuery Mobile.
# Support page transitions: fade, flip, pop, slide, slidedown, slideup.
# Events: pagebeforehide, pagebeforeshow, pagehide, pageshow.
class Page extends Backbone.View
  
  tagName: 'section'
  className: 'page'
  duration: 300
  
  changePage: (page, options) =>
    options ?= {}
    options.transition ?= 'slide'
    
    $('#wrapper').append page.render().el
    page.parent = @
    
    switch options.transition
      when 'slide'
        # Stage the new page
        page.$el.css
          top: 0
          left: '100%'
        
        # Animate the transition
        @$el.animate {translate3d: -window.innerWidth + 'px, 0, 0'}, @duration, 'ease-out'
        page.$el.animate {translate3d: -window.innerWidth + 'px, 0, 0'}, @duration, 'ease-out'
      
      when 'slideup'
        # Stage the new page
        page.$el.css
          top: '100%'
          left: 0
          'z-index': 3
        
        # Animate the transition
        page.$el.animate {translate3d: "0, #{-@$el.height()}px, 0"}, @duration, 'ease-out'
      
      when 'flip'
        # Stage the new page
        @$el.css
          'z-index': 3
        
        page.$el.css
          '-webkit-transform': 'rotateY(180deg)'
        
        # Animate the transition
        @$el.animate {rotateY: '-180deg'}, 0.8, 'ease-out'
        page.$el.animate {rotateY: '0deg'}, 0.8, 'ease-out'
  
  dismiss: =>
    @$el.animate {translate3d: '0, 0, 0'}, @duration, 'ease-out', =>
      @remove()
  
  pop: =>
    @parent.$el.animate {translate3d: '0, 0, 0'}, @duration, 'ease-out'
    @$el.animate {translate3d: '0, 0, 0'}, @duration, 'ease-out', =>
      @remove()
  
  # reload: (newModule) =>
  #   @undelegateEvents()
  #   @$el.empty()
  #   
  #   newPage = new (newModule.exports) {el: @el}
  #   newPage.parent = @parent
  #   newPage.render()

module.exports = Page