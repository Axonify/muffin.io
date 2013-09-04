# A dead simple command line option parser

class OptParser

  parse: (args, switches) ->
    options = {arguments: []}

    i = 0
    while i < args.length
      arg = args[i]
      if /^-/.test(arg)
        for tuple in switches
          [shortFlag, longFlag, description] = tuple
          if arg is shortFlag or arg is longFlag
            name = longFlag.substr(2)
            value = args[i+1]
            options[name] = value ? true
        i += 2
      else
        options.arguments.push arg
        i += 1
    options

module.exports = new OptParser()
