project = require './project'

class Plugin

  cacheBuster: (force) ->
    if project.clientSettings.cacheBuster or force
      "?_#{(new Date()).getTime()}"
    else
      ''

module.exports = Plugin
