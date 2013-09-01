#
# MainApp sets up UI layout on desktop browsers.
#

I18n = require 'muffin/I18n'
LayoutView = require './views/LayoutView'
Router = require './router'

class App

  initialize: ->
    # Set title
    document.title = I18n.t('title')

    # Set up application layout
    @layout = new LayoutView {el: 'body'}

  createRouter: ->
    @router = new Router()

module.exports = App
