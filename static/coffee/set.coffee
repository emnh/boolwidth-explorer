window.set =
  canonical: (a) ->
    a.sort()
    JSON.stringify a

  decanonical: (a) ->
    JSON.parse a

  diff: (a, b) ->
    bmap = {}
    ret = []
    b.forEach (n) ->
      bmap[n] = true
      return

    a.forEach (n) ->
      ret.push n  unless bmap[n]
      return

    ret.sort()
    ret

  union: (a, b) ->
    bmap = {}
    ret = []
    b.forEach (n) ->
      ret.push n
      bmap[n] = true
      return

    a.forEach (n) ->
      ret.push n  unless bmap[n]
      return

    ret.sort()
    ret

  intersect: (a, b) ->
    bmap = {}
    ret = []
    b.forEach (n) ->
      bmap[n] = true
      return

    a.forEach (n) ->
      ret.push n  if bmap[n]
      return

    ret.sort()
    ret
