Backbone = require 'Backbone'
UIKit = require 'UIKit'

class LayoutView extends UIKit.View
  
  template: _.tpl(require '../templates/LayoutView.html')
  
  events:
    'click ul.nav li.nav-item': 'onChangeTab'
    'click .logout-btn': 'logout'
  
  initialize: ->
    @$el.html @template()
  
  render: => @
  
  setView: (v) ->
    @addSubview v, 'at', @$('#page-container')
  
  onChangeTab: (e) ->
    $li = $(e.currentTarget)
    $li.closest('.navbar-inner').find('li.nav-item').removeClass('active')
    $li.addClass('active')
  
  selectTab: (tabName) ->
    @$('li.nav-item').removeClass('active')
    @$("li.nav-item[data-tab='#{tabName}']").addClass('active')
  
  logout: (e) ->
    apps.auth.logout()
    false

module.exports = LayoutView