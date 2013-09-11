# A Muffin plugin that minifies JavaScript.

fs = require 'fs'
UglifyJS = require 'uglify-js'

module.exports = (env, callback) ->

  class UglifyJSOptimizer extends env.Optimizer

    extensions: ['.js']

    optimize: (path, dest, callback) ->
      # Use uglifyjs to minify the js file
      result = UglifyJS.minify([path], {compress: {comparisons: false}})

      # Write to dest
      fs.writeFileSync dest, result.code
      callback(null, result.code)

  callback(new UglifyJSOptimizer())
