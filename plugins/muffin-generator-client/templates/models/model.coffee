Backbone = require 'Backbone'

class <$- classified $> extends Backbone.Model
  urlRoot: "<?= settings.baseURL ?>/<$- underscored_plural $>"

module.exports = <$- classified $>
