require 'vendor/jquery/jquery.md5.js'
I18n = require 'libs/I18n'

class Form extends Backbone.View
  
  initialize: ->
    @$el.html @options.html if @options.html
    @context = @options.context
    
    # Parse the form for data fields
    @fields = {}
    @$('[data-field]').each (index, element) =>
      tagName = $(element).prop('tagName').toLowerCase()
      fieldName = $(element).attr('data-field')
      editorName = $(element).attr('data-editor')
      optionsName = $(element).attr('data-options')
      
      if editorName
        # Custom editor
        editor = new Form.Editor[editorName]
          el: element
          options: @context?[optionsName]
      else
        # Default editors
        switch tagName
          when 'input'
            type = $(element).attr('type')
            switch type
              when 'number'
                editor = new Form.Editor.Number {el: element}
              when 'password'
                editor = new Form.Editor.Password {el: element}
              when 'checkbox'
                editor = new Form.Editor.Checkbox {el: element}
              else
                editor = new Form.Editor.Text {el: element}
          when 'textarea'
            editor = new Form.Editor.TextArea {el: element}
          when 'select'
            editor = new Form.Editor.Select
              el: element
              options: @context?[optionsName]
          else
            editor = new Form.Editor.Text {el: element}
      
      @fields[fieldName] = {editor}
      
      # Relay the editor's events
      editor.on 'change', =>
        @trigger "change:#{fieldName}", @, editor
        @trigger 'change', @, editor
        @onChange fieldName, editor
      editor.on 'add', (index) =>
        @trigger "add:#{fieldName}", @, index, editor
      editor.on 'remove', (index) =>
        @trigger "remove:#{fieldName}", @, index, editor
      editor.on 'focus', =>
        @trigger "focus:#{fieldName}", @, editor
      editor.on 'blur', =>
        @trigger "blur:#{fieldName}", @, editor
    
    if @model then @update(@model)
  
  update: (model) ->
    @model = model
    @setValue @model.toJSON()
  
  setValue: (attrs) =>
    for fieldName, value of attrs when @fields[fieldName]
      @fields[fieldName].editor.setValue(value)
  
  commit: =>
    @clearAllErrors()
    
    attrs = {}
    for fieldName, field of @fields
      value = field.editor.getValue()
      
      errors = @validate fieldName, value
      if errors
        @fields[fieldName].editor.setError errors
        return errors
      else
        attrs[fieldName] = value if value?
    
    @model.set attrs
    return null
  
  validate: (fieldName, value) =>
    errors = []
    for attribute, validator of @model.validators
      continue unless attribute is fieldName
      if _.isArray(validator)
        _(validator).each (v) =>
          error = @test(fieldName, v, value)
          errors.push error if error
      else
        error = @test(fieldName, validator, value)
        errors.push error if error
    if _.isEmpty(errors)
      return null
    else
      return errors
  
  test: (fieldName, validator, value) ->
    error = null
    valid = true
    if _.isString(validator)
      switch validator
        when 'required'
          if not value?
            valid = false
          else if _.isString(value)
            valid = (value isnt '')
          else if _.isArray(value)
            valid = not _.isEmpty(value)
          else if _.isObject(value)
            if _.isEmpty(value)
              valid = false
            else if value?.id?
              valid = (value.id isnt -1)
            else
              valid = true
          else
            valid = true
          unless valid
            error = str.errors[@model.className]['required'][fieldName]
        when 'email'
          if value? and value isnt ''
            valid = /^[a-zA-Z0-9._%-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$/.test(value)
          unless valid
            error = "Please enter a valid email address."
        when 'password'
          valid = value?.length >= 5
          unless valid
            error = "The password must contain at least 5 characters."
    else if _.isFunction(validator)
      error = validator(value)
    return error
  
  reset: =>
    for fieldName, field of @fields
      field.editor.reset()
  
  onChange: (fieldName, editor) ->
    editor.clearError()
    value = editor.getValue()
    errors = @validate fieldName, value
    if errors
      @fields[fieldName].editor.setError errors
    else
      @model.set fieldName, value
      logging.debug JSON.stringify(@model.toJSON())
  
  clearAllErrors: =>
    for fieldName, field of @fields
      field.editor.clearError()
  
  # Override default remove function in order to remove embedded views
  remove: ->
    for fieldName, field of @fields
      field.editor.remove()
    super

# Editor base class
class Form.Editor extends Backbone.View
  
  defaultValue: null
  
  events:
    'change': 'onChange'
    'focus': 'onFocus'
    'blur': 'onBlur'
  
  initialize: ->
    @setValue @defaultValue
  
  render: =>
    @
  
  getValue: ->
    @$el.val()
  
  setValue: (value) ->
    @$el.val(value) if value?
  
  reset: ->
    @setValue @defaultValue
  
  focus: ->
    return if @hasFocus
    @$el.focus()
  
  blur: ->
    return unless @hasFocus
    @$el.blur()
  
  onChange: =>
    @trigger 'change', @
  
  onFocus: =>
    @trigger 'focus', @
  
  onBlur: =>
    @trigger 'blur', @
  
  setError: (error) =>
    @$el.addClass('rederror')
  
  clearError: =>
    @$el.removeClass('rederror')


# Text Editor
class Form.Editor.Text extends Form.Editor
  
  defaultValue: ''

# Number Editor
class Form.Editor.Number extends Form.Editor
  
  defaultValue: 0
  
  events:
    'keypress': 'onKeypress'
  
  initialize: ->
    super
    # To trigger onChange in Chrome, we have to observe HTML5 'oninput' event.
    @el.oninput = @onChange
  
  # Prevent non-numeric input
  onKeypress: (e) =>
    # # Get the whole new value
    # newVal = @$el.val() + String.fromCharCode(e.which)
    # numeric = /^[0-9]*\.?[0-9]*?$/.test(newVal)
    # return false if not numeric
  
  getValue: =>
    value = @$el.val()
    value = parseInt(value, 10) if _.isString(value)
    value = null if _.isNaN(value)
    return value
  
  setValue: (value) =>
    if _.isNumber(value)
      @$el.val(value)
    else if _.isString(value)
      value = parseInt(value, 10)
      @$el.val(value) unless _.isNaN(value)

# Password Editor
class Form.Editor.Password extends Form.Editor
  
  defaultValue: ''
  
  getValue: => @$el.val()

# TextArea Editor
class Form.Editor.TextArea extends Form.Editor

# Checkbox Editor
class Form.Editor.Checkbox extends Form.Editor
  
  defaultValue: false
  
  getValue: =>
    @$el.prop('checked')
  
  setValue: (value) =>
    @$el.prop 'checked', value

# Checkboxes
class Form.Editor.Checkboxes extends Form.Editor
  
  default: []
  
  optionTemplate: _.template """
    <li><input type="checkbox" name="checkbox-group-<%- id %>" value=<%- id %> class="checkbox" /><%- value %></li>
  """
  
  setOptions: (options) =>
    @collection = options
    @renderOptions()
    @collection.on 'reset', @renderOptions
  
  renderOptions: =>
    @$el.empty()
    if @collection
      @collection.each (model) =>
        $option = $(@optionTemplate(model.toOption()))
        @$el.append $option
    @
  
  render: =>
    @setValue @value
    @trigger 'change', @
    @
  
  getValue: =>
    value = []
    @$(':checked').each (index, element) ->
      id = $(element).val()
      id = parseInt(id, 10) unless _.isNaN(parseInt(id, 10))
      value.push {id}
    value
  
  setValue: (value) =>
    @value = value
    if @collection
      # Pluck all ids
      ids = _(value).pluck('id')
      @$(':checkbox').each (index, element) ->
        checked = parseInt($(element).val(), 10) in ids
        $(element).prop 'checked', checked

# Select Editor
class Form.Editor.Select extends Form.Editor
  
  defaultValue: -1
  
  optionTemplate: _.template """
    <option value=<%- id %>><%- value %></option>
  """
  
  initialize: (options) ->
    @value = @defaultValue
    if options.options
      @setOptions options.options
  
  setOptions: (options) =>
    @options = options
    @renderOptions()
    if @options instanceof Backbone.Collection
      @options.on 'reset', @renderOptions
  
  renderOptions: =>
    @$el.empty()
    
    $firstOption = $(@optionTemplate({id: -1, value: 'Select'}))
    @$el.append $firstOption
    
    if @options instanceof Backbone.Collection
      @options.each (model) =>
        $option = $(@optionTemplate(model.toOption()))
        @$el.append $option
    @render()
  
  onChange: =>
    @trigger 'change:selection', @
  
  render: =>
    @$el.val(@value)
    @trigger 'change:selection', @
    @
  
  getValue: =>
    value = @$el.val()
    value = parseInt(value, 10) unless _.isNaN(parseInt(value, 10))
    if value is 'true' then value = true
    if value is 'false' then value = false
    
    if @options instanceof Backbone.Collection
      if value isnt -1
        {id: value}
      else
        null
    else
      value
  
  setValue: (value) =>
    @value = value?.id ? value
    @$el.val(@value)
  
  reset: =>
    @value = @defaultValue
    @$el.val(@value)
  
  setError: (error) =>
    @$el.parent().addClass('rederror')
  
  clearError: =>
    @$el.parent().removeClass('rederror')


# Date Editor
class Form.Editor.Date extends Form.Editor
  
  initialize: (options) ->
    # Set data formats
    @displayDateFormat = 'mm/dd/yy'
    @serverDateFormat = 'yy-mm-dd'
    
    # Use jQuery UI's date picker
    @$el.datepicker {dateFormat: @displayDateFormat}
  
  convertDateFormat: (from, to, value) ->
    date = $.datepicker.parseDate(from, value)
    $.datepicker.formatDate to, date
  
  setValue: (value) =>
    @value = @convertDateFormat(@serverDateFormat, @displayDateFormat, value)
    @$el.val(@value)
  
  getValue: =>
    value = @$el.val()
    @convertDateFormat(@displayDateFormat, @serverDateFormat, value)
  
  reset: ->
    @$el.datepicker 'setDate', null

# DateTime Editor
class Form.Editor.DateTime extends Form.Editor
  
  initialize: (options) ->
    # Set data formats
    @displayDateFormat = 'mm/dd/yy'
    
    # Use jQuery UI's date picker
    @$('input').datepicker {dateFormat: @displayDateFormat}
  
  setValue: (timestamp) =>
    date = new Date(timestamp)
    @$('input').val $.datepicker.formatDate(@displayDateFormat, date)
    
    hours = date.getHours()
    minutes = date.getMinutes()
    ampm = (if hours >= 12 then 'PM' else 'AM')
    hours = hours % 12
    if ampm is 'PM' and hours is 0
      hours = 12
    
    @$("select[name='hours']").val hours
    @$("select[name='minutes']").val minutes
    @$("select[name='ampm']").val ampm
  
  getValue: =>
    date = @$('input').val()
    hours = @$("select[name='hours']").val()
    minutes = @$("select[name='minutes']").val()
    ampm = @$("select[name='ampm']").val()
    dateTimeString = "#{date} #{hours}:#{minutes} #{ampm}"
    (new Date(dateTimeString)).getTime()
  
  reset: ->
    @$('input').datepicker 'setDate', null
    @$("select[name='hours']").val(0)
    @$("select[name='minutes']").val(0)
    @$("select[name='ampm']").val('AM')

module.exports = Form