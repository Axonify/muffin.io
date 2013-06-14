fs = require 'fs-extra'
sysPath = require 'path'
logging = require '../lib/logging'

install = (name, version='master') ->
  if version is '*'
    version = 'master'
  logging.info "Installing #{name}@#{version}..."

module.exports = {install}
