Session = require '../models/Session'
User = require '../models/User'
_ = require 'underscore'

SessionController = 
  # GET /sessions
  index: (req, res) ->
    if req.session.user
      User.findById req.session.user._id, {password: 0, salt: 0}, (err, user) ->
        if user
          res.send {user}
        else
          res.send {}
    else
      res.send {}
  
  # POST /sessions
  create: (req, res, next) ->
    username = req.body.username
    password = req.body.password
    
    User.findOne {$or: [{'username': username}, {'email': username}]}, (err, user) ->
      if user and user.authenticate(password)
        # Generate a new session
        req.session.regenerate (err) ->
          req.session.user = {_id: user.id}
          res.send(req.session)
      else
        res.send(401)
  
  # DELETE /sessions
  destroy: (req, res) ->
    if req.session
      req.session = null
    res.send({})

module.exports = SessionController
