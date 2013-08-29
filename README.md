# ![muffin image](https://secure.gravatar.com/avatar/e422d31c03da8d8db685dde4a350eb3d?s=60) muffin.io

Muffin is a full stack development tool for creating modern webapps. It is designed to help the developer become more productive without getting in the way. It is designed for real developers working on real-world projects.

It focuses on addressing a few key issues, such as the build process, module loading and package management, without adding extra layers of complexity on top of existing frameworks. It encourages a component-based approach to webapp development — building large, complex webapps from small, reusable components. It doesn’t try to cater to every project or every developer’s needs, but instead concentrates on perfecting a carefully-selected, highly-opinionated development process featuring CoffeeScript and Backbone.js.

Muffin is available for use under the [MIT software license](https://raw.github.com/Axonify/muffin.io/master/LICENSE).


## Introduction

Over the last few years a new trend in webapp development has emerged. A growing number of prominent webapps are now built upon client-side web frameworks, most notably Backbone.js and Ember.js, instead of server-side web frameworks such as Rails and Django. 

However, tooling for creating the new generation of webapps is still severely lacking. There are a lot of options out there, but none solves the problem particularly well. Some tools add extra layers of complexity on top of the elegant but unopinionated Backbone.js, some try to mimic behaviors of server-side frameworks such as Rails, and others try to support a large variety of development workflows but end up not supporting any of them remarkably well. Muffin is a tool that tries to solve this problem better.

If you want a quick overview of how Muffin does things differently, here is a short video introducing Muffin.

<a href="http://www.youtube.com/watch?feature=player_embedded&v=YOUTUBE_VIDEO_ID_HERE" target="_blank"><img src="http://img.youtube.com/vi/YOUTUBE_VIDEO_ID_HERE/0.jpg" alt="IMAGE ALT TEXT HERE" width="240" height="180" border="10" /></a>


## Installation

You'll need to have Node.js installed. You can download Node.js binary installers [here](http://nodejs.org/download/). 

    $ [sudo] npm install -g muffin.io

Muffin comes with a commandline tool aptly named `muffin`.

To use Google App Engine as your backend stack, you need to install the [Google App Engine SDK for Python](https://developers.google.com/appengine/downloads#Google_App_Engine_SDK_for_Python).

To use the Node.js/MongoDB stack, you need to [install MongoDB](http://docs.mongodb.org/manual/installation/). The easiest way to install MongoDB on Mac OS X is via Homebrew.

    $ brew update
    $ brew install mongodb


## Quick Start

Create a new project:

    $ muffin new <app-name>

Install dependencies:

    $ cd /path/to/your/app
    $ muffin install

Start the server:

    $ muffin server

Now point your browser to `http://localhost:4000` and see your app in action.


## Design Philosophy

Muffin has a small but powerful core, which focuses on solving a few key issues pertaining to all client-side webapps. Such issues include:

* A development build process that supports file watching, live reload, debugging, etc.
* A production build process that supports file concatenation, compression, cache busting, etc.
* A module loader that supports asynchronous module loading, automatic dependency loading, etc.
* A package management system that provides easy installation and updates of packages, including both modules and traditional scripts.
An automatic dependency management system that doesn’t require manual configuration.


## Features

Muffin is optimized for developer's productivity. It offers many features to make it easier to build client-side webapps.

* Convention over configuration
* Use modern languages
* Write modular code
* A frictionless build process
* Rails-style generators 
* Explicit over implicit
* Frontend: Backbone.js + CoffeeScript
* Backends: Google App Engine or NodeJS/MongoDB
* Scalable
* Mobile Friendly
* Muffin is DRY


## Muffin Commands

### Create a new project

    $ muffin new PROJECT_NAME

You can specifiy the boilerplate code for client and server.

    $ muffin new PROJECT_NAME --client github.com/muffin/boilerplate-client --server github.com/muffin/boilerplate-gae

### Generators

    $ muffin generate model user
    $ muffin generate view UserListView
    $ muffin generate scaffold user name:string email:string age:number --app auth

### Remove generated code

    $ muffin destroy model user
    $ muffin destroy view UserListView
    $ muffin destroy scaffold user --app auth

### Package management

    $ muffin install <package-name>
    $ muffin install (installs all the frontend dependencies specified in package.json)
    $ muffin update <package-name>
    * muffin update (updates all the frontend dependencies)

### Watch for file changes

    $ muffin watch

Watch the current project and recompile as needed.

### Build the app

    $ muffin build

Compile coffeescripts into javascripts and copy assets to `public/` directory.

### Run the server

    $ muffin server

Serve the app on port 3000 while watching static files.

### Minify for production

    $ muffin minify

Minify and concatenate js/css files, optimize png/jpeg images, build for production.

### Clean

    $ muffin clean

Remove the build directory.


## Project Structure

Default project structure:

    PROJECT_DIR/
      client/
        apps/
        assets/
        components/
      server/
        apps/
        components/
        public/
      README.md
      config.json


## Configuration

You can specify configuration options for your project in `config.json`.


## Preprocessing

Muffin can preprocess the files before compiling or copying them into the public folder. This is a powerful feature you can use to set up customize the build for different environments, for example, different cache busting policies for development and production environment.

All the preprocessing code should be wrapped in escape tags including `<?= ?>`, `<? ?>` or `<?- ?>`. Muffin simply run the Underscore template engine through the files before compilation.

During the preprocessing, Muffin provides a `settings` object and a few helpers (specific to the file type) to the template function.

For example, you can use this feature to selectively add cache busters.

    <? if (settings.env === 'development') { ?>
      tag.src += "?_#{(new Date()).getTime()}"
    <? } ?>


### HTML/Jade helper

Create a link tag with cache busters appended.

    <?= link_tag(link, attrs) ?>

Create a stylesheet tag with cache busters appended.

    <?= stylesheet_link_tag(link, attrs) ?>

Create a script tag with cache busters appended.

    <?= script_tag(src, attrs) ?>

Inlcude the module loader. For development, this includes a non-minified version in place. For production, a minified version of the module loader is included in place.

    <?= include_module_loader() ?>

Include the live reload module. This is only for development, and has no effect on production build.

    <? = include_live_reload() ?>


## Module Loader

With Muffin you can write clean, modular JavaScript/CoffeeScript in the CommonJS format. Each file in Muffin corresponds to a module.

A simple example for a `Backbone.Model`:

```coffeescript
Backbone = require 'Backbone'

class User extends Backbone.Model
  initialize: -> {}

module.exports = User
```

So in another file, you can import the `User` module.

```coffeescript
Backbone = require 'Backbone'
User = require './User'

class UserList extends Backbone.Collection
  model: User
  initialize: -> {}

module.exports = UserList
```

Muffin automatically wraps the CommonJS modules into a AMD-compatible format during the build process. For example the User model above compiles into:

```javascript
define('javascripts/apps/main/models/User', ["Backbone"], function(require, exports, module) {
  ...
  module.exports = User;
});
```

Note that the first argument in the `define` function is the module path, the second argument is the module's dependencies, and the third argument is the module's factory function. Muffin introspects the file content and automatically sets the module dependencies. This makes module loader's job easier.


## Resources

### Videos

* [Introducing Muffin](http://www.youtube.com)
* [Build a Twitter Clone in 20 Mins](http://www.youtube.com)

### Blog posts

* [Muffin Series 1: Introducing Muffin](http://yaoganglian.com/articles/muffin-series-1/)
* [Muffin Series 2: The Evolution of Web Development](http://yaoganglian.com/articles/muffin-series-2/)
* [Muffin Series 3: Muffin's Features](http://yaoganglian.com/articles/muffin-series-3/)

### Tutorials

* [Muffin Tutorial: Build a Twitter Clone in 20 Mins (Part 1)]()
* [Muffin Tutorial: Build a Twitter Clone in 20 Mins (Part 2)]()
* [Muffin Tutorial: Build a Twitter Clone in 20 Mins (Part 3)]()
* [Muffin Tutorial: Build a Personalized RSS Reader (Part 1)]()
* [Muffin Tutorial: Build a Personalized RSS Reader (Part 2)]()
* [Muffin Tutorial: Build a Personalized RSS Reader (Part 3)]()
