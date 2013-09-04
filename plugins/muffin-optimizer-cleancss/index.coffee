fs = require 'fs'
cleanCSS = require 'clean-css'

module.exports = (env, callback) ->

  class CleanCSSOptimizer extends env.Optimizer

    type: 'optimizer'
    extensions: ['.css']

    optimize: (source, dest, callback) ->
      # Use clean-css to minify the css file
      result = cleanCSS.process(source)
      fs.writeFileSync dest, result
      callback(null, result)

  callback(new CleanCSSOptimizer())
