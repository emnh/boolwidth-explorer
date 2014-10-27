# set window to {} for compatibility for imports
# TODO: window should be replaced by self in modules
# since self == window in main browser and also global object for worker
self.window = {}
self.worker = true
importScripts('../../jscache/bitterset.js')
importScripts('../../jscache/mori.js')
importScripts('../../jscache/BigInt_BigRat.min.js')
importScripts('../bundle.js')
dowork = (e) ->
  cmd = e.data.cmd
  switch cmd
    when 'unions'
      mat = e.data.mat
      timer = new Timer()
      hoods = timer.timeit(() -> unions(mat))
      self.postMessage
        timer: timer
        hoods: hoods
self.addEventListener('message', dowork, false)
