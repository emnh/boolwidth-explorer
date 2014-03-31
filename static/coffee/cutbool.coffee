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

# dependencies
# mori = mori
# bigRat = bigRat
window.H = emhHTML

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

   
doSetup = (rowct, colct, rm) ->
  [rows, cols] = [rowct, colct]
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
    H.table(H.tr(H.td(deg) for deg in BiGraph.getDegrees(rm)))
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
      dl = ([H.li("#{k}: #{v}")] for k,v of tree.state).reduce((a, b) -> a.concat(b))
      H.li(H.ul(dl))
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
    rowDegrees: BiGraph.getDegrees(rm)
    colDegrees: BiGraph.getDegrees(BiGraph.transpose(rm))
    matrix: (row for row in rm)
    hoodcount: hoodcount

makeProcessGraph = (opts) ->
  processGraph = (data) ->
    graph = new Graph()
    graph.parseDimacs(data)
    dc = new Decomposition()
    #tree = dc.trivialDecomposition(graph)
    #dc.computeExact(tree, graph)
    tree = dc.sampleImprover(graph)
    console.log("computing exact")
    htree = new HTMLTree({})
    htmldecomp = htree.decompToHTML(tree)
    htree = H.div(H.ul(htmldecomp), {class: 'decomp'})
    htree.ready(() -> $(htree).jstree())
    #console.log("htmldecomp", htmldecomp)
    content = [htree]
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
    # XXX: error, but method not in use
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
  fnamediv = getFileNameSelector("fnameselect")
  fnamediv.appendTo('#inputs')
  inputs.boxes = H.table(H.tr([H.td(label), H.td(input)]) for [label, input] in inputs.boxes)

  # setup select change handler
  handler = (evt) ->
    f = (data) ->
      g = new Graph()
      g.parseDimacs(data)
    fname = evt.currentTarget.value
    $.get(fname, "", f)
  fnameselect = fnamediv.find("select")
  fnameselect.change(handler)
  fnameselect.val("graphdata/graphLib_ours/cycle/c5.dimacs")
  fnameselect.trigger("change")

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
  edge_prob = bigRat(inputs.getedgeprob())
  samplect = inputs.getsamplecount()
  mat_type = inputs.getmat_type()

  #console.clear()
  
  r = $("#compute_results")
  r.empty()
  #console.log(BiGraph.unitymat)
  options =
    rowct: rowct
    colct: colct
    edge_prob: edge_prob
  bggen = new BiGraphGenerator(options)
  rm = bggen[mat_type]()
  doSetup(rowct, colct, rm)
  h = doUnions(rm)
  doFastUnions(rm)
  doDecomposition(rm)
  rm
  #r.collapse({})

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
          bigen =
            new BiGraphGenerator
              rowct: rowct
              colct: colct
              edge_prob: bigRat(set.edge_prob)
          rm = bigen[set.mat_type]()
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

  create_mat = BiGraph[mat_type]
  rm = create_mat(rowct, colct)
  hoods = unions(rm)
  #console.log("hood count", mori.count(hoods))
  rm

if window?
  # browser
  inputs = htmlInputs(doCompute)
  doCompute(inputs)
  #console.log("I think uncaught type-errors from nvd3 can be ignored as long as graphs show up fine")
  samplerStats()
else
  # console testing
  #console.log("console testing")
  consoletest()
