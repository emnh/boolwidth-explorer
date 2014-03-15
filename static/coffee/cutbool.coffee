`// noprotect`
# vim: st=2 sts=2 sw=2

# General resources
# Ace 9 Editor: http://ace.c9.io/build/kitchen-sink.html for search/replace
# QuickLatex: for compiling Latex algorithms to images for web display
# MoonScript: http://moonscript.org/, CoffeeScript for Lua, for perf

# ==== Approximation Resources
#
# Current approximation with SampleSearch / Weighted Backtrack Estimate
# [Approximate Counting by Sampling the Backtrack-free Search Space]( http://www.ics.uci.edu/~csp/r142.pdf)
# [Studies in Solution Sampling](http://www.hlt.utdallas.edu/~vgogate/papers/aaai08.pdf)
# [Approximate Solution Sampling (and Counting) on AND/OR search space](http://www.ics.uci.edu/~csp/r161a.pdf)
# [Estimating Search Tree Size](http://www.cs.ubc.ca/~hutter/EARG.shtml/earg/stack/WS06-11-005.pdf)
# [Predicting the Size of Depth-First Branch and Bound Search Trees]( http://ijcai.org/papers13/Papers/IJCAI13-095.pdf)
# [Adapting the Weighted Backtrack Estimator to Conflict Driven Search](http://www.inf.ucv.cl/~bcrawford/2009_1%20Papers%20Tesis/0805.pdf)
#

# probability of edge in bipartite graph

# row and column count of bipartite graph
G = 8
EDGE_PROB = bigRat(1, G)
ROWCT = G
COLCT = G
MAX_DISPLAY_HOODS = 100 # maximum hoods to output to HTML
# adjacency matrix type
MAT_TYPES =
  ['rndmat',
  'unitymat',
  'rndunitymat',
  'unityskewmat',
  'unityskewmat_k(5)']
MAT_TYPE = MAT_TYPES[2]
SAMPLE_COUNT = 20

# unity skew mat 2 hood counts 1..16
u2 = [2, 2, 5, 10, 17, 29, 51, 90, 158, 277, 486, 853, 1497, 2627, 4610, 8090]
u2r = [1, 2.5, 2, 1.7, 1.705, 1.758, 1.764, 1.755, 1.753, 1.754, 1.755, 1.754, 1.754, 1.754, 1.754]
u3 = [2, 2, 2, 6, 12, 20, 30, 46, 74, 122, 200, 324, 522, 842, 1362, 2206]
u3r = [1, 1, 3, 2, 1.666, 1.5, 1.533, 1.608, 1.648, 1.639, 1.62, 1.611, 1.613, 1.617, 1.619]
u4 = [2, 2, 2, 2, 7, 14, 23, 34, 47, 67, 101, 158, 249, 387, 592, 898]
u4r = [1, 1, 1, 3.5, 2, 1.642, 1.478, 1.382, 1.425, 1.507, 1.564, 1.575, 1.554, 1.529, 1.516]
u5 = [2, 2, 2, 2, 2, 8, 16, 26, 38, 52, 68, 92, 132, 198, 302, 458]
u5r = [1, 1, 1, 1, 4, 2, 1.625, 1.461, 1.368, 1.307, 1.352, 1.434, 1.5, 1.525, 1.516]

toType = (obj) ->
  ({}).toString.call(obj).match(/\s([a-zA-Z]+)/)[1].toLowerCase()

class Timer
  timeit: (fn) ->
    before = new Date().getTime()
    ret = fn()
    after = new Date().getTime()
    @elapsed = after - before
    ret

util = {}

util.mergedicts = (obj1, obj2) ->
  for attrname of obj2
    obj1[attrname] = obj2[attrname]

util.getmergedicts = (objs...) ->
  newdict = {}
  for obj in objs
    for attrname of obj
      newdict[attrname] = obj[attrname]
  return newdict
    
util.zip = () ->
  lengthArray = (arr.length for arr in arguments)
  length = Math.min(lengthArray...)
  for i in [0...length]
    arr[i] for arr in arguments

bigraph = {}

bigraph.mat2list = (mat) ->
  graph = {}
  
  vector = (x) -> mori.into(mori.vector(), x)
  rowct = mat.rows
  colct = mat.cols
  graph.rows = vector(mori.repeat(rowct, mori.vector()))
  graph.cols = vector(mori.repeat(colct, mori.vector()))
  
  for row, rowi in mat
    for col, coli in row when mat[rowi][coli] == 1
      graph.rows = mori.update_in(graph.rows, [rowi], (l) -> mori.conj(l, coli))
      graph.cols = mori.update_in(graph.cols, [coli], (l) -> mori.conj(l, rowi))

  graph


bigraph.getmat = (corefn, rowct, colct) ->
  row = () -> (corefn(i, j) for i in [1..colct])
  rows = (row() for j in [1..rowct])
  rows.rows = rowct
  rows.cols = colct
  rows
  
bigraph.rndmat = (rowct, colct) ->
  corefn = (i, j) -> Math.floor(Math.random() < EDGE_PROB)
  bigraph.getmat(corefn, rowct, colct)

bigraph.unitymat = (rowct, colct) ->
  corefn = (i, j) -> (if i == j then 1 else 0)
  bigraph.getmat(corefn, rowct, colct)
  
bigraph.unityskewmat = (rowct, colct) ->
  corefn = (i, j) -> (if i == j or i % colct == (j + 1) % colct or i % colct == (j + 2) % colct then 1 else 0)
  bigraph.getmat(corefn, rowct, colct)
  
bigraph.unityskewmat_k = (k) ->
  (rowct, colct) ->
    corefn = (i, j) ->
      if (1 for k_i in [0..(k-1)] when i % colct == (j + k_i) % colct).length > 0
        1
      else
        0
    bigraph.getmat(corefn, rowct, colct)

bigraph.rndunitymat = (rowct, colct) ->
  corefn = (i, j) -> (if i == j then 1 else 0) | Math.floor(Math.random() < EDGE_PROB)
  bigraph.getmat(corefn, rowct, colct)

bigraph.getDegrees = (mat) ->
  addcol = (x, y) -> x + y
  rowcmp = (a, b) -> mori.into_array(mori.map(addcol, a, b))
  mori.reduce(rowcmp, mori.into_array(mat))

makeH = () ->
  html = {}
  tags = 
    ["script", "div", "span", "p", "ul", "li", "a",
    "table", "th", "tr", "td", "colgroup", "col", "thead", "tbody", 
    "h1", "h2", "h3", "h4", "h5",
    "label", "input", "button"]
  makeTagDef = (tag) ->
    html[tag] = (content, attrs = {}) ->
      attrs.html = content
      $("<" + tag + "/>", attrs)
  makeTagDef(tag) for tag in tags
  return html

H = makeH()
    
H.mat2table = (mat) ->
  H.table(H.tr(H.td(x) for x in row) for row in mat)

H.show = (h...) ->
  i.appendTo('#compute_results') for i in h

H.section = (title, h...) ->
  H.show(title)
  H.show(H.div(h))

H.u2table = (mat) ->
  trow = (row) ->
    r = (H.td(x) for x in row)
    if row.from != undefined
      [a,b] = row.from
      r.push(H.td("[ from: [#{a}] [#{b}] ]"))
    r
  H.table(H.tr(trow(row)) for row in mat)

H.u2list = (mat) ->
  trow = (row) ->
    r = (x for x in row)
    if row.from != undefined
      [a,b] = row.from
      r.push(" [ from: [#{a}] [#{b}] ]")
    r
  H.ul(H.li(trow(row)) for row in mat)  

binUnion = (a,b) ->
  if mori.count(a) != mori.count(b)
    throw "a.length != b.length"
  mori.map(((x,y) -> x | y), a, b)
  #(a[i] | b[i] for _,i in a)

unions = (mat) ->
  udata = H.div("")
  ulog = (fn) -> fn().appendTo(udata)
  # debug off
  ulog = (fn) -> 0
  hoods = {}
  hoodar = []
  cols = mat.cols
  init = (0 for x in [1..cols])
  hoods[init] = {}
  hoodar.push(init)
  
  addHood = (hood, row) ->
    #console.log("hood #{hood.length} #{hood}")
    #console.log("row #{row.length} #{row}")
    #console.log(zip(hood,row))
    #union = (x + y for [x,y] in zip(hood, row))
    union = mori.into_array(binUnion(hood, row))
    union.from = [hood, row]
    #console.log("union #{union}")
    if mori.count(union) != mori.count(hood)
      throw 'length mismatch: union #{union} hood #{hood}'
    if hoods[union] == undefined
      ulog(() -> H.div("" + union))
      hoods[union] = true
      hoodar.push(union)
  addHoods = (row) ->
    ulog(() -> H.div("Parent: " + row))
  (addHoods(row, (addHood(hood, row) for hood in hoodar)) for row in mat)
  [hoodar, udata]

ishood = (mat, hood) ->
  is_subset = (a, b) ->
    if mori.count(a) != mori.count(b)
      throw "length mismatch: a: #{a} b: #{b}"
    mori.every(mori.identity, mori.map(((x, y) -> x <= y), a, b))
  checkrow = (row) -> is_subset(row, hood)
  subsets = mori.filter(checkrow, mat)
  subsets_union = mori.reduce(binUnion, subsets)
  f1 = mori.into(mori.vector(), hood)
  f2 = mori.into(mori.vector(), subsets_union)
  t = mori.equals(f1, f2)
  t

isPartialHood = (mat, hood) ->
  is_subset = (a, b) ->
    if mori.count(a) != mori.count(b)
      throw "length mismatch: a: #{a} b: #{b}"
    f = mori.map(((x, y) -> x <= y or x == "?" or y == "?"), a, b)
    mori.every(mori.identity, f)
  checkrow = (row) -> is_subset(row, hood)
  subsets = mori.filter(checkrow, mat)
  subsets_union = mori.reduce(binUnion, subsets)
  t = mori.map(((x, y) ->
               x == y or x == "?" or y == "?"), hood, subsets_union)
  t = mori.every(mori.identity, t)
  t

getFixed = (mat) ->
  # 0,1 or "?"
  bincmp = (x, y) -> if x == y then x else "?"
  rowcmp = (a, b) -> mori.into_array(mori.map(bincmp, a, b))
  mori.reduce(rowcmp, mori.into_array(mat))
  
unionsfast = (mat) ->
  ufdata = H.div("")
  ulog = (fn) -> 
    fn().appendTo(ufdata)
  # debug off
  # ulog = (fn) -> 0
  fhoods = []
  root = []
  node_bykey = []
  keyindex = 0
  pqsum = 0
  
  vector = (x) -> mori.into(mori.vector(), x)
  
  # working at 2710
  
  rec_hoods = (state) ->
    {depth, children, fixed, hoods, ct, keyindex, pqprob} = state
    #if not state.depth? console.log("helooo")

    keyindex = 0 # XXX: correct?

    #console.log("fixed: #{fixed}, ct: #{ct}")
    # ulog(() -> H.div("fixed: #{fixed}, ct: #{ct}"))
    # ulog(() -> H.div(mat2table(mori.into_array(hoods))))
    #console.log("state", state)
    #console.log("children", children)
    node =
      title: "#{fixed}"
      key: keyindex
      children: []
      hoods: hoods
      childcount: 0
      depth: depth
      avgdepth: 0
      prob: pqprob
            
    node_bykey[keyindex] = node
    children.push(node)
    keyindex += 1
    newstate =
      depth: depth + 1 # recursion depth
      children: node.children # tree representing algorithm for postprocessing
      fixed: fixed # pattern specifying neighborhoods to enumerate in subtree
      fixedhasone: state.fixedhasone
      rowindices: state.rowindices # indices of rows eligible to participate in neighborhoods of subtree
      # degree of node / count of 1s per column over eligible rows
      colsums: state.colsums
      hoods: hoods # eligible hoods, to be replaced
      ct: ct
    applyfixed = () ->
      bycol = (coli, sym) ->
        rowidxbyval = mori.get(hoods_by_col_value, coli)
        valid =
          switch sym
            when '?'
              mori.cat(rowidxbyval[0], rowidxbyval[1])
            when 0
              rowidxbyval[0]
            when 1
              rowidxbyval[1]

    if ct >= 0
      childcalls = []
      if mori.get(fixed, ct) != "?"
        # position already fixed by necessary neighborhood, skip to next
        childcalls.push({ct: ct - 1})
      else
        # fix position to 0, i.e. remove a vertex/column on one side,
        # and remove rows with 1 in this column on other side
        isZero = (hood) -> mori.get(hood, ct) == 0
        remaining_hoods = vector(mori.filter(isZero, hoods))
        #console.log(remaining_hoods)
        
        # TODO: rename ct to colindex or something
        # 
        rowcount = mori.count(hoods)
        # number of remaining rows with 0 in this column
        remct = rowcount - mori.get(colsums, ct)
        #mori.assoc(colsums, ct, 0)
        #indexof1rows = mori.get(hoods_by_col_value, ct)
        #mori.map((x) -> x - , colsums)
        #mori.update_in(colsums, 
        
        # remct = mori.count(remaining_hoods)
        # TODO: replace partialHood
        # if row which is removed by setting 0 in this position,
        # has a 1 in a 1-fixed position,
        # then we need to check for each 1 that there is another row with 1 in this position.
        # could keep counters on each col that says how many alternatives are left
        if remct > 0 and isPartialHood(remaining_hoods, fixed)
          if remct == 1
            # one hood remaining, so all is fixed
            #console.log("remaining_hoods", remaining_hoods)
            newfixed = vector(mori.first(remaining_hoods))
            #console.log("newfixed #{newfixed}")
            childcalls.push({
                             fixed: newfixed,
                             hoods: remaining_hoods,
                             ct: -1})
          else
            # if ishood(fixed, remaining_hoods)
            childcalls.push({
                             fixed: mori.assoc(fixed, ct, 0),
                             hoods: remaining_hoods,
                             ct: ct - 1})
        
        # fix position to 1
        # must be at least one neighborhood
        # which contains this node, i.e. has 1
        # in this position
        # console.log("g ct #{mori.get(globs, ct)} #{ct}")
        if mori.get(colsums, ct) >= 1
          # TODO: eliminate already included sets, including null set
          
          #isOne = (hood) -> mori.get(hood, ct) == 1
          #onehoods = mori.filter(isOne, hoods)
          
          # isect = 
          # TODO: must fix ones
          #onehoods_isect = mori.reduce(isect, onehoods)
          #if mori.count(onehoods) > 0
          if not state.fixedhasone
            hoods = mori.remove(((x) -> mori.equals(x, nullset)), hoods)
          childcalls.push({
                           fixed: mori.assoc(fixed, ct, 1),
                           hoods: hoods,
                           fixedhasone: true,
                           ct: ct - 1})
      
      prob = 1 / childcalls.length
      for childcall in childcalls
        rec_hoods(util.getmergedicts(newstate, childcall, { pqprob: pqprob * prob } ))

      sumchildren = (x, y) -> x + y.childcount
      #sumdepth = (x, y) -> (x + y.depth) / 2
      #node.avgdepth = node.children.reduce(sumdepth)
      node.avgdepth = 
        switch mori.count(node.children)
          when 1 then node.children[0].avgdepth
          when 2 then (node.children[0].avgdepth + node.children[1].avgdepth) / 2
      node.childcount = node.children.reduce(sumchildren, 0)
    else # leaf
      fixed = mori.into_array(fixed)
      #if not ishood(hoods, fixed) then console.log("BUG")
      #ish = ishood(hoods, fixed)
      # ulog(() -> H.p("end: #{fixed} ishood #{ish}"))
      fhoods.push(fixed)
      node.childcount = 1
      pqsum += (1 / (pqprob*pqprob))
      #node.avgdepth = mori.count(hoods) / fixed.reduce((x, y) -> x + y))
  #fixed = ('?' for x in [1..mat.cols])
  fixed = getFixed(mat)
  fixed = mori.into(mori.vector(), fixed)
  nullset = vector(0 for x in [1..mat.cols])
  
  hoods = mori.sorted_set()
  hoods = mori.into(hoods, mori.map(vector, mat))
  hoods = mori.conj(hoods, nullset)
  hoodcount = mori.count(hoods)
  
  #for x in mori.into_array(hoods)
  #  do () ->
  #    console.log("x", "" + x, x[0])
      
  rowindexes = [0..(hoodcount-1)]
  #withidx = mori.map(((rowi, h) -> [rowi, h]), rowindexes, hoods)
  hoods = vector(hoods)
  group_by_column_value =
    (coli) ->
      mori.group_by(((i) -> 
        mori.nth(mori.nth(hoods, i), coli)), rowindexes)
  hoods_by_col_value = mori.map(group_by_column_value, [0..COLCT-1])
  #mori.each(hoods_by_01, (x) -> console.log("a", x))
  console.log("h01", "" + hoods_by_col_value)
  #H.show(mat2table(hoods))
  
  getDegrees = (mat) ->
    addcol = (x, y) -> x + y
    addrow = (a, b) -> mori.map(addcol, a, b)
    vector(mori.reduce(addrow, mat))
  
  colsums = getDegrees(hoods)
  console.log("" + colsums)
  
  rec_hoods({
        depth: 0,
        children: root,
        fixed: fixed,
        fixedhasone: false,
        rowindices: rowindexes,
        colsums: colsums,
        hoods: hoods,
        ct: mat.cols - 1,
        pqprob: 1
        })
  #fhoods.push(nullset)
  
  getsample = (node) ->
    prob = switch mori.count(node.children)
      when 0
        node.prob
      when 1
        getsample(node.children[0])
      when 2
        rand = Math.floor(Math.random()*2)
        getsample(node.children[rand])
    return prob
        
  N = SAMPLE_COUNT
  samples = (1 / getsample(root[0]) for k in [1..N])
  estimate = samples.reduce((x, y) -> x + y) / N
  
  # TODO: estimate: let the selection order be free
  # TODO: separate approximation algorithm from enumeration
  # TODO: estimate idea, train neural network with count based on vertex degrees
  
  #console.log(samples)
  #console.log("E:", estimate)
  #console.log("pqsum:", pqsum)
  
  #getsamplesampleidx = (norm_samples) ->
  #  rand = Math.random()
  #  sum = 0
  #  for sample, i in samples
  #    sum += sample
  #    if sum > rand
  #      return i

  # sample the samples to get from backtrack-free to uniform distribution
  #sum_samples = samples.reduce((x, y) -> x + y)
  #norm_samples = (s / sum_samples for s in samples)
  #M = N / 2
  #sample_samples = (samples[getsamplesampleidx(norm_samples)] for k in [1..M])
  #estimate_sir = sample_samples.reduce((x, y) -> x + y) / M
  #console.log(norm_samples)
  #console.log(sample_samples)
  #console.log("E-sir:", estimate_sir)
  
  root.bykey = node_bykey
  {
   hoods: fhoods,
   tree: root,
   log: ufdata,
   est: estimate
  }

buildtree = (jsontree, nodeinfo) ->
  colgroups = [H.col("", {width: "*"}) for i in [1..5]]
  colgroups[0] = H.col("", {width: "*"})
  table = 
    H.table([
      H.colgroup(colgroups),
      H.thead(H.tr(H.th(x) for x in ["Fixed", "Count", "Prob", "Depth", "Key"])),
      H.tbody(H.tr(H.td(i) for i in [1..5]))
      ], { class: "uftable" } )
  
  
  $.ui.fancytree.debugLevel = 1 # silence debug output
  table.fancytree
    extensions: ["table"]
    table:
      indentation: 20 # indent 20px per node level
      nodeColumnIdx: 0 # render the node title into the 2nd column
    renderColumns: (e, data) ->
      node = data.node
      $tdList = $(node.tr).find(">td")
      # (index #0 is rendered by fancytree by adding the checkbox)
      #$tdList.eq(1).text(node.getIndexHier()).addClass "alignRight"
      
      $tdList.eq(1).text jsontree.bykey[node.key].childcount
      $tdList.eq(2).text "1/" + 1/jsontree.bykey[node.key].prob
      $tdList.eq(3).text Math.pow(2, jsontree.bykey[node.key].avgdepth)
      $tdList.eq(4).text node.key
      #$tdList.eq(3).text jsontree.bykey[node.key].avgdepth
      #$tdList.eq(3).text node.key
    filter:
      mode: "hide"
    source:
      jsontree
    focus: (e, data) ->
      node = data.node
      rnode = jsontree.bykey[node.key]
      nodeinfo.html(H.mat2table(mori.into_array(mori.map(mori.into_array, rnode.hoods))))
  table

drawGraph = (left, right, holder) ->
  nodes = {}
  
  leftnodes =
    for key, value of left
      node =
        col: 0
        name: key
        colindex: value
  rightnodes =
    for key, value of right
      node =
        col: 1
        name: key
        colindex: value 
  nodes = leftnodes.concat(rightnodes)
  nodesByName = {}
  nodesByName[node.name] = node for node in nodes
  
  edges = [
           [1, 5], [1, 6]
           [2, 6], [2, 7]
           [3, 7], [3, 8]
           [4, 8], [4, 5]
           ]
  edgeNodes = ([nodesByName[x],nodesByName[y]] for [x, y] in edges)
  raph = Raphael(holder[0], 320, 240)
  s = raph.set()
  
  drawcol = (col, offset) ->
    pos =
      x: 10 + offset * 30,
      y: 10 + col * 40
    s.push raph.circle(pos.x, pos.y, 5).attr
      fill: "none"
      "stroke-width": 2
    pos
  (nodesByName[name].pos = drawcol(0, i) for name, i of left)
  (nodesByName[name].pos = drawcol(1, i) for name, i of right)
  console.log("node", n) for n in nodesByName
  
  drawEdge = (left, right) ->
    s.push raph.path("M#{left.x},#{left.y}c0,0,0,0,#{right.x-left.x},#{right.y-left.y}").attr
      fill: "none"
      "stroke-width": 2
  
  #for [a, b] in edgeNodes
    #console.log(a.pos, b.pos)
  #  drawEdge(a.pos, b.pos)
    
  s.attr stroke: Raphael.getColor()
  
  return
  
doSetup = () ->
  [rows, cols] = [ROWCT, COLCT]
  rm = eval('bigraph.' + MAT_TYPE)(rows, cols)
  
  rest = bigraph.getDegrees(rm)
  rest = rest.reduce((x, y) -> (1 + 1/y)*x)
  #console.log(rest)
  #rest = rest.filter((x) -> x > 0).reduce((x, y) -> 2 * (x - 1) /  * y)
  title = H.h1("Bipartite adjacency matrix (#{rows}, #{cols})")
  content = [
    H.p("rows=#{rows}, cols=#{cols}")
    H.mat2table(rm)
    H.div("Degrees")
    H.table(H.tr(H.td(deg) for deg in bigraph.getDegrees(rm)))
    H.p("Rough estimate: #{rest}")]
  H.section(title, content...)

  holder = $('<div id="holder"/>')
  holder.appendTo("#result")
  leftnodes = [1..ROWCT]
  rightnodes = [1..COLCT]
  drawGraph(leftnodes, rightnodes, holder)
  
  rm

getHoodPlaceHolder = (mhoods, tohtml, id) ->
  showHoods = () ->
    firsthoods = mhoods.slice(0, MAX_DISPLAY_HOODS)
    ht = tohtml(firsthoods)
    $(@).html(H.div([H.p("First #{MAX_DISPLAY_HOODS} neighborhoods:"), ht]))
  hdptext = "Click to show first #{MAX_DISPLAY_HOODS} neighborhoods"
  hdplink = H.a(hdptext, {href: "#" + id})
  hoodplacement = H.div(hdplink, {id: id}).click(showHoods)
  hoodplacement
  
doUnions = (rm) ->
  timer = new Timer()
  [hoods, unions_log] = timer.timeit(() -> unions(rm))
  #console.log(x) for x in hoods.slice(0, 5)
  title = "Trivial Neighborhood Algorithm "
  title += "(t=#{timer.elapsed}ms, count=#{mori.count(hoods)})"
  content = [
          H.p("unions: #{timer.elapsed} ms")
          H.p("per hood: #{timer.elapsed / mori.count(hoods)} ms")
          getHoodPlaceHolder(hoods, H.u2list, "hoodsplacement")]
  H.section(H.h1(title), content...)
  hoods

doFastUnions = (rm) ->
  timer = new Timer()
  
  ufret = timer.timeit(() -> unionsfast(rm))
  
  getTreePlaceHolder = () ->
    showtree = () ->
      nodeinfo = H.div("nodeinfo")
      uitree = buildtree(ufret.tree, nodeinfo)
      $("#ufalgovis").empty()
      $("#ufalgovis").append(uitree)
      $("#ufalgovis").append(nodeinfo)
      uitree.fancytree("getRootNode").visit((node) -> node.setExpanded(true))
    treelink = H.a("Click to show search tree", {'href': '#ufalgovis'}).click(showtree)
    H.div(treelink, { id: "ufalgovis", class: "ufalgovis" })
  
  title = H.h1("Backtrack Neighborhoods (t=#{timer.elapsed}ms, count=#{mori.count(ufret.hoods)})")
  content =
    [
      H.p("Backtrack algorithm elapsed time: #{timer.elapsed} ms")
      H.p("Time per neighborhood: #{timer.elapsed / mori.count(ufret.hoods)} ms")
      H.h2("Algorithm Search Tree")
      getTreePlaceHolder()
      H.div("Backtrack hood count: #{ufret.hoods.length}")
    ]
  H.section(title, content...)
  
  #console.log(x) for x in ufret.hoods.slice(0, 5)
  f = (h) -> H.ul(H.li(x) for x in h)
  title = H.h1("Backtrack Unions Neighborhoods")
  content = getHoodPlaceHolder(ufret.hoods, f, "fasthoodsplacement")
  H.section(title, content...)
  
  acc = Math.round(ufret.est / mori.count(ufret.hoods) * 100) / 100
  title = H.h1("Weighted Backtrack Estimate (N=#{SAMPLE_COUNT}, count=#{ufret.est}, acc=#{acc})")
  H.section(title, H.div("nothing yet"))

investigateHoodCounts = () ->
  cts = []
  for G in [1..16]
    ROWCT = G
    COLCT = G
    rm = doSetup()
    h = doUnions(rm)
    cts.push(mori.count(h))
  console.log(cts)
  ratios = (Math.floor(cts[i + 1] * 1000 / cts[i]) / 1000 for _, i in cts)
  console.log(ratios)
  return cts

#cts = investigateHoodCounts()

htmlInputs = (doCompute) ->
  inputs = {}
  textin = (label, name, value) ->
    input = H.input('', { 'type': 'text', 'id': name, 'name': name, 'value': value })
    inputs['get' + name] = () -> input.val()
    [H.label(label, { 'for': name }), input]
  button = (label) ->
    H.button(label, { 'type': 'button', 'value'})
  
  inputs.boxes = [
    textin("Columns", "columns", COLCT),
    textin("Rows", "rows", ROWCT),
    textin("Edge probability", "edgeprob", EDGE_PROB.toString()),
    textin("Adjacency Matrix Type (TODO: combo)", "mat_type", MAT_TYPE.toString())
    ]
  inputs.boxes = H.table(H.tr([H.td(label), H.td(input)]) for [label, input] in inputs.boxes)
  inputs.compute = button("Compute").click(() -> doCompute(inputs))
  
  lshow = (h...) ->
    i.appendTo('#inputs') for i in h

  lsection = (title, h...) ->
    lshow(title)
    lshow(H.div(h))
  
  lsection(H.h1("Input"), inputs.boxes, inputs.compute)
  #$( "input[name='#{name}']" )
  inputs

doCompute = (inputs) ->
  COLCT = inputs.getcolumns()
  ROWCT = inputs.getrows()
  EDGE_PROB = bigRat(inputs.getedgeprob())
  MAT_TYPE = inputs.getmat_type()

  console.clear()
  
  r = $("#compute_results")
  r.empty()
  rm = doSetup()
  g = bigraph.mat2list(rm)
  console.log("graph rows", "" + g.rows)
  console.log("graph cols", "" + g.cols)
  h = doUnions(rm)
  if mori.count(h) < 5000
    doFastUnions(rm)
  else
    title = H.h1("Backtrack Unions (skipped for large graph >5000 hoods until optimized)")
    H.section(title, H.div(""))
  r.collapse({})
      
inputs = htmlInputs(doCompute)
doCompute(inputs)
