    # <$- classified $>
    '<$- underscored_plural $>':                    '<$- underscored_plural $>_index'
    '<$- underscored_plural $>/new':                '<$- underscored_plural $>_new'
    '<$- underscored_plural $>/:id':                '<$- underscored_plural $>_show'
    '<$- underscored_plural $>/:id/edit':           '<$- underscored_plural $>_edit'

  <$- underscored_plural $>_index: ->
    <$- classified $>IndexView = require './views/<$- classified $>IndexView'
    v = new <$- classified $>IndexView
    app.layout.setView v

  <$- underscored_plural $>_new: ->
    <$- classified $>NewView = require './views/<$- classified $>NewView'
    v = new <$- classified $>NewView
    app.layout.setView v

  <$- underscored_plural $>_show: (id) ->
    <$- classified $>ShowView = require './views/<$- classified $>ShowView'
    v = new <$- classified $>ShowView {id}
    app.layout.setView v

  <$- underscored_plural $>_edit: (id) ->
    <$- classified $>EditView = require './views/<$- classified $>EditView'
    v = new <$- classified $>EditView {id}
    app.layout.setView v
