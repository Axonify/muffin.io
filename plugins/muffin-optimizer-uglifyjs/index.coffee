fs = require 'fs'
UglifyJS = require 'uglify-js'

module.exports = (env, callback) ->

  class UglifyJSOptimizer extends env.Optimizer

    extensions: ['.js']

    optimize: (source, dest, callback) ->
      # Use uglifyjs to minify the js file
      result = UglifyJS.minify([source], {compress: {comparisons: false}})
      fs.writeFileSync dest, result.code
      callback(null, result.code)

  callback(new UglifyJSOptimizer())
