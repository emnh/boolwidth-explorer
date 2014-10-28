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

    a.forEach (n) ->
      ret.push n unless bmap[n]

    ret.sort()
    ret
  
  difference: (a, b) ->
    @diff(a, b)

  union: (a, b) ->
    bmap = {}
    ret = []
    b.forEach (n) ->
      ret.push n
      bmap[n] = true

    a.forEach (n) ->
      ret.push n  unless bmap[n]

    ret.sort()
    ret

  intersect: (a, b) ->
    bmap = {}
    ret = []
    b.forEach (n) ->
      bmap[n] = true

    a.forEach (n) ->
      ret.push n  if bmap[n]

    ret.sort()
    ret
    
class window.set.Set
  constructor: (ar) ->
    @amap = {}
    ar.forEach (n) ->
      @amap[n] = true
