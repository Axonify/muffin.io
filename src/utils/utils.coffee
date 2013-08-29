#
# utils.coffee
#

logging = require './logging'

# Print an error and exit.
fatal = (message) ->
  logging.error message + '\n'
  process.exit 1

module.exports = {fatal}
