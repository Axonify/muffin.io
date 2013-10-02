# A simple utility to download files from HTTP or HTTPS.
# Supports transparent gzip decompression.

fs = require 'fs-extra'
http = require 'http'
https = require 'https'
zlib = require 'zlib'
{parse} = require 'url'
netrc = require 'netrc'

class Request

  get: (url, dest, done) ->
    {hostname, path} = parse(url)
    options = {hostname, path, headers: {'Accept-Encoding': 'gzip'}}

    if dest
      # Save file to disk
      onEnd = (res) ->
        stream = fs.createWriteStream(dest)
        if res.headers['content-encoding'] in ['gzip', 'deflate']
          unzip = zlib.createUnzip()
          res.pipe(unzip).pipe(stream)
        else
          res.pipe(stream)
    else
      # Return the response body
      onEnd = (res) ->
        res.on 'data', (chunk) ->
          if res.headers['content-encoding'] in ['gzip', 'deflate']
            zlib.unzip chunk, (err, buffer) ->
              if err
                done(err)
              else
                done(null, buffer.toString())
          else
            done(null, chunk)

    if /https:/.test(url)
      req = https.request options, onEnd
    else
      req = http.request options, onEnd

    # authorize call
    account = netrc()[hostname]
    if account
      req.auth(account.login, account.password)

    req.on 'error', done
    req.end()

# Freeze the object so it can't be modified later.
module.exports = Object.freeze(new Request())
