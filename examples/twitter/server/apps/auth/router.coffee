SessionController = require './controllers/SessionController'
UserController = require './controllers/UserController'
User = require './models/User'

# Router
router = (app) ->
  # Authentication middleware
  app.authenticate = (req, res, next) ->
    if req.session.user
      User.findById req.session.user._id, (err, user) ->
        if user
          req.currentUser = user
          next()
        else
          res.send(401)
    else
      res.send(401)
  
  # Session
  app.get '/sessions', SessionController.index
  app.post '/sessions', SessionController.create
  app.delete '/sessions', app.authenticate, SessionController.destroy
  
  # User
  app.post '/users', UserController.create
  app.put '/users/:id', app.authenticate, UserController.update

module.exports = router