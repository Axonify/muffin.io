# A superclass for Muffin plugins of type 'compiler'.

class Compiler

  type: 'compiler'
  nowrap: false

  # Inspect JavaScript content to infer dependencies.
  # Borrowed from [require.js](http://requirejs.org/).
  parseDeps: (content) ->
    commentRegex = /(\/\*([\s\S]*?)\*\/|([^:]|^)\/\/(.*)$)/mg
    cjsRequireRegex = /[^.]\s*require\s*\(\s*["']([^'"\s]+)["']\s*\)/g

    # Find all the require calls and push them into dependencies.
    deps = []
    content
      .replace(commentRegex, '') # remove comments
      .replace(cjsRequireRegex, (match, dep) -> deps.push(dep) if dep not in deps)
    deps

module.exports = Compiler
