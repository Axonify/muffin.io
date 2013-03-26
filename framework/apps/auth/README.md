# Installation Procedures
1. `muffin install app auth`
2. Inside 'start.coffee', add the following code:
<code>
    # Create auth app
    AuthApp = require '../auth/app'
    apps.auth = new AuthApp
    apps.auth.initialize()
    ...
    # Ignore initial route. Let AuthApp redirect.
    Backbone.history.start {silent: true}
     
    # Get session info and redirect.
    apps.auth.getSession()
</code>