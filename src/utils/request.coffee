#
# A simple utility to download files via HTTP requests.
# Supports gzip decompression and HTTPS.
#

fs = require 'fs-extra'
http = require 'http'
https = require 'https'
zlib = require 'zlib'
{parse} = require 'url'
#netrc = require 'netrc'

request =
  get: (url, dst, done) ->
    {hostname, path} = parse(url)
    options = {hostname, path, headers: {'Accept-Encoding': 'gzip'}}

    if dst
      # Save file to disk
      onEnd = (res) ->
        stream = fs.createWriteStream(dst)
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
    # @netrc = netrc(options.netrc)
    # netrc = @netrc[parse(url).hostname]
    # if netrc
    #   req.auth(netrc.login, netrc.password)

    req.on 'error', (err) ->
      return done(err)

    req.end()

module.exports = request
