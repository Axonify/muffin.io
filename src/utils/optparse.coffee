# `OptParser` is a super simple command line option parser.

class OptParser

  # - `args`: command line arguments
  # - `switches`: a list of tuples, e.g., `[['-h', '--help', 'display this help message'], ...]`.
  parse: (args, switches) ->
    options = {arguments: []}

    i = 0
    while i < args.length
      arg = args[i]
      # If the argument starts with a hyphen, it might be an option.
      if /^-/.test(arg)
        step = 2
        for tuple in switches
          [shortFlag, longFlag, description] = tuple
          if arg is shortFlag or arg is longFlag
            # Remove the leading hyphens `--`
            name = longFlag.substr(2)
            # We assume the next argument is the value of the option.
            value = args[i+1]
            # If the next argument is another option, set the value to `true`.
            if /^-/.test(value)
              value = true
              step = 1
            # If there is no subsequent argument, set the value to `true`.
            value ?= true
            # Store in the options hash
            options[name] = value
            break
        i += step
      else
        # The argument is not an option, so we just copy it into the `arguments` list.
        options.arguments.push arg
        i += 1
    options

# Freeze the OptParser object so it can't be modified later.
module.exports = Object.freeze(new OptParser())
