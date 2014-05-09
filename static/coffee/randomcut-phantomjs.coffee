console.log "Loading a web page"
page = require("webpage").create()
url = "http://localhost:5000/cb.html"
system = require('system')
args = system.args

#page.onResourceRequested = (request) ->
#  console.log('Request ' + JSON.stringify(request, undefined, 4))
#page.onResourceReceived = (response) ->
#  console.log('Receive ' + JSON.stringify(response, undefined, 4))

page.onConsoleMessage = (msg) ->
  console.log(msg)
  if msg.indexOf("results") > -1
    try
      [id, label, results] = msg.split(" ")
      results = JSON.parse(results)
      fname = results.fname
      mat_fname = path.join('out', results.fname)
      fs.mkdirp(mat_fname, () -> console.log("made #{mat_fname}"))
      #fs.write('out/' + fname
    
  if msg.indexOf("finished") > -1
    phantom.exit()

page.open url, (status) ->
  #Page is loaded!
  console.log("Page loaded")
  title = page.evaluate(() -> return hello())
  console.log('Page hello is ' + title)
  if args.length == 1
    console.log("Need filename for graph as first parameter")
    phantom.exit()
  fname = args[1]
  console.log("Processing #{fname}")
  fn = (fname) ->
    RandomCutGraph.doGraph(fname)
  result = page.evaluate(fn, fname)
