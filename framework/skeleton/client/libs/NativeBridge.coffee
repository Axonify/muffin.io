class NativeBridge
  
  sendMessage: (msg) ->
    if $os.ios and $os.browser isnt 'safari'
      # Check $os.browser to make sure we are in the native wrapper, not Mobile Safari.
      iframe = document.createElement('iframe')
      iframe.setAttribute('src', "js:#{encodeURIComponent(JSON.stringify(msg))}")
      document.documentElement.appendChild(iframe)
      iframe.parentNode.removeChild(iframe)
      iframe = null
    else if $os.android
      try AxonifyAndroid.sendMessage(JSON.stringify(msg))
    else if $os.windowsphone
      try window.external.notify(JSON.stringify(msg))
    return
  
  handleMessage: (msg) -> {}

module.exports = NativeBridge