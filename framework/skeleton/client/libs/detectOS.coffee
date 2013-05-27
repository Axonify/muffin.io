# NO_AMD_PREFIX

# Detect mobile platforms by parsing user agent
detectOS = ->
  ua = navigator.userAgent
  os = {}
  
  desktop = ua.match(/(Macintosh;|Windows NT|X11;)/)
  webkit = ua.match(/WebKit\/([\d.]+)/)
  android = ua.match(/(Android)\s+([\d.]+)/)
  ipad = ua.match(/(iPad).*OS\s([\d_]+)/)
  iphone = !ipad && ua.match(/(iPhone\sOS)\s([\d_]+)/)
  windowsphone = ua.match(/Windows Phone/)
  blackberry = ua.match(/(BlackBerry|RIM).*Version\/([\d.]+)/)
  firefox = ua.match(/(Firefox)\/([\d.]+)/)
  operamini = ua.match(/(Opera\sMini)\/([\d.]+)/)
  safari = ua.match(/(Safari)\/([\d.]+)/)
  chrome = ua.match(/Chrome\/([\d.]+)/) || ua.match(/CriOS\/([\d.]+)/)
  
  if desktop
    os.desktop = true
    os.mobile = false
  else
    os.desktop = false
    os.mobile = true
  
  if android
    os.android = true
    os.name = 'android'
    os.version = android[2]
  
  if iphone
    os.ios = os.iphone = true
    os.name = 'iphone'
    os.version = iphone[2].replace(/_/g, '.')
  
  if ipad
    os.ios = os.ipad = true
    os.name = 'ipad'
    os.version = ipad[2].replace(/_/g, '.')
  
  if windowsphone
    os.windowsphone = true
    os.name = 'windowsphone'
  
  if blackberry
    os.blackberry = true
    os.name = 'blackberry'
    os.version = blackberry[2]
  
  if firefox
    os.browser = 'firefox'
    os.version = firefox[2]
  
  if operamini
    os.browser = 'operamini'
  
  if safari
    os.browser = 'safari'
  
  if chrome
    os.browser = 'chrome'
  
  return os

window.$os = detectOS()
