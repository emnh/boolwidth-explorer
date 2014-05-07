console.log "Loading a web page"
page = require("webpage").create()
url = "http://localhost:5000/cb.html"
page.open url, (status) ->
  #Page is loaded!
  console.log("Page loaded")
  phantom.exit()
  return
