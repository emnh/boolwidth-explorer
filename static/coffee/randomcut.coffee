self.RandomCutGraph = {}

self.RandomCutGraph.randomCut = (graph, log, results) ->
  dc = new Decomposition()
  left = []
  right = []
  for node of graph.nodes
    if Math.random() > 0.5
      right.push(node)
    else
      left.push(node)
  results.left = left
  results.right = right
  #log("left|right", left, "|", right)
  mat = dc.getBipartiteMatrix(left, graph)
  results.rows = mat.rows
  results.cols = mat.cols
  results.mat = mat
  return
  #bigraph_table = H.mat2table(mat).addClass("bigraph_table")
  #bigraph_table.appendTo('body')
  samplect = 10
  inner_samplect = 10
  sampler =
    new Sampler
      mat: mat
      inner_samplect: inner_samplect
  results.samplect = samplect
  results.inner_samplect = 10
  timer = new Timer()
  est_results = timer.timeit(() -> sampler.getEstimate(samplect))
  hoodct = est_results.estimate
  hoodlog = Math.log(hoodct) / Math.log(2)
  results.estimate_elapsed = timer.elapsed
  results.estimate_hoodct = hoodct
  log("hoodct estimate (#{timer.elapsed}ms): #{hoodct}, log: #{hoodlog}")
  if hoodct < 100000
    log("computing exact...")
    timer = new Timer()
    hoods = timer.timeit(() -> unions(mat))
    hoodct = mori.count(hoods)
    hoodlog = Math.log(hoodct) / Math.log(2)
    results.exact_hoodct = hoodct
    results.exact_elapsed = timer.elapsed
    log("hoodct exact (#{timer.elapsed}ms): #{hoodct}, bw: #{hoodlog}")
    acc = Math.round(results.estimate_hoodct * 100 / results.exact_hoodct) / 100
    log("acc", acc)

self.RandomCutGraph.makeProcessGraphRandomCut = (opts) ->
  processGraph = (data) ->
    id = opts.id
    results = {}
    log = (msg...) -> console.log("#{id}", msg...)
    graph = new Graph()
    graph.parseDimacs(data)
    nodecount = Object.keys(graph.nodes).length
    edgecount = graph.edges.length
    #if nodecount < 100
    console.log("")
    results.id = opts.id
    results.fname = opts.fname
    results.nodecount = nodecount
    results.edgecount = edgecount
    log("filename: ", opts.fname)
    log("nodes length", nodecount)
    log("edges length", edgecount)
    
    #for i in [0..10] do multiple full iterations instead perhaps
    RandomCutGraph.randomCut(graph, log, results)
    log("results", JSON.stringify(results))

    opts.progress[0]++
    log("progress #{opts.progress[0]}/#{opts.totalcount}")
    if (opts.progress[0] == opts.totalcount)
      console.log("finished")

self.RandomCutGraph.doGraph = (fname) ->
  processGraph =
    RandomCutGraph.makeProcessGraphRandomCut
        id: 0
        totalcount: 1
        progress: [0]
        fname: fname
  $.get(fname, "", processGraph)

self.RandomCutGraph.doAllGraphs = () ->
  fnamelist = "/graphfiles.txt"
  progress = [0]

  processList = (data) ->
    lines = data.split('\n')
    lines = (line for line in lines when line != '')
    totalcount = lines.length
    for fname,i in lines[0..totalcount-1]
      do (fname) ->
        processGraph =
          RandomCutGraph.makeProcessGraphRandomCut
            id: i
            totalcount: totalcount
            fname: fname
            progress: progress
        $.get(fname, "", processGraph)

  $.ajax
    url: fnamelist
    data: ""
    success: processList
    dataType: "text"
  "doAllGraphs started"
