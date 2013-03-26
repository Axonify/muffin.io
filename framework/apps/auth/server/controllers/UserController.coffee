User = require '../models/User'

UserController = 
  # GET /users
  index: (req, res) ->
    User.find {}, (err, users) ->
      res.send users
  
  # POST /users
  create: (req, res) ->
    user = new User(req.body)
    user.created_at = user.updated_at = new Date
    user.save (err) ->
      if err
        res.send(err, 422)
      else
        req.session.regenerate (err) ->
          req.session.user = {_id: user.id}
          res.send(user)
  
  # GET /users/:id
  show: (req, res) ->
    User.findById req.params.id, (err, user) ->
      if user
        res.send(user)
      else
        res.send(404)
  
  # PUT /users/:id
  update: (req, res) ->
    User.findById req.params.id, (err, user) ->
      if user
        user.updated_at = new Date
        user.set req.body
        user.save (err) ->
          if err then res.send(err, 422) else res.send(user)
      else
        res.send(404)
  
  # DELETE /users/:id
  destroy: (req, res) ->
    User.findById req.params.id, (err, user) ->
      if user
        user.remove -> res.send(200)
      else
        res.send(404)

module.exports = UserController