## TODO
- partial object graph, local storage, support conditional GET and batch operations in REST APIs
- review muffin code once more (compile files synchronously?); add back startDummyServer; speed up the build process; fix 20% cpu usage when idle;
- fix `muffin new`, `muffin generate`, `muffin minify`
- implement `muffin update`, `muffin search`
- convert other Backbone UI components/widgets to TJ components
- **muffin.apps.admin**
  * Generate the admin site similar to WordPress or Django
  * apps/admin/#dashboard - monitor server/stats (Ganglia integration?)
  * an admin console like the one for Google App Engine
  * a JavaScript error log service
- **muffin.apps.flatpages**: Jeckyll style **static site generator** using JSON files
- **themes**: easily apply themes to the site, similar to WordPress
- **ioSync support**, real-time pushes on both NodeJS and GAE (via Channel API)
- **muffin test**: unit testing with Mocha, and headless testing with Zombie.js or Selenium. Phantom.js, Bunyip. Load testing (https://github.com/gamechanger/nodeload)
- muffin.io website (show off interactive features, video demo, good documentation, prezi, host on Nodejitsu)
- Sublime Text 2 plugin
- A web interface as an alternative to using commands that supports creating a new project, choose project type (mobile, static, desktop), and change themes.
- Eventually, the web interface might trump the command line interface. At that point we can do all the work in the browser, from creating a project, to coding, to deployment. Muffin will become a cloud service to easily create interactive webapps. (Imagine saving code in one browser window, and the other browser window auto reloads the page.)
- Integrate with iPython. Supports advanced scientific computing functionalities.
- Use Muffin to build interactive ebooks!
- Use Muffin to create interactive online courses
- Data syncing: partial object graph, local storage, support conditional GET and batch operations in REST APIs.
- Deployment: Amazon EC2. multi-core (clustering) support for Node.js deployment, as done in Geddy.  Integrate with Google Analytics. Integrate with {errorception}. (Spar). Ganglia integration?
- Learn from Yeoman, Mimosa, mojito
- Revisit Brunch, capt, backnode, bones, bbb, Brewer.js, Tower.js, singool
- Backbone.shortcuts (keymaster.js)
- improve Backbone.Forms, learn from [django.forms](http://www.djangobook.com/en/2.0/chapter07.html)

Remember that the goal of Muffin is to build the next-generation web apps - highly interactive and real-time. Even static sites can be interactive. There shouldn't be a line between single page webapps and static sites; after all, both are merely static files rendered by the browser. That's why Muffin is also a natural fit for building WordPress, JekyII style static sites.
