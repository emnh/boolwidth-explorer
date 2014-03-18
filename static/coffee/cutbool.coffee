`// noprotect`
# vim: st=2 sts=2 sw=2
#
#
# TODO: connected components for sampler
# TODO: show backtrack tree
# TODO: integrate with main dc
# TODO: create general sample algorithm that runs on arbitrary search tree,
# such that the algorithm can be combined from summing over samples of all
# search trees to running on the graph that is the combination of all search
# trees

# General resources
# Ace 9 Editor: http://ace.c9.io/build/kitchen-sink.html for search/replace
# QuickLatex: for compiling Latex algorithms to images for web display
# MoonScript: http://moonscript.org/, CoffeeScript for Lua, for perf

# ==== Approximation Resources
#
# http://www.cse.unsw.edu.au/~tw/comic-2006-004.pdf
#
# Current approximation with SampleSearch / Weighted Backtrack Estimate
# [Estimating Search Tree Size](http://www.cs.ubc.ca/~hutter/EARG.shtml/earg/stack/WS06-11-005.pdf)
# [Predicting the Size of Depth-First Branch and Bound Search Trees]( http://ijcai.org/papers13/Papers/IJCAI13-095.pdf)
# [Approximate Counting by Sampling the Backtrack-free Search Space]( http://www.ics.uci.edu/~csp/r142.pdf)
# [Studies in Solution Sampling](http://www.hlt.utdallas.edu/~vgogate/papers/aaai08.pdf)
# [Approximate Solution Sampling (and Counting) on AND/OR search space](http://www.ics.uci.edu/~csp/r161a.pdf)
# [Adapting the Weighted Backtrack Estimator to Conflict Driven Search](http://www.inf.ucv.cl/~bcrawford/2009_1%20Papers%20Tesis/0805.pdf)
#

# probability of edge in bipartite graph

# row and column count of bipartite graph
G = 12
#bigRat = rational
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
#SAMPLE_TIME = 1000
SAMPLE_COUNT = 20
INNER_SAMPLE_COUNT = 1

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
    before = (new Date()).getTime()
    ret = fn()
    after = (new Date()).getTime()
    @elapsed = after - before
    ret

  time: () ->
    (new Date).getTime()

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
    ["script", "div", "span", "p", "ol", "ul", "li", "a", "dl", "dt", "dd",
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
  contentdiv = (H.div(h, {'class': 'content'}))
  atitle = H.a(title, {href: '#', 'class': 'title'})
  title.click () ->
    $(".section .content").css("visibility", "hidden")
    $(".title h1").css("font-size", "small")
    contentdiv.css("visibility", "visible")
    title.css("font-size", "large")
  H.show(H.div([atitle, contentdiv], { 'class': 'section' }))
  #title.click()

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
  #console.log("node", n) for n in nodesByName
  
  drawEdge = (left, right) ->
    s.push raph.path("M#{left.x},#{left.y}c0,0,0,0,#{right.x-left.x},#{right.y-left.y}").attr
      fill: "none"
      "stroke-width": 2
  
  #for [a, b] in edgeNodes
    #console.log(a.pos, b.pos)
  #  drawEdge(a.pos, b.pos)
    
  s.attr stroke: Raphael.getColor()
  
  return
  
doSetup = (rowct, colct, create_mat) ->
  [rows, cols] = [rowct, colct]
  rm = create_mat(rows, cols)
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
  leftnodes = [1..rowct]
  rightnodes = [1..colct]
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

doMiniChart = (svgid, data) ->
  
  nv.addGraph ->
    chart = nv.models.lineChart()
    #chart.xAxis.xRange 0 exact * 2
    #chart.lines.forceY [0, exact * 2]
    chart.showLegend(false)
    chart.margin({top:0, bottom:0, right:0, left:0})
    chart.lines.forceY [0, 2]
    chart.xAxis.tickFormat d3.format(",f")
    chart.yAxis.tickFormat d3.format(",.2f")
    #console.log("samples", data)
    d3.select(svgid).datum(data).call(chart)
    nv.utils.windowResize chart.update
    chart

sampleValues = (samples, exact) ->
  values = []
  sum = 0
  for s, i in samples
    sum += s
    x = i + 1
    ret =
      x: x
      y: (sum / x) / exact
    values.push(ret)
  values

getChartData = (samples, samples2, exact) ->
  data = [
    {
      key: 'STree Estimate'
      values: values = sampleValues(samples, exact)
    },
    {
      key: 'QPos Estimate'
      values: values2 = sampleValues(samples2, exact)
    },
    {
      key: 'Exact'
      values: {x: i + 1, y: 1} for _,i in samples
    }
  ]
  data

doChart = (svgid, data) ->
  
  nv.addGraph ->
    chart = nv.models.lineChart()
    #chart.xAxis.xRange 0 exact * 2
    #chart.lines.forceY [0, exact * 2]
    chart.lines.forceY [0, 2]
    chart.xAxis.tickFormat d3.format(",f")
    chart.yAxis.tickFormat d3.format(",.2f")
    #console.log("samples", data)
    d3.select(svgid).datum(data).call(chart)
    nv.utils.windowResize chart.update
    chart

class HTMLTree
  constructor: (opts) ->
    @opts = opts
    if @opts.sampler? and @opts.sampler
      @opts.innerfmt = (tree) ->
        "est: #{tree.state.estimate}, d: #{tree.state.depth}, #{tree.state.sample}"
    else
      @opts.innerfmt = (tree) ->
        #"#{tree.state}"
        s = ("#{k}:#{v}" for k,v of tree.state).join(",")
        if tree.leaf
          s += " leaf"
        s

  searchTreeToHTML: (tree) ->
    if tree.children?
      pre = [
               if tree.state?
                 @opts.innerfmt(tree)
               else
                 ""]
      H.li([pre,H.ul((@searchTreeToHTML(c) for c in tree.children))])
    else if tree.leaf? and tree.leaf == true
      dl = ([H.dt("#{k}"), H.dd("#{v}")] for k,v of tree.state).reduce((a, b) -> a.concat(b))
      H.li(H.dl(dl))
      #H.li(H.span(tree.state.sample))

doFastUnions = (rm) ->
  timer = new Timer()
  state =
      mat: rm
  samplect = inputs.getsamplecount()
  timer = new Timer()
  sampler = new Sampler(state)
  itertree = timer.timeit(() -> sampler.iterate())
  hoods = itertree.getSolutions()
  hoodcount = hoods.length
  if hoodcount == 0
    throw "hood count bug, would cause infinite loop with chart"
  iter_elapsed = timer.elapsed

  # Iterate Search Tree
  broot = itertree.root
  #console.log("tree", itertree.root)
  htmltree =
    new HTMLTree
      sampler: false
  html_itertree = htmltree.searchTreeToHTML(itertree.root)
  html_itertree = H.div(H.ul(html_itertree), {class: 'searchtree'})

  title = H.h1("Backtrack Neighborhoods (t=#{iter_elapsed}ms, count=#{hoodcount})")
  content =
    [
      H.p("Backtrack algorithm elapsed time: #{iter_elapsed} ms")
      H.p("Time per neighborhood: #{iter_elapsed / hoodcount} ms")
      H.h2("Algorithm Search Tree")
      H.div("Backtrack hood count: #{hoodcount}")
    ]
  H.section(title, content...)
  
  f = (h) -> H.ul(H.li(x) for x in h)
  title = H.h1("Backtrack Unions Neighborhoods")
  content = [
    getHoodPlaceHolder(hoods, f, "fasthoodsplacement"),
    html_itertree
    ]
  H.section(title, content...)

  # Run first sampler
  results = timer.timeit(() -> sampler.getEstimate(samplect))
  estimate = results.estimate
  sample_elapsed = timer.elapsed
  acc = Math.round(estimate / hoodcount * 100) / 100

  # Sampler Search Tree
  tree = results.results[0].searchtree.root
  htmltree =
    new HTMLTree
      sampler: true
  htree = htmltree.searchTreeToHTML(tree)
  htree = H.div(H.ul(htree), {class: 'searchtree'})

  # Output first sampler
  sampleinfo = "t=#{sample_elapsed}ms, N=#{samplect}, count=#{estimate}, acc=#{acc})"
  title = H.h1("STree Estimate (#{sampleinfo})")
  H.section(title, htree, chart) # H.div("Search Tree"), ol)
  htree.ready () ->
   $(".searchtree")
     .jstree()
     .on("loaded", () -> htree "open_all")

  # Run second sampler
  sampler2 = new Sampler(state)
  results2 = timer.timeit(() -> sampler2.getQPosEstimate(samplect))
  estimate = results2.estimate

  # Output second sampler, TODO: tree
  sample_elapsed = timer.elapsed
  acc = Math.round(estimate / hoodcount * 100) / 100
  sampleinfo = "t=#{sample_elapsed}ms, N=#{samplect}, count=#{estimate}, acc=#{acc}"
  title = H.h1("STree QPos Estimate (#{sampleinfo})")
  H.section(title, "")

  # Chart
  chart = $("<div id='chart0'><svg style='height: 500px; width: 800px;'/></div>")
  H.section(H.h1("STree Chart"), chart)
  chartid = '#' + chart.attr("id") + ' svg'
  samples = (s.estimate for s in results.results)
  samples2 = results2.results
  data = getChartData(samples, samples2, hoodcount)
  #doChart(chartid, data)
  $().ready(() -> doChart(chartid, data))

investigateHoodCounts = () ->
  cts = []
  for g in [1..16]
    rowct = colct = g
    rm = doSetup(rowct, colct, MAT_TYPE)
    h = doUnions(rm)
    cts.push(mori.count(h))
  #console.log(cts)
  ratios = (Math.floor(cts[i + 1] * 1000 / cts[i]) / 1000 for _, i in cts)
  #console.log(ratios)
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
    textin("Adjacency Matrix Type (TODO: combo)", "mat_type", MAT_TYPE.toString()),
    textin("Sample Count", "samplecount", SAMPLE_COUNT)
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
  colct = inputs.getcolumns()
  rowct = inputs.getrows()
  EDGE_PROB = bigRat(inputs.getedgeprob())
  samplect = inputs.getsamplecount()
  mat_type = inputs.getmat_type()

  console.clear()
  
  r = $("#compute_results")
  r.empty()
  create_mat = eval('bigraph.' + mat_type)
  rm = doSetup(rowct, colct, create_mat)
  g = bigraph.mat2list(rm)
  h = doUnions(rm)
  doFastUnions(rm)
  rm
  #r.collapse({})

class SearchTree
  constructor: () ->
    @root = null
    @top = @root
    @stack = []

  branch: (argstate) ->
    #console.log("st branch", argstate)
    node =
      state: argstate
      children: []
    if @root == null
      @root = node
      @top = node
      @stack.push(@top)
    else
      @top.children.push(node)
      @stack.push(@top)
      @top = node

  pop: () ->
    #console.log("st pop")
    @top = @stack.pop()
    @top

  solution: (argstate) ->
    #console.log("st solution", argstate)
    @branch argstate
    @top.leaf = true
    delete @top.children
    @pop()

  getSolutions: () ->
    solutions = []
    proc = (tree) ->
      if tree.children? and tree.children.length > 0
        proc(c) for c in tree.children
        if tree.leaf
          throw "node should not be both leaf and parent"
      else if tree.leaf? and tree.leaf == true
        solutions.push(tree.state)
    proc @root
    solutions

  return: (argstate) ->
    #console.log("st return", argstate)
    argstate
   
class Sampler

  # TODO: estimate: let the selection order be free
  # TODO: estimate idea, train neural network with count based on vertex degrees

  constructor: (@state) ->
    @mat = @state.mat
    @hoods = []

  isSubset: (pat) ->
    (row for row in @mat when pat.every((e, i) -> e == '?' or row[i] <= e))
  
  isSubsetSum: (rows, pat) ->
    atLeastOneOneInRows = (e, i) ->
      if e == 1
        rows.some((row) -> row[i] == 1)
      else
        true
    pat.every(atLeastOneOneInRows)

  isPartialHood: (pat) ->
    rows = @isSubset(pat)
    @isSubsetSum(rows, pat)

  iterate: () ->
    st = new SearchTree()
    solct =  0
    @itersub = (state) ->
      st.branch state
      if state.sample.length >= @mat.cols
        solct++
        st.solution
          sample: state.sample
      else
        zeroct = @isPartialHood(state.sample.concat([0]))
        onect = @isPartialHood(state.sample.concat([1]))
        switch (onect + zeroct)
          when 0
            solct++
            st.solution
              sample: state.sample
          when 1
            nextval = if onect > 0 then 1 else 0
            @itersub
              sample: state.sample.concat([nextval])
          when 2
            @itersub
              sample: state.sample.concat([0])
            @itersub
              sample: state.sample.concat([1])
      st.pop()
    st.branch
      sample: []
    @itersub
      sample: []
    st

  getTreeSamples: () ->
    st = new SearchTree()
    solct =  0
    @itersub = (state) ->
      st.branch state
      while not done
        st.pop()
        if state.sample.length >= @mat.cols
          solct++
          st.solution
            sample: state.sample
        else
          zeroct = @isPartialHood(state.sample.concat([0]))
          onect = @isPartialHood(state.sample.concat([1]))
          switch (onect + zeroct)
            when 0
              solct++
              st.solution
                sample: state.sample
            when 1
              nextval = if onect > 0 then 1 else 0
              st.branch
                sample: state.sample.concat([nextval])
            when 2
              st.branch
                sample: state.sample.concat([0])
              st.branch
                sample: state.sample.concat([1])
      st.pop()
    st.branch
      sample: []
    @itersub
      sample: []
    st

  getQPosSample: (sample, prob) ->
    qpos = (i for x,i in sample when x == '?')
    qcount = qpos.length
    if qcount == 0 # @mat[0].length
      return prob
    else
      # select nth question mark as new position
      newposrand = Math.floor(Math.random() * qcount)
      newposition = qpos[newposrand]
      getnext = (val) ->
        newsample = ((if i == newposition   then val else x) for x,i in sample)
        newsample
      vals =
        for val in [0, 1]
          ispartial = @isPartialHood(getnext(val))
          ispartial
      prob = switch (vals[0] + vals[1])
        when 0
          prob
        when 1
          nextval = if vals[1] > 0 then 1 else 0
          prob = @getQPosSample(getnext(nextval), prob)
        when 2
          rand = Math.floor(Math.random()*2)
          prob = @getQPosSample(getnext(rand), prob*0.5)
      return prob

  getSamples: (in_sample, in_prob, samplect=INNER_SAMPLE_COUNT) ->
    stack = []
    samples = []
    st = new SearchTree()
    branch = (argstate) ->
      st.branch(argstate)
      stack.push(argstate)
    solution = (argstate) ->
      st.solution(argstate)
      samples.push
        sample: argstate.sample
        estimate: argstate.estimate
      samplect--
      samplect <= 0

    branch
      sample: in_sample
      prob: in_prob
      estimate: 1
      depth: 0

    done = false
    ct = 0
    branchct = 0
    maxdepth = Math.ceil(Math.log(samplect) / Math.log(2))
    while stack.length > 0 and not done
      st.pop()
      state = stack.pop()
      ct++
      zeroct = @isPartialHood(state.sample.concat([0]))
      onect = @isPartialHood(state.sample.concat([1]))
      if state.sample.length >= @mat[0].length
        done = solution(state)
      else
        switch (onect + zeroct)
          when 0
            # shouldn't happen, because sample length would exceed row length in earlier check
            done = solution(state)
          when 1
            nextval = if onect > 0 then 1 else 0
            branch
              sample: state.sample.concat([nextval])
              prob: state.prob
              estimate: state.estimate
              depth: state.depth + 1
              parent: state
          when 2
            rand = Math.floor(Math.random()*2)
            newprob = state.prob * 0.5
            if state.depth < maxdepth
              estimate = state.estimate
            else
              estimate = state.estimate * 2 # assumes same type
            branch
              sample: state.sample.concat([rand])
              prob: newprob
              estimate: estimate
              depth: state.depth + 1
              parent: state
            if state.depth < maxdepth
              opposite = rand ^ 1
              branch
                sample: state.sample.concat([opposite])
                prob: newprob
                estimate: estimate
                depth: state.depth + 1
                parent: state
              branchct++
      st.return(state)
    #console.log("iterations", ct)
    #samples.sort()
    #(console.log(s.sample.length + " " +  s.sample.join("") + " " + s.estimate) for s in samples)
    ret =
      searchtree: st
      samples: samples
      estimate: sum(x.estimate for x in samples)

  average = (samples) ->
    samples.reduce((x, y) -> x + y) / samples.length

  sum = (samples) ->
    samples.reduce((x, y) -> x + y)

  getAbstractEstimate: (samplect, getSampleM) ->
    samples = (getSampleM() for i in [1..samplect])
    average(samples)

  getEstimate: (samplect) ->
    results = (@getSamples([], 1) for i in [1..samplect])
    ret =
      estimate: average(r.estimate for r in results)
      results: results
      samples: r.estimate for r in results
  
  getQPosEstimate: (samplect) ->
    initsample = ('?' for x in [1..@mat[0].length])
    samples = (1 / @getQPosSample(initsample, 1) for i in [1..samplect])
    ret =
      estimate: average(samples) # r.estimate for r in results)
      results: samples
      samples: samples

samplerStats = () ->
  sets = []
  mat = []
  minrowct = 8
  mincolct = 8
  maxrowct = 16
  maxcolct = 16
  samplect = 30 #inputs.getsamplecount()
  timer = new Timer()
  for edge_prob in [0.5]
    for i in [mincolct..maxcolct]
      mat[i] = []
      for j in [minrowct..maxrowct]
        do (i, j, edge_prob) ->
          set =
            colct: i
            rowct: j
            edge_prob: edge_prob
            mat_type: 'rndunitymat'
          rowct = set.rowct
          colct = set.colct
          #samplect = (maxrowct + maxcolct)
          EDGE_PROB = bigRat(set.edge_prob)
          rm = eval('bigraph.' + set.mat_type)
          rm = rm(rowct, colct)
          #rm = doSetup(rowct, colct, mat_type)
          #
          sampler = new Sampler({mat: rm})

          tree = timer.timeit(() -> sampler.iterate())
          elapsed_hoods = timer.elapsed
          count = tree.getSolutions().length

          results = timer.timeit () -> sampler.getEstimate(samplect)
          estimate = Math.round(results.estimate)
          elapsed_samples = timer.elapsed
          acc = Math.round(estimate / count * 100)
          timeratio = Math.round(elapsed_samples / elapsed_hoods * 100)
          mat[i][j] =
            count: count
            estimate: estimate
            accuracy: acc
            elapsed_hoods: elapsed_hoods
            elapsed_samples: elapsed_samples
            timeratio: timeratio
            samples: results.samples

  exactdata = [
    {
      key: 'Exact',
      values: {x: i + 1, y: 1} for i in [1..samplect]
    }
  ]
  getdi = (samples, exact, title) ->
    {
      key: title,
      values: sampleValues(samples, exact)
    }
  fmt_a = (i,j) ->
    H.td("#{mat[i][j].count}|#{mat[i][j].estimate}")
  fmt_b = (i,j) ->
    acc = mat[i][j].accuracy / 100
    cls =
      if acc > 2 or acc < 1/2
        "poor"
      else if acc > 3/2 or acc < 2/3
        "medium"
      else
        "good"
    ret = H.td("#{mat[i][j].accuracy}%", { class: cls })
  fmt_c = (i, j) ->
    #H.td("#{mat[i][j].elapsed_hoods}|#{mat[i][j].elapsed_samples}")
    H.td("#{mat[i][j].timeratio}")
  fmt_d = (i, j) ->
    acc = mat[i][j].accuracy / 100
    cls =
      if acc > 2 or acc < 1/2
        "poor"
      else if acc > 3/2 or acc < 2/3
        "medium"
      else
        "good"

    chart = $("<div id='summary_chart#{i}x#{j}'><svg style='height: 50px; width: 50px;'/></div>")
    chartid = '#' + chart.attr("id") + ' svg'
    dv = [getdi(mat[i][j].samples, mat[i][j].count, "#{i}x#{j}")]
    data = exactdata.concat(dv)
    chart.ready(() ->
      doMiniChart(chartid, data))
    H.td(chart, {class: "#{cls} chartcell" })

  mktable = (title, fmt) ->
    headerrow = [H.tr([H.th(" ")].concat(H.th(i) for i in [mincolct..maxcolct]))]
    rows = (H.tr([H.th(i)].concat(fmt(i, j) for j in [mincolct..maxcolct])) for i in [minrowct..maxrowct])
    content = H.table(headerrow.concat(rows))
    content.addClass("nums")
    H.section(H.h1(title), content)
  mktable("Summary Count|Estimate", fmt_a)
  mktable("Summary Accuracy", fmt_b)
  mktable("Summary Time", fmt_c)
  mktable("Summary Charts", fmt_d)

  chart = $("<div id='summary_chart0'><svg style='height: 500px; width: 800px;'/></div>")
  chartid = '#' + chart.attr("id") + ' svg'
  H.section(H.h1("Summary BigChart"), chart)
  dv =
    for i in [minrowct..maxrowct]
      for j in [mincolct..maxcolct]
        do (i, j) ->
          getdi(mat[i][j].samples, mat[i][j].count, "#{i}x#{j}")
  dv = dv.reduce((a,b) -> a.concat(b))
  data = exactdata.concat(dv)
  $(chart).ready(() -> doChart(chartid, data))

inputs = htmlInputs(doCompute)
doCompute(inputs)
#samplerStats()

console.log("I think uncaught type-errors from nvd3 can be ignored as long as graphs show up fine")
