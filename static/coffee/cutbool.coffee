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

# row and column count of bipartite graph
G = 12
#bigRat = rational
EDGE_PROB = bigRat(1, 12)
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

posthoodstat = (data) ->
  $.ajax
    type: "POST"
    url: '/bigraph_stat'
    data: data
    success: (data) ->
      0
      #console.log("post success:", data)
    dataType: 'text'
   
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

deferred_max = 0
deferredHTML = (htype) ->
  deferred_max += 1
  defid = "deferred" + deferred_max
  opts =
    lines: 7  # The number of lines to draw
    length: 2  # The length of each line
    width: 3  # The line thickness
    radius: 3  # The radius of the inner circle
    corners: 1  # Corner roundness (0..1)
    rotate: 0  # The rotation offset
    direction: 1  # 1: clockwise, -1: counterclockwise
    color: '#000'  # #rgb or #rrggbb or array of colors
    speed: 1.6  # Rounds per second
    trail: 40  # Afterglow percentage
    shadow: false  # Whether to render a shadow
    hwaccel: false  # Whether to use hardware acceleration
    className: 'spinner'  # The CSS class to assign to the spinner
    zIndex: 2e9  # The z-index (defaults to 2000000000)
    top: '0%'  # Top position relative to parent
    left: '0%' # Left position relative to parent
  ret =
    jq: htype("", {id: defid, class: "loading", style: "position: relative;"})
    jqById: () -> $("#" + defid)
    id: defid
    spin: () ->
      spinner = new Spinner(opts).spin()
      ret.jq.append(spinner.el)
  ret.spin()
  ret
  
doUnions = (rm) ->
  #timer = new Timer()
  #hoods = timer.timeit(() -> unions(rm))
  tinfo = deferredHTML(H.span)
  titlefun = (tinfo) ->
    title = H.span("Trivial Neighborhood Algorithm ")
    title.append(tinfo.jq)
    title
    #title += "(t=#{elapsed.jq.outerHtml()}ms, count=#{hoodcount.jq})"
  content = deferredHTML(H.div)
  H.section(H.h1(titlefun(tinfo)), content.jq)

  #tinfo.jq.html("(t=#{timer.elapsed}ms, count=#{mori.count(hoods)})")
  updateinfo = (e) ->
    data = e.data
    timer = data.timer
    hoods = data.hoods
    tinfo.jq.html "(t=#{timer.elapsed}ms, count=#{mori.count(hoods)})"
    content.jq.empty()
    content.jq.append H.p("unions: #{timer.elapsed} ms")
    content.jq.append H.p("per hood: #{timer.elapsed / mori.count(hoods)} ms")
    content.jq.append getHoodPlaceHolder(hoods, H.u2list, "hoodsplacement")

    # Rough estimate based on degrees, depends on hood count from worker
    sampler = new Sampler({mat: rm})
    timer = new Timer()
    result = timer.timeit(() -> sampler.getRoughEstimate(mori.count(hoods)))
    rest_title.jq.html "(t=#{timer.elapsed}ms, count=#{result.rest}, acc=#{result.acc(result.rest)})"
    rest_content.jq.html [
      H.p("Rough estimate (degrees #{result.deg0}): #{result.rest}, acc: #{result.acc(result.rest)}")
      H.p("Rough estimate2 (degrees #{result.deg1}): #{result.rest2}, acc: #{result.acc(result.rest2)}")
      H.p("Average rough estimate: #{(result.avgest) / 2}, acc: #{result.acc(result.avgest)}")
      H.p("Random Graph Theoretical Estimate: (#{result.rndest}, acc: #{result.acc(result.rndest)})")]

  rest_title = deferredHTML(H.span)
  rest_content = deferredHTML(H.div)

  message =
    cmd: 'unions'
    mat: rm
  doWorker(message, updateinfo)
  #console.log(elapsed.jq.html("test"))
  #count.html("test")

  title = H.h1("Rough Estimate ")
  title.append(rest_title.jq)
  H.section(title, rest_content.jq)
  #title.click()

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
    showprops = ['hoodestimate', 'time', 'hoodcount']
    innerfmt = (tree) ->
      s = ("#{k}:#{tree.state[k]}" for k in showprops).join(",")
      if tree.leaf
        s += " leaf"
      s
    if tree.children?
      pre = if tree.state? then innerfmt(tree) else ""
      ret = H.li([pre,H.ul((@decompToHTML(c) for c in tree.children))])
    else if tree.leaf? and tree.leaf == true
      #dl = ([H.li("#{k}: #{v}")] for k,v of tree.state).reduce((a, b) -> a.concat(b))
      #dl = ([H.li("#{k}: #{v}")] for k,v of tree.state).reduce((a, b) -> a.concat(b))
      ret = H.li(tree.state.item)
      #H.li(H.span(tree.state.sample))
    ret.attr("data-treeid", tree.state.id)
    ret

  decompToMap: (tree) ->
    nodemap = {}
    flat = tree.flatten()
    for node in flat
      nodemap[node.state.id] = node
    nodemap

doFastUnions = (rm, samplect) ->
  timer = new Timer()
  state =
      mat: rm
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

  f = (h) -> H.ul(H.li(x.sample) for x in h)
  title = H.h1("Backtrack Neighborhoods (t=#{iter_elapsed}ms, count=#{hoodcount})")
  content =
    [
      H.p("Backtrack algorithm elapsed time: #{iter_elapsed} ms")
      H.p("Time per neighborhood: #{iter_elapsed / hoodcount} ms")
      H.div("Backtrack hood count: #{hoodcount}")
      getHoodPlaceHolder(hoods, f, "fasthoodsplacement")
      H.h2("Algorithm Search Tree")
      html_itertree
    ]
  H.section(title, content...)
  
  # Run first sampler
  sampler =
    new Sampler
      mat: rm
      inner_samplect: samplect / 2
  results = timer.timeit(() -> sampler.getEstimate(samplect / 2))
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
  title = H.h1("Estimate STree (#{sampleinfo})")
  H.section(title, htree, chart) # H.div("Search Tree"), ol)
  # TODO: make lazy load
  htree.click () ->
   $(".searchtree")
     .jstree()
     .on("loaded", () -> htree "open_all")
  #console.log("samples", results.samples)

  # Run second sampler
  sampler2 = new Sampler(state)
  results2 = timer.timeit(() -> sampler2.getQPosEstimate(samplect))
  estimate2 = results2.estimate

  # Output second sampler, TODO: tree?
  sample_elapsed2 = timer.elapsed
  acc2 = Math.round(estimate2 / hoodcount * 100) / 100
  sampleinfo = "t=#{sample_elapsed2}ms, N=#{samplect}, count=#{Math.round(estimate2)}, acc=#{acc2}"
  title = H.h1("Estimate QPos (#{sampleinfo})")
  H.section(title, "")

  # Run third sampler
  sampler3 = new BitSampler(state)
  results3 = timer.timeit(() -> sampler3.getEstimate(samplect))
  estimate3 = results3.estimate

  # Output third sampler, TODO: tree?
  sample_elapsed3 = timer.elapsed
  acc3 = Math.round(estimate3 / hoodcount * 100) / 100
  sampleinfo = "t=#{sample_elapsed3}ms, N=#{samplect}, count=#{Math.round(estimate3)}, acc=#{acc3}"
  title = H.h1("Estimate Bitsets (#{sampleinfo})")
  H.section(title, "")


  # Run fourth sampler
  sampler4 = new ProgressiveSampler(state)
  results4 = timer.timeit(() -> sampler4.getQPosEstimate(samplect))
  estimate4 = results4.estimate

  # Output third sampler, TODO: tree?
  sample_elapsed4 = timer.elapsed
  acc4 = Math.round(estimate4 / hoodcount * 100) / 100
  sampleinfo = "t=#{sample_elapsed4}ms, N=#{samplect}, count=#{Math.round(estimate4)}, acc=#{acc4}"
  title = H.h1("Estimate Progressive (#{sampleinfo})")
  H.section(title, "")

  # Output average sampler
  #elapsed = sample_elapsed + sample_elapsed2
  #estimate = Math.round((estimate + estimate2) / 2)
  #acc = Math.round(estimate / hoodcount * 100) / 100
  #sampleinfo = "t=#{elapsed}ms, N=#{samplect*2}, count=#{estimate}, acc=#{acc}"
  #title = H.h1("Average Estimate (#{sampleinfo})")
  #H.section(title, "")

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
  return
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
    #console.log("computing exact")
    #dc.computeExact(tree, graph)
    tree = dc.sampleImprover(graph)
    htree = new HTMLTree({})
    htmldecomp = htree.decompToHTML(tree)
    nodemap = htree.decompToMap(tree)
    htree = H.div(H.ul(htmldecomp), {class: 'decomp'})
    #console.log("htmldecomp", htmldecomp)
    nodeinfo = H.div("nodeinfo", { class: "nodeinfo" })
    showinfo = (tree) ->
      nodeinfo.empty()
      showvalue = (k, v) ->
        if k == 'mat'
          [H.dt("#{k}"), H.dd(H.mat2table(v))]
        else
          [H.dt("#{k}"), H.dd("#{v}")]
      dl = (showvalue(k, v) for k,v of tree.state).reduce((a, b) -> a.concat(b))
      dl = H.dl(dl)
      dl.appendTo(nodeinfo)
    htree.ready () ->
      jstree = $(htree).jstree()
      selectnode = (e, data) ->
        htmlid = data.selected[0]
        htmlnode = jstree.find('#' + htmlid)
        treeid = htmlnode.attr("data-treeid")
        treenode = nodemap[treeid]
        showinfo(treenode)
      $(htree).on("select_node.jstree", selectnode)
    content = [htree, nodeinfo]
    title = H.h1("Decomposition of #{opts.fname}")
    H.section(title, content...)

doDecomposition = (rm) ->
  sampler =
    new Sampler
      mat: rm
  #fname = "graphdata/graphLib_ours/hsugrid/hsu-4x4.dimacs"
  #fname = "graphdata/graphLib/coloring/queen8_8.dgf"
  #fname = "graphdata/graphLib/coloring/queen5_5.dgf"
  fname = "graphdata/graphLib/coloring/queen7_7.dgf"
  #fname = "graphdata/graphLib/protein/1aac_graph.dimacs"
  #fname = "graphdata/graphLib/coloring/anna.dgf"
  #fname = "graphdata/graphLib/coloring/jean.dgf"
  #fname = "graphdata/graphLib_ours/cycle/c5.dimacs"
  #fname = "graphdata/graphLib/other/sodoku.dgf"
  processGraph =
    makeProcessGraph
      fname: fname
  $.get(fname, "", processGraph)

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
  doUnions(rm)
  doFastUnions(rm, samplect)
  #doDecomposition(rm)
  #RandomCutGraph.doAllGraphs(rm)
  rm
  #r.collapse({})

samplerStats = () ->
  sets = []
  mat = []
  minrowct = 8
  mincolct = 8
  maxrowct = 16
  maxcolct = 16
  samplect = 10 #inputs.getsamplecount()
  inner_samplect = 10
  timer = new Timer()
  for edge_prob in [bigRat(1,2)]
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
          sampler =
            new Sampler
              mat: rm
              inner_samplect: inner_samplect

          result = timer.timeit(() -> sampler.iterate())
          tree = result.tree
          elapsed_hoods = timer.elapsed
          count = tree.getSolutions().length

          results = timer.timeit () -> sampler.getEstimate(samplect)
          estimate = Math.round(results.estimate)
          elapsed_samples = timer.elapsed
          acc = Math.round(estimate / count * 100)
          timeratio = Math.round(elapsed_samples / elapsed_hoods * 100) / 100
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

doWorker = (message, callback) ->
  worker = new Worker('coffee/workers/worker.js')
  worker.addEventListener('message', callback, false)
  worker.postMessage message

self.cutboolMain = () ->
  self.H = emhHTML
  inputs = htmlInputs(doCompute)
  doCompute(inputs)
  #(console.log(i) for i in testfun())
  #console.log("I think uncaught type-errors from nvd3 can be ignored as long as graphs show up fine")
  #samplerStats()

self.hello = () -> 42

if window? and not worker?
  # browser
else if worker
  # imported from worker
  #console.log("cutbool from worker")
  self.H = self.emhHTML
