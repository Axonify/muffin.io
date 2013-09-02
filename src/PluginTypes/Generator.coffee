fs = require 'fs-extra'
sysPath = require 'path'
_ = require '../utils/_inflection'
project = require './project'

class Generator

  type: 'generator'

  constructor: ->
    @clientDir = project.clientDir
    @serverDir = project.serverDir
    @templateDir = './templates'

  # Create new models/collections from templates
  copyTemplate: (data, mapping) ->
    for from, to of mapping
      ejs = fs.readFileSync(sysPath.join(@templatesDir, from)).toString()
      destDir = sysPath.dirname(to)
      fs.mkdirSync destDir

      _.templateSettings =
        evaluate    : /<\$([\s\S]+?)\$>/g,
        interpolate : /<\$=([\s\S]+?)\$>/g,
        escape      : /<\$-([\s\S]+?)\$>/g

      fs.writeFileSync to, _.template(ejs, data)
      logging.info " * Create #{to}"

  # Inject code into file
  injectIntoFile: (path, code, before, after) ->
    data = fs.readFileSync(path).toString()
    if before?
      index = data.indexOf(before)
      return if index is -1
    else if after?
      index = data.indexOf(after)
      return if index is -1
      index += after.length
    data = data[0...index] + code + data[index..]
    fs.writeFileSync path, data
    logging.info " * Update #{path}"

  # Remove files
  removeFiles: (files) ->
    _(files).each (file) ->
      fs.unlink file, (err) ->
        logging.info " * Removed #{file}" unless err

  # Retrieve the model attributes
  parseAttrs: (args) ->
    attrs = {}
    validTypes = ['String', 'Number', 'Date', 'Buffer', 'Boolean', 'Mixed', 'ObjectId', 'Array']
    for attr in args
      [key, value] = attr.split(':')
      if value then value = _(validTypes).find (type) -> type.toLowerCase() is value.toLowerCase()
      utils.fatal "Must supply a valid schema type for the attribute '#{key}'.\nValid types are: #{validTypes.join(', ')}." unless value?
      attrs[key] = value
    return attrs

module.exports = Generator
