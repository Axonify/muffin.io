
class Compiler

  cacheBuster: (env, force) ->
    if env.project.clientConfig.cacheBuster or force
      "?_#{(new Date()).getTime()}"
    else
      ''

module.exports = Compiler
