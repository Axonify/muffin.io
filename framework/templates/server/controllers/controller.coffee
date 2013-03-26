<$- classified $> = require '../models/<$- classified $>'

<$- classified $>Controller = 
  # GET /<$- underscored_plural $>
  index: (req, res) ->
    <$- classified $>.find {}, (err, <$- underscored_plural $>) ->
      res.send <$- underscored_plural $>
  
  # POST /<$- underscored_plural $>
  create: (req, res) ->
    <$- underscored $> = new <$- classified $>(req.body)
    <$- underscored $>.created_at = <$- underscored $>.updated_at = new Date
    <$- underscored $>.save (err) ->
      if err then res.send(err, 422) else res.send(<$- underscored $>)
  
  # GET /<$- underscored_plural $>/:id
  show: (req, res) ->
    <$- classified $>.findById req.params.id, (err, <$- underscored $>) ->
      if <$- underscored $>
        res.send(<$- underscored $>)
      else
        res.send(404)
  
  # PUT /<$- underscored_plural $>/:id
  update: (req, res) ->
    <$- classified $>.findById req.params.id, (err, <$- underscored $>) ->
      if <$- underscored $>
        <$- underscored $>.updated_at = new Date
        <$- underscored $>.set req.body
        <$- underscored $>.save (err) ->
          if err then res.send(err, 422) else res.send(<$- underscored $>)
      else
        res.send(404)
  
  # DELETE /<$- underscored_plural $>/:id
  destroy: (req, res) ->
    <$- classified $>.findById req.params.id, (err, <$- underscored $>) ->
      if <$- underscored $>
        <$- underscored $>.remove -> res.send(200)
      else
        res.send(404)

module.exports = <$- classified $>Controller