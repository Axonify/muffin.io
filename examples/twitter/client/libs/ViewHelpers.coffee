I18n = require 'libs/I18n'

ViewHelpers =
  t: (args...) -> I18n.t.apply(I18n, args)

module.exports = ViewHelpers