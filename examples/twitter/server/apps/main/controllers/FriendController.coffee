User = require '../../auth/models/User'

FriendController = 
  # GET /users/:id/friends
  index: (req, res) ->
    User
    .findById(req.params.id)
    .populate('friends')
    .exec (err, user) ->
      if err
        res.send(404)
      else
        res.send(user.friends)
  
  # POST /users/:id/follow/:fid
  create: (req, res) ->
    User.findById req.params.id, (err, user) ->
      if user
        User.findById req.params.fid, (err, friend) ->
          if friend
            user.friends ?= []
            user.friends.push friend
            user.friendCount += 1
            
            user.save (err) ->
              if err
                res.send(err, 422)
              else
                friend.followers ?= []
                friend.followers.push user
                friend.followerCount += 1
                
                friend.save (err) ->
                  if err then res.send(err, 422) else res.send({})
          else
            res.send(404)
      else
        res.send(404)
  
  # DELETE /users/:id/unfollow/:fid
  destroy: (req, res) ->
    User.findById req.params.id, (err, user) ->
      if user
        index = user.friends.indexOf(req.params.fid)
        if index isnt -1 then delete user.friends[index]
        res.send({})
      else
        res.send(404)

module.exports = FriendController