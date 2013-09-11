# A Muffin plugin that minifies CSS files.

fs = require 'fs'
cleanCSS = require 'clean-css'

module.exports = (env, callback) ->

  class CleanCSSOptimizer extends env.Optimizer

    extensions: ['.css']

    optimize: (path, dest, callback) ->
      # Read the source file
      data = fs.readFileSync(path).toString()

      # Run through clean-css
      result = cleanCSS.process(data)

      # Write to dest
      fs.writeFileSync dest, result
      callback(null, result)

  callback(new CleanCSSOptimizer())
