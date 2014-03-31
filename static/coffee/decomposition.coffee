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

class window.Decomposition
  
  constructor: () ->
    0

  getBipartiteMatrix: (tree, graph) ->
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

  computeExact: (tree, graph) ->
    dc = @
    processTree = (tree) ->
      tree.state.mat = dc.getBipartiteMatrix(tree, graph)
      sampler =
        new Sampler
          mat: tree.state.mat
      tree.state.hoodcount = sampler.count(tree.state.mat)
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
      tree.state.mat = dc.getBipartiteMatrix(tree, graph)
      sampler =
        new Sampler
          mat: tree.state.mat
      timer = new Timer()
      results = timer.timeit(() -> sampler.getEstimate(samplect))
      hoodct = results.estimate
      tree.state.hoodestimate = hoodct
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
  trivialDecomposition: (graph) ->
    
    maxid = 0
    dc = (nodes) ->
      if nodes.length > 1
        mid = nodes.length / 2
        left = nodes.slice(0, mid)
        right = nodes.slice(mid)
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
              item: nodes[0]
    #console.log(Object.keys(graph.nodes).length, graph.nodes)
    nodes = Object.keys(graph.nodes)
    @tree = dc(nodes)

    @tree
    
  sampleImprover: (graph) ->
    tree = @trivialDecomposition(graph)
    @computeSample(tree, graph, 20)
    @computeExact(tree, graph)
    tree
    
