class window.BiGraph
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

  # Static methods below
  @matcopy: () ->
    newmat = ((x for x in row) for row in @mat)

  @getDegrees: (mat) ->
    addcol = (x, y) -> x + y
    rowcmp = (a, b) -> mori.into_array(mori.map(addcol, a, b))
    mori.reduce(rowcmp, mori.into_array(mat))

  @transpose: (mat) ->
    rmat = ([] for x in mat[0])
    for row,i in mat
      for x,j in row
        rmat[j][i] = mat[i][j]

class window.BiGraphGenerator

  constructor: (options) ->
    console.log("opt", options)
    @rowct = options.rowct
    @colct = options.colct
    @options = options

  getmat: (corefn) ->
    [colct, rowct] = [@colct, @rowct]
    row = () -> (corefn(i, j) for i in [1..colct])
    rows = (row() for j in [1..rowct])
    rows.rows = @rowct
    rows.cols = @colct
    rows
    
  rndmat: () ->
    [colct, rowct] = [@colct, @rowct]
    edge_prob = @options.edge_prob
    corefn = (i, j) -> Math.floor(Math.random() < edge_prob)
    @getmat(corefn)

  unitymat: () ->
    corefn = (i, j) -> (if i == j then 1 else 0)
    @getmat(corefn)
    
  unityskewmat: () ->
    [colct, rowct] = [@colct, @rowct]
    corefn = (i, j) -> (if i == j or i % colct == (j + 1) % colct or i % colct == (j + 2) % colct then 1 else 0)
    @getmat(corefn)
    
  unityskewmat_k: (k) ->
    [colct, rowct] = [@colct, @rowct]
    corefn = (i, j) ->
      if (1 for k_i in [0..(k-1)] when i % colct == (j + k_i) % colct).length > 0
        1
      else
        0
    @getmat(corefn)

  rndunitymat: () ->
    edge_prob = @options.edge_prob
    corefn = (i, j) -> (if i == j then 1 else 0) | Math.floor(Math.random() < edge_prob)
    @getmat(corefn)
