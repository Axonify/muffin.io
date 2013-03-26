# Build configuration
module.exports =
  paths:
    jquery: 'vendor/jquery/jquery-1.7.2.min.js'
    underscore: 'vendor/underscore/underscore.js'
    Backbone: 'vendor/backbone/backbone.js'
    apps: 'javascripts/apps'
    libs: 'javascripts/libs'
    UIKit: 'javascripts/widgets/UIKit'
  
  shim:
    'underscore':
      deps: ['jquery']
      exports: '_'
    'Backbone':
      deps: ['jquery', 'underscore']
      exports: 'Backbone'
  
  build: [
    'javascripts/apps/main/start'
  ]