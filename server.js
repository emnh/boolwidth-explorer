var http = require('http')
  , express = require('express')
  , path = require('path')
  , neo4j = require('neo4j')
  , app = express()
  , port = process.env.PORT || 5000;

app.use('/', express.static(path.join(__dirname, 'static')));
app.use('/graphdata', express.static(path.join(__dirname, 'graphdata'))); // for source map
app.use('/static', express.static(path.join(__dirname, 'static'))); // for source map
app.use('/js', express.static(path.join(__dirname, 'bower_components')));
app.use('/nodejs', express.static(path.join(__dirname, 'node_modules')));

app.use(express.bodyParser());

app.post('/message',
    function(request, response){
        var name = request.body.name;
        var value = request.body.value;
        var node = db.createNode({name: value});     // instantaneous, but...
        node.save(function (err, node) {    // ...this is what actually persists.
            if (err) {
                console.error('Error saving new node to database:', err);
                response.send('Error saving new node to database:' + err);
            } else {
                console.log('Node saved to database with id:', node.id);
                response.send('Node saved to database with id:' + node.id);
            }
        });
        //response.send(request.body)
    }
);


var neo4jurl = process.env.NEO4J_URL || 'http://localhost:7474';
var db = new neo4j.GraphDatabase(neo4jurl);

var server = http.createServer(app);
server.listen(port);

console.log('http server listening on %d', port);
