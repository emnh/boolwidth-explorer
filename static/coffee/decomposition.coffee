class window.Tree
  constructor: (options) ->
    @[key] = value for key, value of options

  flatten: () ->
    nodes = []
    dfs = (tree) ->
      nodes.push(tree)
      if tree.children?
        (dfs(child) for child in tree.children)
    dfs(@)
    nodes

spliceImmutable = (array, index, howmany, items...) ->
  newar = (x for x in array)
  newar.splice(index, howmany, items...)
  return newar

class window.Decomposition
  
  constructor: () ->
    0

  getBipartiteMatrix: (left, graph) ->
    leftmap = {}
    setmap = (x) -> leftmap[x] = 1
    (setmap(x) for x in left)
    # right = other half of graph
    right = (x for x of graph.nodes when not(leftmap[x]?))
    #console.log("left", left)
    #console.log("leftmap", leftmap)
    #console.log("right", right)
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

  computeExact: (tree, graph) ->
    dc = @
    processTree = (tree) ->
      tree.state.mat = dc.getBipartiteMatrix(tree.state.items, graph)
      tree.state.hoodcount = Sampler.count(tree.state.mat)
    dfs = (tree) ->
      if tree.children?
        processTree(tree)
        (dfs(child) for child in tree.children)
      else
        0 # TODO: single element, 1 or 2 hoods
    dfs(tree)

  computeSample: (tree, graph, samplect) ->
    dc = @
    maxhoodct = 0
    maxtree = undefined
    processTree = (tree) ->
      tree.state.mat = dc.getBipartiteMatrix(tree.state.items, graph)
      sampler =
        new Sampler
          mat: tree.state.mat
      timer = new Timer()
      results = timer.timeit(() -> sampler.getEstimate(samplect))
      hoodct = results.estimate
      tree.state.hoodestimate = [hoodct, Math.round(Math.log(hoodct) / Math.log(2))]
      tree.state.time = timer.elapsed
      if hoodct > maxhoodct
        maxhoodct = hoodct
        maxtree = tree
    dfs = (tree) ->
      if tree.children?
        processTree(tree)
        (dfs(child) for child in tree.children)
      else
        0 # TODO: single element, 1 or 2 hoods
    dfs(tree)
    ret =
      maxhoodct: maxhoodct
      maxtree: maxtree

  # split half and half
  decompose: (graph, separator) ->
    
    maxid = 0
    dc = (nodes) ->
      if nodes.length > 1
        [left, right] = separator(nodes)
        tree =
          new Tree
            leftnodes: left
            rightnodes: right
            left: dc(left)
            right: dc(right)
            state:
              id: maxid++
              items: nodes
        tree.children = [tree.left, tree.right]
        tree
      else
        tree =
          new Tree
            item: nodes[0]
            leaf: true
            state:
              id: maxid++
              items: nodes
              item: nodes[0]
    #console.log(Object.keys(graph.nodes).length, graph.nodes)
    nodes = Object.keys(graph.nodes)
    @tree = dc(nodes)

    @tree

  trivialDecomposition: (graph) ->
    separator = (nodes) ->
      mid = nodes.length / 2
      left = nodes.slice(0, mid)
      right = nodes.slice(mid)
      [left, right]
    @decompose(graph, separator)

  getSampleCutBool: (mat, samplect) ->
    sampler =
      new Sampler
        mat: mat
    results = sampler.getEstimate(samplect)
    Math.round(results.estimate)

  swap: (graph, boxA, boxB, maxval, samplect) ->
    arand = Math.floor(Math.random() * boxA.length)
    brand = Math.floor(Math.random() * boxB.length)
    anode = boxA[arand]
    bnode = boxB[brand]
    newA = spliceImmutable(boxA, arand, 1, bnode)
    newB = spliceImmutable(boxB, brand, 1, anode)
    console.log("new", newA, newB)
    cuts = (@getBipartiteMatrix(x, graph) for x in [newA, newB])
    hoodcounts = (@getSampleCutBool(mat, samplect) for mat in cuts)
    #hoodcounts = (Sampler.count(mat) for mat in cuts)
    console.log(hoodcounts)
    if hoodcounts[0] < maxval and hoodcounts[1] < maxval
      console.log("swapping #{anode} with #{bnode}")
      [newA, newB]
    else
      console.log("returning same")
      [boxA, boxB]

  #findGoodCutGreedy: (graph) ->
  findGoodTriCut: (graph) ->
    # greedy initial placement
    samplect = 30
    nodes =  Object.keys(graph.nodes)
    console.log(nodes)
    boxes = [[],[],[]]
    oldhoodcounts = [1, 1, 1]
    for node,k in nodes
      #console.log(("#{x.length}: " + x.join(",") for x in boxes))
      A = boxes[0].concat(node)
      B = boxes[1].concat(node)
      C = boxes[2].concat(node)
      cuts = (@getBipartiteMatrix(x, graph) for x in [A, B, C])
      #hoodcounts = (@getSampleCutBool(mat, samplect) for mat in cuts)
      hoodcounts = (Sampler.count(mat) for mat in cuts)
      newmaxhoodcount = max(hoodcounts)
      newmaxcounts = [
        max(oldhoodcounts.concat().splice(0, 1, hoodcounts[0]))
        max(oldhoodcounts.concat().splice(1, 1, hoodcounts[1]))
        #max(oldhoodcounts.concat().splice(2, 1, hoodcounts[2]))
      ]
      nextgenmin = min(newmaxcounts)
      next = (i for i in [0..1] when newmaxcounts[i] <= nextgenmin)
      if next.length > 0
        next = next[0]
      else
        console.log("warning: no nextgenmin")
        next = Math.floor(Math.random() * 3)
      boxes[next] = boxes[next].concat(node)
      oldhoodcounts = hoodcounts
      console.log("log", (Math.round(Math.log(x) * 100 / Math.log(2)) / 100 for x in hoodcounts))
      console.log("hoods", hoodcounts)
      console.log(Math.round((k + 1) * 100 / nodes.length) + "%")
    
    #console.log("computing exact")
    #cuts = (@getBipartiteMatrix(x, graph) for x in boxes)
    #hoodcounts = (Sampler.count(mat) for mat in cuts)
    #console.log("exact", hoodcounts)

    for k in []
      console.log("k", k)
      samplect = 10 #Math.max(30, i * 10)
      cuts = (@getBipartiteMatrix(x, graph) for x in boxes)
      hoodcounts = (@getSampleCutBool(mat, samplect) for mat in cuts)
      #hoodcounts = (Sampler.count(mat, samplect) for mat in cuts)
      console.log("old hoodcounts", hoodcounts)
      maxval = max(hoodcounts)
      for i in [0..2]
        [l, r] = @swap(graph, boxes[i], boxes[(i + 1) % 3], maxval, samplect)
        boxes[i] = l
        boxes[(i + 1) % 3] = r
      console.log("swap")
      console.log(("#{x.length}: " + x.join(",") for x in boxes))
      console.log(hoodcounts)

    # check exact
    #console.log("computing exact")
    #cuts = (@getBipartiteMatrix(x, graph) for x in boxes)
    #hoodcounts = (Sampler.count(mat) for mat in cuts)
    #console.log("exact", hoodcounts)
    
  sampleImprover: (graph) ->
    @findGoodTriCut(graph)
    tree = @trivialDecomposition(graph)
    #@computeSample(tree, graph, 40)
    #@computeExact(tree, graph)
    tree
