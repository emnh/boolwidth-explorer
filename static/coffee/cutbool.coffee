# `// noprotect`
# vim: st=2 sts=2 sw=2
#

# TODO: use connected components in sampler
# TODO: lazy load backtrack tree
# TODO: integrate with main dc
# TODO: finish spliterate
# TODO: generalize sampler algorithm with edge probability
# TODO: create general sample algorithm that runs on arbitrary search tree,
# such that the algorithm can be combined from summing over samples of all
# search trees to running on the graph that is the combination of all search
# trees

# General resources
# Ace 9 Editor: http://ace.c9.io/build/kitchen-sink.html for search/replace
# QuickLatex: for compiling Latex algorithms to images for web display
# MoonScript: http://moonscript.org/, CoffeeScript for Lua, for perf
# Statistics Programming: http://www.greenteapress.com/thinkstats/html/

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

# bigRat = require('../jscache/BigInt_BigRat.min.js')
# mori = require('../jscache/mori.js')

# row and column count of bipartite graph
G = 12
#bigRat = rational
EDGE_PROB = bigRat(1, 2)
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

testpost = (msg) ->
  success = null
  data =
    #JSON.stringify
    name: "emh"
    value: "emh@emh.com"
  $.ajax
    type: "POST"
    url: '/message'
    data: data
    success: (data) -> console.log("post success:", data)
    dataType: 'text'

posthoodstat = (data) ->
  $.ajax
    type: "POST"
    url: '/bigraph_stat'
    data: data
    success: (data) ->
      0
      #console.log("post success:", data)
    dataType: 'text'


class Graph
  constructor: () ->
    @neighbors = []
    @initmarked = -1
    @marked = @initmarked

  parseDimacs: (data) ->
    lines = data.split('\n')
    #firstline = lines[0].match('p edges ([\\d]+) ([\\d]+)')
    #p = parseInt(firstline[1], 10)
    #e = parseInt(firstline[2], 10)
    pat = '^e ([\\d]+) ([\\d]+)'
    edges = (edge.match(pat) for edge in lines)
    edges = (x for x in edges when x?)
    #console.log(edges)
    edges = ([parseInt(edge[1], 10), parseInt(edge[2], 10)] for edge in edges)
    @nodes = {}
    for e in edges
      [x,y] = e
      if not(@nodes[x]?)
        @nodes[x] = new Node()
        @nodes[x].name = x
      if not(@nodes[y]?)
        @nodes[y] = new Node()
        @nodes[y].name = y
      @nodes[x].neighbors.push(y)
      @nodes[y].neighbors.push(x)
    #console.log(@nodes)

class Decomposition
  
  constructor: () ->
    0

  trivialDecomposition: (graph) ->
    getBipartiteMatrix = (tree) ->
      left = tree.leftnodes # indices
      right = tree.rightnodes
      right_revmap = {}
      (right_revmap[graphi] = righti for graphi, righti in right)
      #console.log("rr", right_revmap)
      mat = ([0] for j in right for i in left)
      for ri,i in left
        for n in graph.nodes[ri].neighbors
          j = right_revmap[n]
          mat[i][j] = 1
      #console.log(mat)
      #console.log(row.join(",")) for row in mat
      mat

    dc = (nodes) ->
      if nodes.length > 1
        mid = nodes.length / 2
        left = nodes.slice(0, mid)
        right = nodes.slice(mid)
        tree =
          leftnodes: left
          rightnodes: right
          left: dc(left)
          right: dc(right)
          state:
            items: nodes
        tree.children = [tree.left, tree.right]
        tree.state.mat = getBipartiteMatrix(tree)
        sampler =
          new Sampler
            mat: tree.state.mat
        tree.state.hoodcount = sampler.count(tree.state.mat)
        tree
      else
        tree =
          item: nodes[0]
          leaf: true
          state:
            item: nodes[0]
    #console.log(Object.keys(graph.nodes).length, graph.nodes)
    nodes = Object.keys(graph.nodes)
    @tree = dc(nodes)

    #console.log(@tree)

    @tree
    

class Node
  constructor: () ->
    @neighbors = []
    @initmarked = -1
    @marked = @initmarked

  isMarked: () ->
    @marked != @initmarked

  mark: (label) ->
    if label == @initmarked
      throw "label should not be #{@initmarked}"
    @marked = label

class BiGraph
  constructor: () ->
    @nodes = {}
    @components = {}

  addNode: (id) ->
    if @nodes[id] == undefined
      @nodes[id] = new Node()
    @nodes[id]

  dfs: (node, callback) ->
    if callback(node)
      return
    @dfs(@nodes[neighbor], callback) for neighbor in node.neighbors

  from_mat: (mat) ->
    @mat = mat
    @right_id = (i) -> mat.rows + i
    @edges = []
    @leftids = [0..mat.rows-1]
    if @leftids.length != mat.rows
      throw "bad"
    @rightids = (@right_id(j) for j in [0..mat.cols-1])
    if @rightids.length != mat.cols
      throw "bad"
    (@nodes[id] = new Node() for id in @leftids.concat(@rightids))
    g = @
    addMatEdge = (ri, cj) ->
      if mat[ri][cj] == 1
        cjid = g.rightids[cj]
        g.edges.push([ri, cjid])
        inode = g.nodes[ri]
        jnode = g.nodes[cjid]
        if jnode == undefined
          throw "jnode #{cjid},#{cj}:#{g.rightids} is undefined"
        inode.neighbors.push(cjid)
        jnode.neighbors.push(ri)
    addMatEdge(ri, cj) for col,cj in row for row,ri in mat
        
  @matcopy: () ->
    newmat = ((x for x in row) for row in @mat)
  
  connectedComponents: () ->
    # visit nodes
    markct = 0
    components = []
    for nodei, node of @nodes
      if node.marked < 0
        markct += 1
        callback =
          do (markct) ->
            (node) ->
              ismarked = node.isMarked()
              if not ismarked
                node.mark(markct)
                if components[markct] == undefined
                  components[markct] = []
                components[markct].push(node)
              return ismarked
        @dfs(node, callback)
    @components = components

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

bigraph.transpose = (mat) ->
  rmat = ([] for x in mat[0])
  for row,i in mat
    for x,j in row
      rmat[j][i] = mat[i][j]

makeH = () ->
  html = {}
  tags =
    ["script", "div", "span", "p", "ol", "ul", "li", "a", "dl", "dt", "dd",
    "table", "th", "tr", "td", "colgroup", "col", "thead", "tbody",
    "h1", "h2", "h3", "h4", "h5",
    "label", "input", "button", "select", "option"]
  makeTagDef = (tag) ->
    html[tag] = (content, attrs = {}) ->
      attrs.html = content
      $("<" + tag + "/>", attrs)
  makeTagDef(tag) for tag in tags
  return html

H = makeH()
    
H.mat2table = (mat) ->
  tdf = (x, i, j) ->
    td = H.td(x)
    td.data('index', [i, j])
    td
  rowf = (row, i) -> H.tr([H.th(i + 1)].concat(tdf(x, i, j) for x, j in row))
  rows = (rowf(row, i) for row, i in mat)
  headers = H.tr([H.th()].concat((H.th(i) for i in [1..mat.cols])))
  rows = [headers].concat(rows)
  H.table(rows)

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
  title.click
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

unions = (mat,ulog) ->
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

class VisualGraph

  drawGraph: (graph, chart, table) ->
    leftnodes =
      for name,i in graph.leftids
        node =
          col: 0
          name: name
          colindex: i
          graphnode: graph.nodes[name]
    rightnodes =
      for name,i in graph.rightids
        node =
          col: 1
          name: name
          colindex: i
          graphnode: graph.nodes[name]
    nodes = leftnodes.concat(rightnodes)
    #nodes = graph.leftids.concat(graph.rightids)
    nodesByName = {}
    (nodesByName[node.name] = node for node in nodes)
    edgeByIdx = []

    makeEdge = (x, y) ->
      edge =
        left: nodesByName[x]
        right: nodesByName[y]
        hover: false
      if not(edgeByIdx[edge.left.colindex])
        edgeByIdx[edge.left.colindex] = []
      edgeByIdx[edge.left.colindex][edge.right.colindex] = edge
      if not(edgeByIdx[edge.right.colindex])
        edgeByIdx[edge.right.colindex] = []
      edgeByIdx[edge.right.colindex][edge.left.colindex] = edge
      edge
    edgeNodes = (makeEdge(x, y) for [x, y] in graph.edges)

    components = graph.connectedComponents()

    xpos = (d, i) ->
      10 + d.col * 300
    ypos = (d, i) ->
      30 + d.colindex * 40

    color = d3.scale.category20()
    
    # Mark node in matrix and graph visuals
    mark = (i, j, color, edge) ->
      row = $(".bigraph_table tr:eq(#{i+1})")
      row.css("background", color)
      col = $(".bigraph_table tr td:nth-child(#{j+2})")
      col.css("background", color)
      if edge != undefined
        d3.select('g circle').attr("r", 10)
        #lines.attr("r", 10)

    group = chart
      .selectAll(".circle")
      .data(nodes)
      .enter()
      .append('g')
      .attr("transform", (d) -> "translate(#{xpos(d)}, #{ypos(d)})")

    me = (d, i) ->
      switch d.col
        when 0
          row = $(".bigraph_table tr:eq(#{d.colindex+1})")
          row.css("background", color(d.graphnode.marked))
        when 1
          col = $(".bigraph_table tr td:nth-child(#{d.colindex+2})")
          col.css("background", color(d.graphnode.marked))
          #edges = edgeByIdx[i][d.colindex]
      lines
        .filter((edge, i) -> (edge.left == d) or (edge.right == d))
        .style("stroke-width", 3)
        .style("stroke", "red")

    ml = (d, i) ->
      switch d.col
        when 0
          row = $(".bigraph_table tr:eq(#{d.colindex+1})")
          row.css("background", "")
          #for e in d.edgeByIdx[d.colindex]
        when 1
          col = $(".bigraph_table tr td:nth-child(#{d.colindex+2})")
          col.css("background", "")
      lines
        .filter((edge, i) -> (edge.left == d) or (edge.right == d))
        .style("stroke-width", 1)
        .style("stroke", "black")

    circles = group
      .append('circle')
      .attr("r", 8)
      .attr("fill", (d, i) -> color(d.graphnode.marked))
      .on("mouseenter", me)
      .on("mouseleave", ml)

    text = group
      .append('text')
      .attr('dx', 0)
      .attr('dy', -15)
      .attr("font-family", "sans-serif")
      .attr("font-size", "20px")
      .attr("fill", "black")
      .text((d, i) -> d.colindex + 1)

    lines = chart.selectAll(".line")
      .data(edgeNodes)
      .enter()
      .append("line")
      .attr("x1", (d, i) -> xpos(d.left, i) + 10)
      .attr("y1", (d, i) -> ypos(d.left, i))
      .attr("x2", (d, i) -> xpos(d.right, i) - 10)
      .attr("y2", (d, i) -> ypos(d.right, i))
      .style("stroke-width", 1)
      .style("stroke", "black")
 
    cells = table.find('td')
    mfo = (e) ->
      elem = e.target
      [i, j] = $(elem).data('index')
      edge = edgeByIdx[i][j]
      mark(i, j, "red")
    mfl = (e) ->
      elem = e.target
      [i, j] = $(elem).data('index')
      edge = edgeByIdx[i][j]
      mark(i, j, "")
    cells.on("mouseover", mfo)
    cells.on("mouseleave", mfl)

   
doSetup = (rowct, colct, create_mat) ->
  [rows, cols] = [rowct, colct]
  rm = create_mat(rows, cols)
  #rest = rest.filter((x) -> x > 0).reduce((x, y) -> 2 * (x - 1) /  * y)
  bigraph_table = H.mat2table(rm).addClass("bigraph_table")
  title = H.h1("Bipartite Graph / Matrix (#{rows}, #{cols})")
  jqsvg = $('<svg id="bigraph"/>')
  jqsvg.height(800)
  jqsvg.width(600)
  content = [
    H.p("rows=#{rows}, cols=#{cols}")
    bigraph_table,
    H.div("Degrees")
    H.table(H.tr(H.td(deg) for deg in bigraph.getDegrees(rm)))
    jqsvg]
  H.section(title, content...)
  # display first section by default
  $().ready(title.click())

  vg = new VisualGraph()
  
  svgid = '#' + jqsvg.attr("id")
  chart = d3.select(svgid)

  graph = new BiGraph()
  graph.from_mat(rm)
  vg.drawGraph(graph, chart, bigraph_table)
  #jqsvg.ready(() -> drawGraph(graph, chart))
  
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
  hoods = timer.timeit(() -> unions(rm))
  title = "Trivial Neighborhood Algorithm "
  title += "(t=#{timer.elapsed}ms, count=#{mori.count(hoods)})"
  content = [
          H.p("unions: #{timer.elapsed} ms")
          H.p("per hood: #{timer.elapsed / mori.count(hoods)} ms")
          getHoodPlaceHolder(hoods, H.u2list, "hoodsplacement")]
  H.section(H.h1(title), content...)

  # Rough estimate based on degrees
  sampler = new Sampler({mat: rm})
  timer = new Timer()
  result = timer.timeit(() -> sampler.getRoughEstimate(mori.count(hoods)))

  sampleinfo = "t=#{timer.elapsed}ms, count=#{result.rest}, acc=#{result.acc(result.rest)}"
  title = H.h1("Rough Estimate: (#{sampleinfo})")
  content = [
      H.p("Rough estimate (degrees #{result.deg0}): #{result.rest}, acc: #{result.acc(result.rest)}")
      H.p("Rough estimate2 (degrees #{result.deg1}): #{result.rest2}, acc: #{result.acc(result.rest2)}")
      H.p("Average rough estimate: #{(result.avgest) / 2}, acc: #{result.acc(result.avgest)}")
      H.p("Random Graph Theoretical Estimate: (#{result.rndest}, acc: #{result.acc(result.rndest)})")]
  H.section(title, content...)
  title.click()

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
      pre = if tree.state? then @opts.innerfmt(tree) else ""
      H.li([pre,H.ul((@searchTreeToHTML(c) for c in tree.children))])
    else if tree.leaf? and tree.leaf == true
      dl = ([H.dt("#{k}"), H.dd("#{v}")] for k,v of tree.state).reduce((a, b) -> a.concat(b))
      H.li(H.dl(dl))
      #H.li(H.span(tree.state.sample))

  decompToHTML: (tree) ->
    if tree.children?
      pre = if tree.state? then @opts.innerfmt(tree) else ""
      H.li([pre,H.ul((@decompToHTML(c) for c in tree.children))])
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
  result = timer.timeit(() -> sampler.iterate())
  itertree = result.tree
  #sampler.spliterate()
  hoods = itertree.getSolutions()
  #stree = timer.timeit(() -> sampler.getTreeSamples())
  #console.log("stree", stree.getSolutions().length)
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
  #html_itertree = htmltree.searchTreeToHTML(itertree.root)
  html_itertree = H.li("TODO: lazyload")
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
  #htree = htmltree.searchTreeToHTML(tree)
  htree = H.li("TODO: lazyload")
  htree = H.div(H.ul(htree), {class: 'searchtree'})

  # Output first sampler
  sampleinfo = "t=#{sample_elapsed}ms, N=#{samplect}, count=#{Math.round(estimate)}, acc=#{acc})"
  title = H.h1("STree Estimate (#{sampleinfo})")
  H.section(title, htree, chart) # H.div("Search Tree"), ol)
  # TODO: make lazy load
  htree.click () ->
   $(".searchtree")
     .jstree()
     .on("loaded", () -> htree "open_all")

  # Run second sampler
  sampler2 = new Sampler(state)
  results2 = timer.timeit(() -> sampler2.getQPosEstimate(samplect))
  estimate2 = results2.estimate

  # Output second sampler, TODO: tree?
  sample_elapsed2 = timer.elapsed
  acc2 = Math.round(estimate2 / hoodcount * 100) / 100
  sampleinfo = "t=#{sample_elapsed2}ms, N=#{samplect}, count=#{Math.round(estimate2)}, acc=#{acc2}"
  title = H.h1("STree QPos Estimate (#{sampleinfo})")
  H.section(title, "")

  # Output average sampler
  elapsed = sample_elapsed + sample_elapsed2
  estimate = Math.round((estimate + estimate2) / 2)
  acc = Math.round(estimate / hoodcount * 100) / 100
  sampleinfo = "t=#{elapsed}ms, N=#{samplect*2}, count=#{estimate}, acc=#{acc}"
  title = H.h1("Average Estimate (#{sampleinfo})")
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

  # Save stats to DB
  # TODO: sort matrix by edge degrees
  posthoodstat
    rows: rm.rows
    cols: rm.cols
    rowDegrees: bigraph.getDegrees(rm)
    colDegrees: bigraph.getDegrees(bigraph.transpose(rm))
    matrix: (row for row in rm)
    hoodcount: hoodcount

makeProcessGraph = (opts) ->
  processGraph = (data) ->
    graph = new Graph()
    graph.parseDimacs(data)
    dc = new Decomposition()
    tree = dc.trivialDecomposition(graph)
    htree = new HTMLTree({})
    htmldecomp = htree.decompToHTML(tree)
    #console.log("htmldecomp", htmldecomp)
    content = [htmldecomp]
    title = H.h1("Decomposition of #{opts.fname}")
    H.section(title, content...)

doDecomposition = (rm) ->
  sampler =
    new Sampler
      mat: rm
  #fname = "graphdata/graphLib_ours/hsugrid/hsu-4x4.dimacs"
  fname = "graphdata/graphLib/coloring/queen5_5.dgf"
  processGraph =
    makeProcessGraph
      fname: fname
  $.get(fname, "", processGraph)

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
  
  fnameselect = H.select("", { id: "fnameselect" })
  fnamelabel = H.label("Graph", { 'for': fnameselect })
  inputs.boxes = [
    textin("Columns", "columns", COLCT),
    textin("Rows", "rows", ROWCT),
    textin("Edge probability", "edgeprob", EDGE_PROB.toString()),
    textin("Adjacency Matrix Type (TODO: combo)", "mat_type", MAT_TYPE.toString()),
    textin("Sample Count", "samplecount", SAMPLE_COUNT)
    ]
  H.div([fnamelabel, fnameselect]).appendTo('#inputs')
  inputs.boxes = H.table(H.tr([H.td(label), H.td(input)]) for [label, input] in inputs.boxes)

  fnamelist = "/graphfiles.txt"
  showfnames = (data) ->
    lines = data.split('\n')
    bname = (fname) ->
      fname.split('/')[-1]
    options = (H.option(line, { value: line }) for line in lines when line != '')
    $(option).appendTo(fnameselect) for option in options

    # setup select change handler
    handler = (evt) ->
      f = (data) ->
        g = new Graph()
        #console.log("parsing graph file", fname)
        g.parseDimacs(data)
      fname = evt.currentTarget.value
      #console.log("retrieving graph file", fname)
      $.get(fname, "", f)
    fnameselect.change(handler)
    fnameselect.val("graphdata/graphLib_ours/cycle/c5.dimacs")
    fnameselect.trigger("change")

  H.option("Generate", { value: "generate" }).appendTo(fnameselect)
  $.ajax
    url: fnamelist
    data: ""
    success: showfnames
    dataType: "text"

  inputs.compute = button("Compute").click(() -> doCompute(inputs))
  
  lshow = (h...) ->
    i.appendTo('#inputs') for i in h

  lsection = (title, h...) ->
    lshow(title)
    lshow(H.div(h))
  
  lsection(H.h1("Generate Matrix"), inputs.boxes, inputs.compute)
  #$( "input[name='#{name}']" )
  inputs

doCompute = (inputs) ->
  colct = parseInt(inputs.getcolumns(), 10)
  rowct = parseInt(inputs.getrows(), 10)
  EDGE_PROB = bigRat(inputs.getedgeprob())
  samplect = inputs.getsamplecount()
  mat_type = inputs.getmat_type()

  #console.clear()
  
  r = $("#compute_results")
  r.empty()
  create_mat = eval('bigraph.' + mat_type)
  rm = doSetup(rowct, colct, create_mat)
  g = bigraph.mat2list(rm)
  h = doUnions(rm)
  doFastUnions(rm)
  doDecomposition(rm)
  rm
  #r.collapse({})

class SearchTree
  constructor: (state) ->
    if state
      @debug = state.debug
    else
      @debug = false
    @root = null # root of tree

  addChild: (argstate, parent=null) ->
    if @debug
      console.log("st branch", argstate)
    # used for breadth first search
    node =
      state: argstate
      children: []
    if parent == null
      @root = node
    else
      parent.children.push(node)
    node

  addLeaf: (argstate, parent) ->
    if @debug
      console.log("st solution", argstate)
    if parent == undefined # safety hatch
      throw "parent must not be null for leaves"
    #@pushThenBranch(argstate)
    node = @addChild(argstate, parent)
    node.leaf = true
    delete node.children

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

  getRoughEstimate: (exact) ->
    deg = bigraph.getDegrees(@mat)

    a = (x for x in deg when x > 0)
    a.sort((a,b) -> b - a)
    b = (x for x in deg when x > 0)
    b.sort((a,b) -> a - b)

    f = (x, y) -> (1 + 1/y)*x
    rest = a.reduce(f, 1)
    rest2 = b.reduce(f, 1)

    # Random Graph Estimate
    mul = 6
    p = 0
    for row in @mat
      for x in row when x == 1
        p++
    #console.log("Probability", p, (@mat.cols * @mat.rows), p / (@mat.cols * @mat.rows))
    p /= (@mat.cols * @mat.rows)
    rndest = Math.round(mul*Math.log(@mat.rows)*Math.log(@mat.cols)/p)

    result =
      deg0: a
      deg1: b
      acc: (estimate) -> Math.round(estimate / exact * 100) / 100
      rest: Math.round(rest)
      rest2: Math.round(rest2)
      avgest: (rest + rest2) / 2
      rndest: Math.round(rndest)
      p: p
    result

  spliterate: () ->
    # X = left
    # Z = im(X)
    # X = A U B
    # |A U B| = |A| + |B| - |A ^ B| = |A - A^B| + |B - A ^ B| + |A ^ B|
    # Z = im(A) U im(B)
    # F = im(A) ^ im(B)
    # |Z| = |im(A U B)| = |im(A)| * |im(B)| / |im(A ^ B)|
    # |Z| = |im(A U B)| = |im(A - A ^ B)| * |im(B - A ^ B)| * |im(A ^ B)|
    mat = @mat
    graph = new BiGraph()
    graph.from_mat(mat)

    mid = mat.rows / 2
    A = mat.slice(0, mid)
    B = mat.slice(mid)
    union = (r1, r2) ->
      (r1[i] | r2[i] for x, i in r1)
    intersect = (r1, r2) ->
      (r1[i] & r2[i] for x, i in r1)

    Ac = @count(A)
    Bc = @count(B)
    imA = A.reduce(union)
    imB = B.reduce(union)
    F = intersect(imA, imB)

    rmat = ([] for x in mat[0])
    for row,i in mat
      for x,j in row
        rmat[j][i] = mat[i][j]

    imF = (rmat[i] for x,i in F when x == 1)
    imFidx = (i for x,i in F when x == 1)

    imAnoB = ([i, rmat[i]] for x,i in F when i < mid and x != 1)
    imBnoA = ([i, rmat[i]] for x,i in F when i >= mid and x != 1)
    # TODO: check for empty before calling iterate
    imAnoBhoods = @iterate((x[1] for x in imAnoB))
    imBnoAhoods = @iterate((x[1] for x in imBnoA))
    imAnoBc = imAnoBhoods.count
    imBnoAc = imBnoAhoods.count

    hjoin = {}
    samplect = 10 # O(n^2)
    hoods1 = (h1 for {sample: h1} in imAnoBhoods.tree.getSolutions())
    hoods2 = (h2 for {sample: h2} in imBnoAhoods.tree.getSolutions())
    selectrandom = (ar) ->
      num = Math.floor(Math.random() * ar.length)
      ar[num]
    hoods1sampleidx  = (selectrandom(hoods1) for i in [1..samplect])
    hoods2sampleidx  = (selectrandom(hoods2) for i in [1..samplect])
    for h1 in hoods1sampleidx
      for h2 in hoods2sampleidx
        do (h1, h2) ->
          nhood = union(h1, h2)
          hjoin[nhood] = 1
    ratio = Object.keys(hjoin).length / (samplect * samplect)
    
    colorRow = (indices, color) ->
      for i in indices
        row = $(".bigraph_table tr:eq(#{i+1})")
        row.css("background", color)
    colorCol = (indices, color) ->
      for i in indices
        row = $(".bigraph_table td:nth-child(#{i+2})")
        row.css("background", color)

    #colorLine(F, 'tr', 'cyan')
    colorCol(imFidx, 'magenta')
    colorCol((i for [i, row] in imAnoB), 'cyan')
    colorCol((i for [i, row] in imBnoA), 'pink')

    imFc = @count(imF)
    table = $('bigraph_table')
    console.log("A", A, imA, Ac)
    console.log("B", B, imB, Bc)
    console.log("AnoB", imAnoB, imAnoBc)
    console.log("BnoA", imBnoA, imBnoAc)
    console.log("F", F, imFc)
    console.log("imF", imF, imFc)
    console.log("upper", Ac * Bc, Ac * Bc / imFc)
    console.log("lower", imAnoBc * imBnoAc, imAnoBc * imBnoAc * imFc)
    console.log("avg", Math.pow(Math.E, (Math.log(Ac * Bc) + Math.log(imAnoBc * imBnoAc)) / 2))
    console.log("length check", mat.cols, imAnoB.length + imBnoA.length + imF.length)
    console.log("hjoin", Object.keys(hjoin).length, ratio, Ac * Bc * ratio)
    state = {}
    state.A = A
    state.B = B

    #groups = []
    #group = []
    #overlap = (group, pat) ->
    #  (row for row in group when pat.every((e, i) -> e == '?' or row[i] < e))
    #for row,i in mat
    #  if not(overlap(group,row))
    #    group.push(row)
    #  else
    #    groups.push(group)
    #    group = []

  count: (mat) ->
    if mat.length > 0
      s = new Sampler
            mat: mat
      s.iterate().count
    else
      1

  iterate: () ->
    st = new SearchTree()
    solct =  0
    @itersub = (state) ->
      parent = st.addChild(state, state.tree)
      if state.sample.length >= @mat[0].length
        solct++
        st.addLeaf({ sample: state.sample }, parent)
      else
        zeroct = @isPartialHood(state.sample.concat([0]))
        onect = @isPartialHood(state.sample.concat([1]))
        switch (onect + zeroct)
          when 0
            solct++
            st.addLeaf({ sample: state.sample }, parent)
          when 1
            nextval = if onect > 0 then 1 else 0
            @itersub
              sample: state.sample.concat([nextval])
              tree: parent
          when 2
            @itersub
              sample: state.sample.concat([0])
              tree: parent
            @itersub
              sample: state.sample.concat([1])
              tree: parent
    
    #cc = @connectedComponents(@mat)
    state =
      sample: []
      tree: null
    st.addChild state
    @itersub state
    result =
      count: solct
      tree: st

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

  getSamplesBranch: (args) ->
    state = args.state
    switch (args.childcount)
      when 0
        # shouldn't happen, because sample length would exceed row length in earlier check
        loopvars.done = args.solution(state)
      when 1
        nextval = if args.onect > 0 then 1 else 0
        args.branch
          sample: state.sample.concat([nextval])
          prob: state.prob
          estimate: state.estimate
          depth: state.depth + 1
          parentNode: state.node
      when 2
        rand = Math.floor(Math.random()*2)
        newprob = state.prob * 0.5
        if state.depth < args.loopvars.maxdepth
          estimate = state.estimate
        else
          estimate = state.estimate * 2 # assumes same type
        args.branch
          sample: state.sample.concat([rand])
          prob: newprob
          estimate: estimate
          depth: state.depth + 1
          parentNode: state.node
        if state.depth < args.loopvars.maxdepth
          opposite = rand ^ 1
          args.branch
            sample: state.sample.concat([opposite])
            prob: newprob
            estimate: estimate
            depth: state.depth + 1
            parentNode: state.node
          args.loopvars.branchct++


  getSamples: (in_sample, in_prob, samplect=INNER_SAMPLE_COUNT) ->
    stack = []
    samples = []
    branchPoints = []
    st = new SearchTree()
    branch = (argstate) ->
      argstate.node = st.addChild(argstate, argstate.parentNode)
      stack.push(argstate)
    solution = (argstate) ->
      st.addLeaf(argstate, argstate.parentNode)
      samples.push
        sample: argstate.sample
        estimate: argstate.estimate
      samplect--
      return samplect <= 0

    branch
      sample: in_sample
      prob: in_prob
      estimate: 1
      depth: 0
      parentNode: null
    loopvars =
      done: false
      ct: 0
      branchct: 0
      maxdepth: Math.ceil(Math.log(samplect) / Math.log(2))
    while stack.length > 0 and not loopvars.done
      state = stack.pop()
      loopvars.ct++
      zeroct = @isPartialHood(state.sample.concat([0]))
      onect = @isPartialHood(state.sample.concat([1]))
      if state.sample.length >= @mat[0].length
        loopvars.done = solution(state)
      else
        @getSamplesBranch
          state: state
          branch: branch
          childcount: zeroct + onect
          onect: onect
          solution: solution
          loopvars: loopvars
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

          result = timer.timeit(() -> sampler.iterate())
          tree = result.tree
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
  acc_avg = 0
  (acc_avg += mat[i][j].accuracy for j in [mincolct..maxcolct] for i in [minrowct..maxrowct])
  acc_avg /= ((maxcolct - mincolct) * (maxrowct - minrowct))
  mktable("Summary Accuracy (avg: #{acc_avg})", fmt_b)
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

consoletest = () ->
  colct = COLCT
  rowct = ROWCT
  edge_prob = EDGE_PROB
  samplect = SAMPLE_COUNT
  mat_type = MAT_TYPE

  create_mat = eval('bigraph.' + mat_type)
  rm = create_mat(rowct, colct)
  hoods = unions(rm)
  #console.log("hood count", mori.count(hoods))
  rm

if window?
  # browser
  inputs = htmlInputs(doCompute)
  doCompute(inputs)
  #console.log("I think uncaught type-errors from nvd3 can be ignored as long as graphs show up fine")
  #samplerStats()
else
  # console testing
  #console.log("console testing")
  consoletest()
