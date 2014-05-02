binUnion = (a,b) ->
  if mori.count(a) != mori.count(b)
    throw "a.length != b.length"
  mori.map(((x,y) -> x | y), a, b)
  #(a[i] | b[i] for _,i in a)

self.unions = (mat,ulog) ->
  # udata = H.div("")
  # ulog = (fn) -> fn().appendTo(udata)
  if not ulog?
    # debug off
    ulog = (fn) -> 0
  hoods = {}
  hoodar = []
  cols = mat.cols
  init = (0 for x in [1..cols])
  hoods[init] = {}
  hoodar.push(init)
  
  addHood = (hood, row) ->
    union = mori.into_array(binUnion(hood, row))
    union.from = [hood, row]
    if mori.count(union) != mori.count(hood)
      throw 'length mismatch: union #{union} hood #{hood}'
    if hoods[union] == undefined
      ulog(() -> H.div("" + union))
      hoods[union] = true
      hoodar.push(union)
  addHoods = (row) ->
    ulog(() -> H.div("Parent: " + row))
  (addHoods(row, (addHood(hood, row) for hood in hoodar)) for row in mat)
  hoodar
