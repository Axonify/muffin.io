User = require '../../auth/models/User'

FollowerController = 
  # GET /users/:id/followers
  index: (req, res) ->
    User
    .findById(req.params.id)
    .populate('followers')
    .exec (err, user) ->
      if err
        res.send(404)
      else
        res.send(user.followers)

module.exports = FollowerController