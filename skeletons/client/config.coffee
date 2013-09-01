# Project configurations
# If you change any settings in this file, you need to rerun `muffin watch` or `muffin build`.
module.exports =
  defaultLocale: 'en'
  supportedLocales: ['en']

  build:
    aliases:
      apps: 'javascripts/apps'
      lib: 'javascripts/lib'

    concat: [
      'javascripts/apps/main/start'
    ]

    buildDir: '../server/public'

  development:
    baseURL: '/api/v1'
    assetHost: '/'
    logMaxEntries: 20
    logLevel: 'DEBUG'
    logWriter: 'consoleWriter'
    logFormatter: 'simpleFormatter'
    cacheBuster: true

  production:
    baseURL: '/api/v1'
    assetHost: '/'
    logMaxEntries: 20
    logLevel: 'ERROR'
    logWriter: 'consoleWriter'
    logFormatter: 'simpleFormatter'
    cacheBuster: true
