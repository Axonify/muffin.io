Backbone = require 'Backbone'
<$- classified $> = require './<$- classified $>'

class <$- classified $>List extends Backbone.Collection
  model: <$- classified $>
  url: "<?= settings.baseURL ?>/<$- underscored_plural $>"

module.exports = <$- classified $>List
