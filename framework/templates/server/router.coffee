<$- classified $>Controller = require './controllers/<$- classified $>Controller'

  # <$- classified $>
  app.get '/<$- underscored_plural $>', <$- classified $>Controller.index
  app.get '/<$- underscored_plural $>/:id', <$- classified $>Controller.show
  app.post '/<$- underscored_plural $>', <$- classified $>Controller.create
  app.put '/<$- underscored_plural $>/:id', <$- classified $>Controller.update
  app.delete '/<$- underscored_plural $>/:id', <$- classified $>Controller.destroy