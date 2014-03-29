window.force_view = (options) ->

  container = options.container
  # options.graph can contain graph to show

  resetMouseVars = ->
    mvars.mousedown_node = null
    mvars.mouseup_node = null
    mvars.mousedown_link = null
    return

  dragstart = (d, i) ->
    mvars.mousedown_node = d
    if mvars.mousedown_node is mvars.selected_node
      mvars.selected_node = null
    else
      mvars.selected_node = mvars.mousedown_node
    mvars.selected_link = null
    
    # reposition drag line
    drag_line.attr("class", "link")
      .attr("x1", mvars.mousedown_node.x)
      .attr("y1", mvars.mousedown_node.y)
      .attr("x2", mvars.mousedown_node.x)
      .attr("y2", mvars.mousedown_node.y)
    redraw()
    return

  dragmove = (d, i) ->
    point = d3.mouse(mvars.background)
    tick()
    return

  dragend = (d, i) ->
    target = d3.event.sourceEvent.target
    target = jq(target).data("dragtarget")
    if target
      mvars.mouseup_node = target
      add_edge mvars.mouseup_node, mvars.mouseup_node.index
    else
      point = d3.mouse(mvars.background)
      add_node point
    
    # hide drag line
    drag_line.attr "class", "drag_line_hidden"
    
    # clear mouse event vars
    resetMouseVars()
    return
 
  mousedown = ->
    console.log "svg mousedown"
    
    return 0
    # allow panning if nothing is selected
    #vis.call(d3.behavior.zoom().on("zoom"), rescale);
    return  if not mvars.mousedown_node and not mvars.mousedown_link

  mousemove = ->
    return  unless mvars.mousedown_node
    
    #console.log("svg mousemove");
    
    # update drag line
    drag_line
      .attr("x1", mvars.mousedown_node.x)
      .attr("y1", mvars.mousedown_node.y)
      .attr("x2", d3.mouse(mvars.background)[0])
      .attr "y2", d3.mouse(mvars.background)[1]
    return

  mouseup = ->
    console.log "svg mouseup"
    point = d3.mouse(mvars.background)
    add_node point
    return

  add_node = (point) ->
    if mvars.mousedown_node
      
      # hide drag line
      drag_line.attr "class", "drag_line_hidden"
      unless mvars.mouseup_node
        
        # add node
        node =
          x: point[0]
          y: point[1]
          id: d3.max(force_obj.nodes, (d) -> parseInt(d.id, 10)) + 1

        n = force_obj.nodes.push(node)
        
        # select new node
        mvars.selected_node = node
        mvars.selected_link = null
        
        # add link to mousedown node
        force_obj.links.push
          source: mvars.mousedown_node
          target: node

      redraw()
    return

  add_edge = (d, i) ->
    console.log "add_edge: " + d
    if mvars.mousedown_node
      mvars.mouseup_node = d
      if mvars.mouseup_node is mvars.mousedown_node
        console.log "self-loop"
        resetMouseVars()
        return
      
      # add link
      link =
        source: mvars.mousedown_node
        target: mvars.mouseup_node

      force_obj.links.push link
      
      # select new link
      mvars.selected_link = link
      mvars.selected_node = null
      
      # enable zoom
      #vis.call(d3.behavior.zoom().on("zoom"), rescale);
      redraw()
    return
 
  tick = (e) ->
    crossing = (n) ->
      
      # determine if node has neighbor on the other side of bipartition
      force_obj.marked_nodes[o.id]
      links.any (link) ->
        s = link.source
        t = link.target
        if s is n or s is t
          same_side = ids[s.id] is ids[t.id]
          not same_side
        else
          false

    gstate.link.attr("x1", (d) ->
      d.source.x
    ).attr("y1", (d) ->
      d.source.y
    ).attr("x2", (d) ->
      d.target.x
    ).attr "y2", (d) ->
      d.target.y

    if force_obj.marked_nodes isnt `undefined` and e isnt `undefined`
      k = 10 * e.alpha
      force_obj.nodes.forEach (o, i) ->

    
    #o.x += force_obj.marked_nodes[o.id] ? k : -k;
    #o.y += i & 1 ? k : -k;
    #o.x = force_obj.marked_nodes[o.id] ? 100 : o.x;
    gstate.node.attr "transform", (d) ->
      "translate(" + d.x + "," + d.y + ")"

    return
  
  # rescale g
  rescale = ->
    trans = d3.event.translate
    scale = d3.event.scale
    vis.attr "transform", "translate(" + trans + ")" + " scale(" + scale + ")"
    return
  getDragFunction = ->
    dragfunction = undefined
    im = d3.select("#interaction_mode")
    value = im.property("value")
    #console.log("interaction mode optval", value)
    dragfunction =
      if value == "move"
        force_layout.drag
      else
        node_drag
    dragfunction
  
  # redraw force layout
  redraw = (state) ->
    drawNodes = (state) ->
      node = gstate.node = gstate.node.data(force_obj.nodes, (d) -> d.id)
      g = node.enter().append("svg:g").attr("class", "node")
      g.append("svg:circle").attr("class", "node").attr("r", 5).transition().duration(750).ease("elastic").attr "r", 10
      g.append("svg:text").attr("x", 0).attr("y", 4).attr("class", "id").text (d, i) ->
        d.id
      
      # drag on g and each child of .node svg:g
      g.call getDragFunction()
      g.each (d, i) ->
        d3this = d3.select(this)
        d3this.selectAll("*").each f = (o) ->
          d3.select(this).call getDragFunction()
          jq(this).data "dragtarget", d
          return

        return

      node.exit().transition().duration(500).attr("r", 0).remove()
      node.classed "node_selected", (d) ->
        d is mvars.selected_node

      node.classed "node_target", (d) ->
        d is mvars.node_target

      return
    drawLinks = ->
      #link = vis.selectAll(".link")
      link = gstate.link = gstate.link.data(force_obj.links)
      mf = (d) ->
        mvars.mousedown_link = d
        if mvars.mousedown_link is selected_link
          mvars.selected_link = null
        else
          mvars.selected_link = mousedown_link
        mvars.selected_node = null
        redraw(state)
      link.enter()
        .insert("line", ".node")
        .attr("class", "link")
        .on("mousedown", mf)

      link.exit().remove()
      link.classed "link_selected", (d) ->
        d is mvars.selected_link

      return
    saveData = ->
      graph =
        nodes: force_obj.nodes
        links: force_obj.links

      graphstr = JSON.stringify(JSON.decycle(graph))
      try
        window.localStorage["graph"] = graphstr
      catch e
        console.log "localStorage not supported. can't save graph."
      return
    
    drawNodes(state)
    drawLinks()
    saveData()
    console.log "redraw"
    force_layout.start()
    if force_obj.nodes and force_obj.links
      force_obj.redraw_callbacks.forEach (f) ->
        f()
        return

    return
  spliceLinksForNode = (node) ->
    toSplice = force_obj.links.filter((l) ->
      (l.source is node) or (l.target is node)
    )
    toSplice.map (l) ->
      force_obj.links.splice force_obj.links.indexOf(l), 1
      return

    return
  keydown = ->
    return  if not selected_node and not selected_link
    switch d3.event.keyCode
      # backspace
      when 8, 46 # delete
        if selected_node
          force_obj.nodes.splice force_obj.nodes.indexOf(selected_node), 1
          spliceLinksForNode selected_node
        else force_obj.links.splice force_obj.links.indexOf(selected_link), 1  if selected_link
        selected_link = null
        selected_node = null
        redraw()
        break
    return
  markNodes = (node_ids) ->
    ids = {}
    for i of node_ids
      ids[node_ids[i]] = 1
    gstate.node.classed "node_marked", (d) ->
      ids[parseInt(d.id)]

    force_obj.marked_nodes = ids
    
    #console.log(force_layout.linkStrength);
    force_layout.linkStrength (link) ->
      s = link.source
      t = link.target
      same_side = ids[s.id] is ids[t.id]
      (if same_side then 1 else 0)

    force_layout.start()
    return
  jq = jQuery
  throw "needs jquery"  if jq is `undefined`
  force_obj = this
  width = container.width()
  height = container.height()
  #console.log("wh", width, height)
  fill = d3.scale.category20()

  mvars =
    selected_node: null
    selected_link: null
    mousedown_link: null
    mousedown_node: null
    mouseup_node: null
    node_target: null

  # container is jquery element
  container.empty()

  outer = d3.select(container[0])
    .attr("width", width + 5)
    .attr("height", height + 5)
    .append("svg:svg")
    .attr("width", width)
    .attr("height", height)
    .attr("pointer-events", "all")

  vis = outer.append("svg:g")
    .call(d3.behavior.zoom()
    .on("zoom", rescale))
    .on("dblclick.zoom", null)
    .append("svg:g")
    .on("mousemove", mousemove)
    .on("mousedown", mousedown)
    .on("mouseup", mouseup)

  vis
    .append("svg:rect")
    .attr("width", width)
    .attr("height", height)
    .attr "fill", "white"

  mvars.background = vis.node()

  force_layout = undefined
  graphstr = undefined
  if options.graph?
    graph = options.graph
  else
    try
      graphstr = window.localStorage["graph"]
    catch e
      console.log "localStorage not supported. can't save graph."
    if graphstr?
      graph = JSON.retrocycle(JSON.parse(graphstr))
    else
      graph =
        nodes: [{id: 1}]
        links: []
  force_layout =
    d3.layout.force()
    .size([width, height])
    .nodes(graph.nodes)
    .links(graph.links)
    .linkDistance(50)
    .charge(-200)
    .on("tick", tick)
  drag_line = vis.append("line").attr("class", "drag_line").attr("x1", 0).attr("y1", 0).attr("x2", 0).attr("y2", 0)
  dragTarget = undefined
  force_obj.nodes = force_layout.nodes()
  force_obj.links = force_layout.links()
  force_obj.graph =
    nodes: force_obj.nodes
    links: force_obj.links

  gstate = {}
  gstate.node = vis.selectAll(".node")
  gstate.link = vis.selectAll(".link")
  node_drag = d3.behavior.drag().on("dragstart", dragstart).on("drag", dragmove).on("dragend", dragend)
  force_obj.redraw_callbacks = []
  @markNodes = markNodes
  
  #/ INIT CODE
  
  # add keyboard callback
  d3.select(window).on "keydown", keydown
  redraw()
  
  # focus on svg
  # vis.node().focus();
  d3.select("#interaction_mode").on "change", (i) ->
    console.log "change"
    gstate.node.call getDragFunction()
    return

  # Public methods
  force_obj.addNode = () ->
    add_node()

  force_obj.addEdge = () ->
    add_edge()

  force_obj

class window.ForceView
  constructor: (container) ->
    @inner = force_view(container)
    @nodes = @inner.nodes

  addNode: () ->
    @inner.add_node([0, 0])
