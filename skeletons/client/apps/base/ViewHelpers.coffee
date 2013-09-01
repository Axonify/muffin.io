I18n = require 'muffin/I18n'

ViewHelpers =
  t: (args...) -> I18n.t.apply(I18n, args)

module.exports = ViewHelpers
