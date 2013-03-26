User = require '../../auth/models/User'

RecommendedController = 
  # GET /users/:id/recommended
  index: (req, res) ->
    User.findById req.params.id, (err, user) ->
      if user
        exclude = [user.id].concat(user.friends)
        User
        .find({_id: {$nin: exclude}})
        .select('email name username profileImageUrl')
        .limit(20)
        .exec (err, users) ->
          if err
            res.send(404)
          else
            res.send(users)
      else
        res.send(404)

module.exports = RecommendedController