window.pack_view = (containerid, graphvis) ->
  idstr = (nodes) ->
    nodes.reduce ((a, n) ->
      a + "," + n.id
    ), ""
  nodesRepr = (nodes) ->
    JSON.stringify nodes.map((x) ->
      x.id
    )
  Splitter = (postproc) ->
    getLeafNodes = (root) ->
      leaves = []
      flat = flattentree(root)
      for ni of flat
        n = flat[ni]
        leaves.push n  unless n.children
      leaves
    split = (nodes, nodeid) ->
      nodeid = ""  unless nodeid?
      if nodes.length > 1
        mid = Math.floor(nodes.length / 2)
        left = nodes.slice(0, mid)
        right = nodes.slice(mid)
        leftsplit = split(left, nodeid + "l")
        rightsplit = split(right, nodeid + "r")
        nodecopy = nodes.slice(0)
        nodecopy.sort (a, b) ->
          a - b

        tree =
          name: "" + nodes.length
          children: [
            leftsplit
            rightsplit
          ]
          id: nodeid
          getLeafNodes: () -> getLeafNodes(tree)
        postproc tree
      else if nodes.length is 1
        node = nodes[0]
        tree =
          name: "" + node.id
          size: 1
          id: node.id
          getLeafNodes: () -> getLeafNodes(tree)
        postproc tree
      else
        {}
    unless postproc
      postproc = (x) ->
        x
    split: split
  initpack = ->
    diameter = jq(containerid).width()
    width = diameter
    height = diameter
    pack = d3.layout.pack().size([ # tree traversal order
      diameter - 4
      diameter - 4
    ]).value((d) ->
      d.size
    ).sort(null)
    svg = d3.select(containerid).append("svg").attr("width", diameter).attr("height", diameter).append("g").attr("transform", "translate(2,2)")
    background = svg.node()
    svg.append("svg:rect").attr("width", width).attr("height", height).attr "fill", "white"
    diameter: diameter
    pack: pack
    svg: svg
    background: background
  dragstart = (d) ->
    state = packvis_obj.state
    circle = d3.select("#treenode" + d.id)
    x = d.x + d.r + 5
    y = d.y
    items = state.pack.nodes(d).map((x) ->
      jq(d3.select("#treenode" + x.id).node()).clone()
    )
    
    # pack.nodes changes the tree, so reset the changes to x, y, r...
    # TODO: clone tree first instead
    state.pack.nodes state.root
    items[0].attr "translate"
    state.dragstart =
      x: x
      y: y

    state.dragobj = d
    jq(state.svg.append("g").attr("id", "drag").attr("opacity", "0.5").node()).append items
    return
  dragmove = (d) ->
    state = packvis_obj.state
    
    # cloned nodes have coordinates relative to svg, just like the mouse,
    # so translate drag group by distance the mouse moved from drag start
    state.svg.selectAll("circle").classed "dragtarget", false
    d3.select(d3.event.sourceEvent.target).classed "dragtarget", true
    x = d3.mouse(state.background)[0] - state.dragstart.x
    y = d3.mouse(state.background)[1] - state.dragstart.y
    d3.select("#drag").attr "transform", "translate(" + x + "," + y + ")"
    return
  dragend = (d) ->
    state = packvis_obj.state
    state.svg.selectAll("circle").classed "dragtarget", false
    d3.select("#drag").remove()
    flat = flattentree(state.root)
    d1 = state.dragobj
    d2 = jq(d3.event.sourceEvent.target).data("dragtarget")
    
    # swap children
    for ni of flat
      n = flat[ni]
      continue  if n.children is `undefined`
      if n.children[0] is d1
        console.log "swap1"
        n.children[0] = d2
      else if n.children[0] is d2
        console.log "swap2"
        n.children[0] = d1
      if n.children[1] is d1
        console.log "swap3"
        n.children[1] = d2
      else if n.children[1] is d2
        console.log "swap4"
        n.children[1] = d1
    packvis_obj.refresh()
    return
  pack = ->
    state = packvis_obj.state
    svg = state.svg
    pack = state.pack
    diameter = state.diameter
    format = d3.format(",d")
    nodes = pack.nodes(state.root)
    treenodes = svg.selectAll(".treenode").data(nodes, (x) ->
      x.id
    )
    
    #var titles = svg.selectAll(".treenode title").data(nodes);
    
    #treenodes.attr("fill", "gray");
    first = treenodes.empty()
    newnodes = treenodes.enter().append("g")
    newnodes.attr "id", (d) ->
      "treenode" + d.id.toString()

    unless first
      treenodes.classed "entered", false
      newnodes.classed "entered", true
    treenodes.order()
    # using mousedown instead
    node_drag = d3.behavior.drag().on("dragstart", dragstart).on("drag", dragmove).on("dragend", dragend)
    treenodes.classed("treenode", true).classed("leaf", (d) ->
      not d.children
    ).call(node_drag).on("mouseover", (d) ->
      if d.children?
        ids = get_ids(d.getLeafNodes())
        packvis_obj.markNodes ids
      return
    ).on("mouseout", (d) ->
      packvis_obj.markNodes []
      return
    ).transition().duration(500).attr "transform", (d) ->
      "translate(" + d.x + "," + d.y + ")"

    newnodes.append "title"
    treenodes.select("title").text (d) ->
      d.title

    newnodes.append "circle"
    treenodes.select("circle").transition().duration(500).attr("r", (d) ->
      d.r
    ).each (d) ->
      jq(this).data "dragtarget", d
      return

    
    # show cutbool
    newnodes.filter((d) ->
      d.children
    ).append "text"
    treenodes.filter((d) ->
      d.children
    ).select("text").transition().duration(500).attr("dy", (d) ->
      "-" + d.r / 1.5
    ).style("text-anchor", "middle").style("font-size", (d) ->
      d.r / 3
    ).text (d) ->
      d.name.substring 0, d.r / 3

    newnodes.filter((d) ->
      not d.children
    ).append "text"
    treenodes.filter((d) ->
      not d.children
    ).select("text").transition().duration(500).attr("dy", ".3em").style("text-anchor", "middle").style("font-size", (d) ->
      d.r
    ).text (d) ->
      d.name.substring 0, d.r / 3

    treenodes.exit().transition().duration(500).attr("r", 0).remove()
    d3.select(self.frameElement).style "height", diameter + "px"
    return
  cutbool = (simplegraph, leftnodes) ->
    allnodes = get_ids(simplegraph.nodes)
    rightnodes = set.diff(allnodes, leftnodes)
    hoods = leftnodes.map((n) ->
      hood = set.intersect(simplegraph.nodes[n].neighbors, rightnodes)
      hood.sort (a, b) ->
        a - b

      hood
    )
    emptyset = []
    unions = {}
    unions[set.canonical(emptyset)] = 1
    hoods.forEach (h) ->
      f = (hood) ->
        (u) ->
          oldhood = set.decanonical(u)
          newhood = set.union(oldhood, hood)
          unions[set.canonical(newhood)] = 1
          return

      (Object.keys(unions)).forEach f(h)
      return

    log = jq("#debug")
    for u of unions
      log.append "<p>" + u + "</p>"
    unions
  Cutter = (simplegraph) ->
    computeCut = (tree) ->
      leftnodes = tree.getLeafNodes().map((n) ->
        n.id
      )
      leftnodes.sort()
      cbnodes = JSON.stringify(leftnodes)
      
      # cache. take note on graph change if tree is not rebuilt.
      return tree  if tree.cbnodes is cbnodes
      u = cutbool(simplegraph, leftnodes)
      cb = Object.keys(u).length
      tree.cutbool = cb
      tree.size = cb
      if tree.children
        tree.name = "" + cb
        tree.title = "" + tree.cbnodes
      tree
    computeCut
  
  # split again and redraw after graph changes
  redraw_pack = ->
    graph = packvis_obj.graphvis.graph
    simplegraph = getSimpleGraph(graph)
    packvis_obj.cutter = Cutter(simplegraph)
    root = Splitter(packvis_obj.cutter).split(graph.nodes)
    packvis_obj.state.root = root
    packvis_obj.pack()
    return
  redraw_swap = ->
    
    # recompute cutbool and redraw tree
    flat = flattentree(packvis_obj.state.root)
    for ni of flat
      packvis_obj.cutter flat[ni]
    packvis_obj.pack()
    return
  refresh = ->
    for fi of packvis_obj.onchange
      packvis_obj.onchange[fi]()
    return
  jq = jQuery
  nodedata = undefined
  packvis_obj = this
  packvis_obj.graphvis = graphvis
  packvis_obj.markNodes = ->

  packvis_obj.pack = pack
  packvis_obj.redraw_pack = redraw_pack
  packvis_obj.refresh = refresh
  packvis_obj.onchange = [redraw_swap]
  packvis_obj.state = initpack()
  packvis_obj.redraw_pack()
  packvis_obj
