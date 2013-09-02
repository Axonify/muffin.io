
module.exports = (env, callback) ->

  class UglifyJSOptimizer extends env.Optimizer

    type: 'optimizer'

    optimize: ->

  callback(new UglifyJSOptimizer())
