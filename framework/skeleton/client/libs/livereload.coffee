# NO_AMD_PREFIX
WebSocket = window.WebSocket ? window.MozWebSocket
return unless WebSocket

window.onload = ->
  host = window.location.hostname
  port = <?= (settings.liveReload && settings.liveReload.port) ? settings.liveReload.port : 9485 ?>
  connection = new WebSocket("ws://#{host}:#{port}")
  connection.onmessage = onMessage

onMessage = (e) ->
  message = JSON.parse(e.data)
  if message.reload is 'soft'
    switch message.type
      when 'css'
        tags = document.getElementsByTagName('link')
        for i in [0...tags.length]
          if tags[i].getAttribute('rel') is 'stylesheet'
            url = tags[i].getAttribute('href')
            url = url.replace(/\?.*$/, '')
            if message.path.match(url)
              tags[i].setAttribute('href', cacheBuster(url))
      when 'image'
        tags = document.getElementsByTagName('img')
        for i in [0...tags.length]
          url = tags[i].getAttribute('src')
          url = url.replace(/\?.*$/, '')
          if message.path.match(url)
            tags[i].setAttribute('src', cacheBuster(url))
      when 'module'
        if /\.css$/.test(message.path)
          # We only need to reload the css module if it's already applied.
          tag = getElementByAttributeValue('data-path', message.path)
          if tag
            tag.parentNode.removeChild(tag)
            require.undef message.path
            require [message.path], -> {}
        else
          window.location.reload(true)
  else
    # Hard refresh
    window.location.reload(true)

cacheBuster = (url) ->
  date = Math.round(Date.now() / 1000).toString()
  url + (if url.indexOf('?') >= 0 then '&' else '?') + 'cacheBuster=' + date

# Get any one element by a certain attribute value
getElementByAttributeValue = (attribute, value) ->
  for element in document.getElementsByTagName('*')
    return element if element.getAttribute(attribute) is value