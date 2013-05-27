# Project configurations
# If you change any settings in this file, you need to rerun `muffin watch` or `muffin build`.
module.exports =
  # Installed apps and widgets
  installed_apps: [
    'session'
  ]
  installed_widgets: []
  
  # Client app settings
  clientSettings:
    app: 'myapp'
    version: '0.0.1'
    defaultLocale: 'en'
    supportedLocales: ['en']
    
    development:
      baseURL: '/api/v1'
      assetHost: '/'
      logMaxEntries: 20
      logLevel: 'DEBUG'
      logWriter: 'consoleWriter'
      logFormatter: 'simpleFormatter'
      cacheBuster: true
      liveReload:
        src: 'javascripts/libs/livereload.js'
        port: 9485
    
    production:
      baseURL: '/api/v1'
      assetHost: '/'
      logMaxEntries: 20
      logLevel: 'ERROR'
      logWriter: 'consoleWriter'
      logFormatter: 'simpleFormatter'
      cacheBuster: true
  
  # Test
  test:
    reporter: 'spec'
