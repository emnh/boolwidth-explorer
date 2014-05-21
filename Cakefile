{exec} = require 'child_process'
task 'build', 'Build project from src/*.coffee to lib/*.js', ->
  exec 'node node_modules/bower/bin/bower install', (err, stdout, stderr) ->
    throw err if err
    console.log stdout + stderr
  exec 'node node_modules/iced-coffee-script/bin/coffee -c -m -o static/coffee/ static/coffee/*.coffee', (err, stdout, stderr) ->
    throw err if err
    console.log stdout + stderr
  exec 'node node_modules/jade/bin/jade -P -o static/ static/cb.jade', (err, stdout, stderr) ->
        throw err if err
        console.log stdout + stderr
