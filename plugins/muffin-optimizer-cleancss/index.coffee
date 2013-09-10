fs = require 'fs'
cleanCSS = require 'clean-css'

module.exports = (env, callback) ->

  class CleanCSSOptimizer extends env.Optimizer

    extensions: ['.css']

    optimize: (source, dest, callback) ->
      # Use clean-css to minify the css file
      sourceData = fs.readFileSync(source).toString()
      result = cleanCSS.process(sourceData)
      fs.writeFileSync dest, result
      callback(null, result)

  callback(new CleanCSSOptimizer())
