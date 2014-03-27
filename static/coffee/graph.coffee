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
