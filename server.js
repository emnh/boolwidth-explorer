var http = require('http')
  , express = require('express')
  , path = require('path')
  , app = express()
  , port = process.env.PORT || 5000;

app.use('/', express.static(path.join(__dirname, 'static')));
app.use('/', express.static(path.join(__dirname, 'static/jade.out')));
app.use('/js', express.static(path.join(__dirname, 'bower_components')));
app.use('/nodejs', express.static(path.join(__dirname, 'node_modules')));


var server = http.createServer(app);
server.listen(port);

console.log('http server listening on %d', port);
