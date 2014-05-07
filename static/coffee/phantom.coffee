console.log "Loading a web page"
page = require("webpage").create()
url = "http://localhost:5000/cb.html"

page.onResourceRequested = (request) ->
    console.log('Request ' + JSON.stringify(request, undefined, 4))
page.onResourceReceived = (response) ->
    console.log('Receive ' + JSON.stringify(response, undefined, 4))

page.open url, (status) ->
  #Page is loaded!
  console.log("Page loaded")
  title = page.evaluate(() -> return self.hello())
  console.log('Page hello is ' + title)
  title = page.evaluate(() -> doDecomposition())
  console.log('Page hello is ' + title)
  phantom.exit()
