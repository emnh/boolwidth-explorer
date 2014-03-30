class window.Node
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

class window.Graph
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
    @edges = edges
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
    @noderev = {}
    @noderev = {}
    nodeseq = (name for name,node of @nodes)
    for name, i in nodeseq
      @noderev[name] = i
    #console.log(@noderev)

window.getSimpleGraph = (graph) ->
  simplenodes = {}
  graph.nodes.forEach (n) ->
    simplenodes[n.id] =
      id: n.id
      neighbors: []

    return

  simplelinks = graph.links.map((l) ->
    simplenodes[l.source.id].neighbors.push l.target.id
    simplenodes[l.target.id].neighbors.push l.source.id
    [
      l.source.id
      l.target.id
    ]
  )
  simplegraph =
    nodes: simplenodes
    links: simplelinks

  simplegraph

window.formatGraph = (graph) ->
  s = []
  g = getSimpleGraph(graph)
  s.push "# dgf format"
  s.push "# nodes: " + graph.nodes.map((x) ->
    x.id
  )
  s.push "p edge " + graph.nodes.length + " " + graph.links.length
  g.links.sort (x, y) ->
    x[0] - y[0]

  for li of g.links
    l = g.links[li]
    s.push "e " + l[0] + " " + l[1]
  s = s.reduce((x, y) ->
    x + "\n" + y
  )
  s

window.flattentree = (root) ->
  flat = []
  stack = [root]
  until (stack.length is 0)
    root = stack.pop()
    flat.push root
    for c of root.children
      stack.push root.children[c]
  flat

window.get_ids = (nodes) ->
  
  # function works on maps as well as arrays, so the following won't work
  # return nodes.map(function(x) { return x.id; });
  ids = []
  for node of nodes
    ids.push nodes[node].id
  ids

window.formatTree = (tree) ->
  s = []
  s.push "# format: <treenode> <leafnodes>"
  s.push "# name of <treenode> = (<r[ight]>|<l[eft]>)*"
  s.push "# e.g. rll for right left left. this unique tree node id format is arbitrary."
  flat = flattentree(tree)
  for fi of flat
    f = flat[fi]
    id = (if f.id is "" then " " else f.id)
    s.push id + " " + get_ids(f.getLeafNodes())  if f.children
  s = s.reduce((x, y) ->
    x + "\n" + y
  )
  s
