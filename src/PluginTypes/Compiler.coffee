class Compiler

  type: 'compiler'

  parseDeps: (content) ->
    commentRegex = /(\/\*([\s\S]*?)\*\/|([^:]|^)\/\/(.*)$)/mg
    cjsRequireRegex = /[^.]\s*require\s*\(\s*["']([^'"\s]+)["']\s*\)/g
    deps = []

    # Find all the require calls and push them into dependencies.
    content
      .replace(commentRegex, '') # remove comments
      .replace(cjsRequireRegex, (match, dep) -> deps.push(dep) if dep not in deps)
    deps

module.exports = Compiler
