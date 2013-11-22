# A Muffin plugin that minifies HTML files.

fs = require 'fs'

module.exports = (env, callback) ->

  class HtmlOptimizer extends env.Optimizer

    extensions: ['.html', '.htm']

    optimize: (path, dest, callback) ->
      # Read the source file
      data = fs.readFileSync(path).toString()

      # Remove comments, line breaks, and whitespace between tags
      data = data.replace(/<!--(.*?)-->/g, '').replace(/\r?\n|\r/g, '').replace(/>\s+</g,'><')

      # Write to dest
      fs.writeFileSync dest, data
      callback(null, data)

  callback(new HtmlOptimizer())
