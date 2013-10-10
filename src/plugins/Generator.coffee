# A superclass for Muffin plugins of type 'generator'.

fs = require 'fs-extra'
sysPath = require 'path'
_ = require 'underscore'
logging = require '../utils/logging'

class Generator

  type: 'generator'

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
      logging.info " * Created #{sysPath.relative(process.cwd(), to)}"

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
    logging.info " * Updated #{sysPath.relative(process.cwd(), path)}"

  # Remove files
  removeFiles: (files) ->
    for file in files
      fs.unlinkSync file
      logging.info " * Removed #{sysPath.relative(process.cwd(), file)}"

  # Retrieve the model attributes
  parseAttrs: (args) ->
    attrs = {}
    validTypes = ['String', 'Number', 'Date', 'Boolean']
    for attr in args
      [key, value] = attr.split(':')
      if value then value = _(validTypes).find (type) -> type.toLowerCase() is value.toLowerCase()
      logging.fatal "Must supply a valid schema type for the attribute '#{key}'.\nValid types are: #{validTypes.join(', ')}." unless value?
      attrs[key] = value
    return attrs

module.exports = Generator
