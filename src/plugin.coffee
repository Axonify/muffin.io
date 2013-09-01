project = require './project'

class Plugin

  cacheBuster: (force) ->
    if project.clientConfig.cacheBuster or force
      "?_#{(new Date()).getTime()}"
    else
      ''

module.exports = Plugin
