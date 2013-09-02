
module.exports = (env, callback) ->

  class CleanCSSOptimizer extends env.Optimizer

    type: 'optimizer'

    optimize: ->

  callback(new CleanCSSOptimizer())
