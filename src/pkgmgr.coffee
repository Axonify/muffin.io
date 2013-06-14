fs = require 'fs-extra'
sysPath = require 'path'
logging = require '../lib/logging'

install = (pkg) ->
  logging.info "Installing #{pkg}..."

module.exports = {install}
