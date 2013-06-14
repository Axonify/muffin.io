Backbone = require 'Backbone'
UIKit = require 'UIKit'
<$- classified $>List = require '../models/<$- classified $>List'

class <$- classified $>IndexView extends UIKit.View
  
  template: _.tpl(require '../templates/<$- classified $>IndexView.html')
  tbodyTemplate: _.tpl(require '../templates/<$- classified $>ListTable.html')
  
  events:
    'click a.delete': 'onDelete'
  
  initialize: ->
    @$el.html @template()
    
    @fields = @$('table thead th:gt(0)').map ->
      $(this).attr('data-field')
    .get()
    
    # Set up data structures backing the view
    @collection = new <$- classified $>List
    @collection.on 'reset', @render
    @collection.on 'add', @render
    @collection.on 'remove', @render
    @collection.fetch()
  
  render: =>
    $tbody = @$('table tbody').empty()
    $tbody.html @tbodyTemplate({<$- underscored_plural $>: @collection.toJSON(), fields: @fields})
    @
  
  onDelete: (e) ->
    index = $(e.currentTarget).closest('tr').index()
    @collection.at(index).destroy()

module.exports = <$- classified $>IndexView
