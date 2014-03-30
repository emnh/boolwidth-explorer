class window.Timer
  timeit: (fn) ->
    before = (new Date()).getTime()
    ret = fn()
    after = (new Date()).getTime()
    @elapsed = after - before
    ret

  time: () ->
    (new Date).getTime()
