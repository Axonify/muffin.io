Plugin = require '../Plugin'
less = require 'less'

class LessCompiler extends Plugin

  type: 'compiler'

  compile: ->
    sourceData = fs.readFileSync(source).toString()
    filename = sysPath.basename(source, sysPath.extname(source)) + '.css'
    path = sysPath.join destDir, filename

    parser = new (less.Parser)
      paths: [sysPath.dirname(source)]
    parser.parse sourceData, (err, tree) ->
      fs.writeFileSync path, tree.toCSS()
      logging.info "compiled #{source}"
      server.reloadBrowser(path)

module.exports = LessCompiler
