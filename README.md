# ![muffin image](https://secure.gravatar.com/avatar/e422d31c03da8d8db685dde4a350eb3d?s=60) muffin.io

**muffin.io** strives to take the bitterness out of modern webapp development by focusing on a small set of remarkable open-source tools such as CoffeeScript, Backbone.js, Node.js and MongoDB, integrating them into a seamless development workflow.

Like a well-written recipe, **muffin.io** provides simple procedures and sensible conventions to assist the web developer in every step of the development process, from project setup to production deployment. It offers Rails-style generators, a build system that supports live reload and compressing files for production, as well as a set of best practices extracted from real-world Backbone webapps.

## Designed for the new generation of webapps

**muffin.io** was designed exclusively for creating the new generation of webapps --- webapps built upon client-side web frameworks such as Backbone.js.

In a client-side web framework, the application UI is entirely rendered on the client side using JavaScript. The server provides a simple RESTful web service that can talk to any type of clients, such as an iOS app, an Android app, or in this case a JavaScript webapp. Only JSON data are sent over the wire. This design significantly reduces the complexity on the server side since all the view states are tracked on the client side. Another significant benefit is that all the client code are in static files (compressed JavaScript files, HTML templates) that can be served on the Content Delivery Network (CDN) and can be cached in the browser, even as offline webapps. As JavaScript performance in major browsers steadily improved in the last few years, client-side web frameworks are quickly gaining traction, as evidenced by the fast-growing list of [real-world projects](http://backbonejs.org/#examples) built on Backbone.js.

An essential ingredient in Backbone's popularity is its minimalist approach: it only provides the bare-bone MVC architecture and does not impose any project structure or build process. However, structure is still needed for anything other than a toy app. **muffin.io** aims to provide some guidance, best practices and utilities to make it easier to develop production-quality Backbone apps.

## Supported backend stacks

A nice benefit of building webapps on a client-side web framework is that the frontend and backend stacks are completely decoupled. This means that you can choose any backend stack you like, be it Ruby on Rails, Java, Node.js or Google App Engine. As long as the backend provides a RESTful web service that speaks JSON, the frontend would happily communicate with it.

So in general, **muffin.io** is agnostic to backend stacks. However, **muffin.io** does have preferred backend stacks if you want to get the maximum benefit out of generators and other features.

Currently **muffin.io** generators can only generate server code on the Node.js/MongoDB stack. Generator support for Google App Engine is in development.

## Features

* Create a new project with `muffin new <project-name>`
* Rails-style generators for models, views and scaffolding, including code for both client and server
* A build system that watches and compiles CoffeeScript, LESS, Jade, and supports live reload
* Concatenates and compresses JavaScript files and HTML templates for production deployment
* A RequireJS-style module loader tightly integrated with the build system
* any many more...

## How does muffin.io compare to similar tools?

**muffin.io** shares some features with other tools such as [Yeoman](http://yeoman.io), [brunch.io](http://brunch.io/), [Meteor](http://meteor.com/) and [mojito](http://developer.yahoo.com/cocktails/mojito/). Here is a comparison table of the features.


    Feature                |   Muffin   |   Yeoman   |   Brunch  
    -----------------------+------------+------------+-----------
    Watch file for changes |    Yes     |    Yes     |    Yes
    Live reload            |    Yes     |    Yes     |    Yes
    Production build       |    Yes     |    Yes     |    Yes
    Auto wrap modules      |    Yes     |    Yes     |    Yes
    Generators for server  |    Yes     |    No      |    No
    ...


