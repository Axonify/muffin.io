project = require './project'

class Compiler

  cacheBuster: (force) ->
    if project.clientConfig.cacheBuster or force
      "?_#{(new Date()).getTime()}"
    else
      ''

module.exports = Compiler
