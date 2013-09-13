Backbone = require 'Backbone'

class LayoutView extends Backbone.View

  template: _.tpl(require '../templates/LayoutView.html')

  events:
    'click .start-btn': 'getStarted'

  initialize: ->
    @$el.html @template()
    @$('.jumbotron').show()
    @$('.getting-started').hide()

  render: => @

  setView: (v) ->
    @$('#page-container').html v.render().el

  getStarted: (e) ->
    @$('.jumbotron').fadeOut 500, =>
      @$('.getting-started').fadeIn()

module.exports = LayoutView
