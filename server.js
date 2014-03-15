var http = require('http')
  , express = require('express')
  , app = express()
  , port = process.env.PORT || 5000;

app.use('/', express.static(__dirname + '/static'));
app.use('/js', express.static(__dirname + '/bower_components'));
app.use('/nodejs', express.static(__dirname + '/node_modules'));

var server = http.createServer(app);
server.listen(port);

console.log('http server listening on %d', port);
