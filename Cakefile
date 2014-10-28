{exec} = require 'child_process'
task 'build', 'Build project from src/*.coffee to lib/*.js', ->
  exec 'node node_modules/bower/bin/bower install', (err, stdout, stderr) ->
    throw err if err
    console.log stdout + stderr
  exec '''cp static/coffee/*.coffee static/coffee.out/ &&
    cp -a static/coffee/workers static/coffee.out/ &&
    node node_modules/iced-coffee-script/bin/coffee -c -m -o static/coffee.out/ static/coffee.out/*.coffee && 
    node node_modules/iced-coffee-script/bin/coffee -c -m -o static/coffee.out/workers/ static/coffee.out/workers/*.coffee &&
    rm -f static/coffee.out/bundle.map static/coffee.out/bundle.js &&
    node node_modules/mapcat/bin/mapcat static/coffee.out/*.map -m static/coffee.out/bundle.map -j static/coffee.out/bundle.js''', (err, stdout, stderr) ->
    throw err if err
    console.log stdout + stderr
  exec 'node node_modules/jade/bin/jade -P -o static/ static/*.jade', (err, stdout, stderr) ->
    throw err if err
    console.log stdout + stderr
