# vim: st=2 sts=2 sw=2
http = require("http")
express = require("express")
path = require("path")
neo4j = require("neo4j")
app = express()
port = process.env.PORT or 5000

app.use "/", express.static(path.join(__dirname, "static"))
app.use "/graphdata", express.static(path.join(__dirname, "graphdata")) # for source map
app.use "/static", express.static(path.join(__dirname, "static")) # for source map
app.use "/js", express.static(path.join(__dirname, "bower_components"))
app.use "/nodejs", express.static(path.join(__dirname, "node_modules"))
app.use express.bodyParser()

app.post "/message", (request, response) ->
  name = request.body.name
  value = request.body.value
  node = db.createNode(name: value) # instantaneous, but...
  node.save (err, node) -> # ...this is what actually persists.
      if err?
        console.error "Error saving new node to database:", err
        response.send
          message: "Error saving new node to database:"
          error: err
      else
        console.log "Node saved to database with id:", node.id
        response.send
          message: "Node saved to database"
          id: node.id

  node.save (err, node) -> # ...this is what actually persists.
    if err?
      console.error "Error saving new node to database:", err
      response.send
        message: "Error saving new node to database:"
        error: err
    else
      console.log "Node saved to database with id:", node.id
      response.send
        message: "Node saved to database"
        id: node.id

app.post "/bigraph_stat", (request, response) ->
  data = request.body
  cols = data.cols
  rows = data.rows
  name = "bigraph"
  data.name = name
  matrix = data.matrix
  hoodcount = data.hoodcount
  response.send
    message: "disabled"
  node =
    db.createNode
      cols: data.cols
      colDegrees: data.colDegrees
      rows: data.rows
      rowDegrees: data.rowDegrees
      name: name
      hoodcount: data.hoodcount
      matrix: JSON.stringify(data.matrix)
  node.save (err, node) -> # ...this is what actually persists.
    if err?
      console.error "Error saving new node to database:", err
      response.send
        message: "Error saving new node to database:"
        error: err
    else
      console.log "Node saved to database with id:", node.id
      response.send
        message: "Node saved to database"
        id: node.id

#response.send(request.body)
neo4jurl = process.env.NEO4J_URL or "http://localhost:7474"
db = new neo4j.GraphDatabase(neo4jurl)
server = http.createServer(app)
server.listen port
console.log "http server listening on %d", port
