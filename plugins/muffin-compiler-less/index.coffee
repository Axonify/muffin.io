less = require 'less'

module.exports = (env, callback) ->

  class LessCompiler extends env.Compiler

    type: 'compiler'
    extensions: ['less']

    compile: (data, path, callback) ->
      sourceData = fs.readFileSync(source).toString()
      filename = sysPath.basename(source, sysPath.extname(source)) + '.css'
      path = sysPath.join destDir, filename

      options = {paths: [sysPath.dirname(source)]}
      parser = new (less.Parser)(options)
      parser.parse sourceData, (err, tree) ->
        compiledData = tree.toCSS()
        logging.info "compiled #{source}"
        fs.writeFileSync path, compiledData
        callback(err, compiledData)

  callback(new LessCompiler())
