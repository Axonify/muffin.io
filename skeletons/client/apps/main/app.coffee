#
# Main App
#

I18n = require 'muffin/I18n'
LayoutView = require './views/LayoutView'
Router = require './router'

class App

  initialize: ->
    # Support Backbone events
    _.extend(@, Backbone.Events)

    # Set title
    document.title = I18n.t('title')

    # Set up application layout
    @layout = new LayoutView {el: 'body'}

  createRouter: ->
    @router = new Router()

module.exports = App
