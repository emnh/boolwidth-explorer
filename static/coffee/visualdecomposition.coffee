class window.VisualDecomposition

  showGraph: (parent) ->
    parent.append(@container)
    @parent = parent
    # events must be attached after adding to DOM
    @addHandlers()
    @zoomOn()

  addHandlers: () ->
    t = @
    @toggleZoom.click () ->
      if t.zoom
        t.toggleZoom.prop('value', "Zoom On")
        t.zoomOff()
      else
        t.toggleZoom.prop('value', "Zoom Off")
        t.zoomOn()

  dragBehavior: (force, tick) ->
    dragstart = (d, i) ->
      force.stop() # stops the force auto positioning before you start dragging
    dragmove = (d, i) ->
      d.px += d3.event.dx
      d.py += d3.event.dy
      d.x += d3.event.dx
      d.y += d3.event.dy
      tick() # this is the key to make it work together with updating both px,py,x,y on d !
    dragend = (d, i) ->
      d.fixed = true # of course set the node to fixed so the force doesn't include the node in its auto positioning stuff
      tick()
      force.resume()
    node_drag = d3.behavior.drag().on("dragstart", dragstart).on("drag", dragmove).on("dragend", dragend)
    return node_drag

  zoomOff: () ->
    @svg.on "mousedown.zoom", null
    @svg.on "mousemove.zoom", null
    @svg.on "dblclick.zoom", null
    @svg.on "touchstart.zoom", null
    @svg.on "wheel.zoom", null
    @svg.on "mousewheel.zoom", null
    @svg.on "MozMousePixelScroll.zoom", null
    @zoom = false
    #@svg.remove()
    #@container.add(@svg)
    #@addHandlers()

  zoomOn: () ->
    svgGroup = @svgGroup
    rescale = () ->
      #console.log("rescale", d3.event.scale, d3.event.translate)
      trans = d3.event.translate
      scale = d3.event.scale
      svgGroup.attr "transform", "translate(" + trans + ")" + " scale(" + scale + ")"
    zoomListener = d3.behavior.zoom().on("zoom", rescale)
    zoomListener(@svg)
    @zoom = true

  selectNodes: (nodes) ->
    selector = (d) ->
      if (d in nodes)
        "red"
      else
        "lightblue"
    allNodes =
      @svg
        .selectAll(".node circle")
        .data(@graph.nodes)
        .attr "fill", selector
    #console.log(allNodes)

  getNodesByX: () ->
    nodes = []
    for node,i in @svgGroup.selectAll(".node")[0]
      node = $(node)
      nodes.push
        jqNode: node
        nodeData: @nodes[i]
      #console.log('node', node.attr('cx'))
    nodes.sort((a, b) -> parseFloat(a.jqNode.attr('cx')) - parseFloat(b.jqNode.attr('cx')))
    nodeIndices = (x.nodeData.index for x in nodes)
    nodeNames = (parseInt(x.nodeData.name) for x in nodes)
    #for node in nodes
    #  console.log('snode', node.nodeData.id, node.jqNode.attr('cx'))
    [nodeIndices, nodeNames]

  removeLongestLink: () ->
    links = []
    for link,i in @svgGroup.selectAll(".link")[0]
      x1 = link.x1.baseVal.value
      y1 = link.y1.baseVal.value
      x2 = link.x2.baseVal.value
      y2 = link.y2.baseVal.value
      dx = x2 - x1
      dy = y2 - y1
      length = Math.sqrt(dx*dx + dy*dy)
      links.push
        index: i
        link: link
        length: length
      #console.log(x1, x2, y1, y2, length)
    links.sort((a, b) -> a.length - b.length)
    toRemove = links[links.length - 1]
    #console.log('index', toRemove.index)

    @force.stop()
    links = @force.links()
    newLinks = []
    for link,i in links
      if i != toRemove.index
        newLinks.push(link)
    @force.links(newLinks)
    #[toRemove.index].source = @force.links()[toRemove.index].target
    @force.resume()
    $(toRemove.link).remove()
    

  createVisualGraph: (size, graph) ->
    
    @graph = graph

    [width, height] = size
    color = d3.scale.category20()
    
    force =
      d3
        .layout.force()
        .charge(-120)
        .linkDistance(30)
        .size([width, height])
    @force = force
    container = emhHTML.div("") # { style: "visibility: hidden;" })
    @container = container
    
    toggleZoom = emhHTML.input '',
      type: "button"
      value: "Zoom Off"
    @toggleZoom = toggleZoom

    @container.append(toggleZoom)

    svg =
      d3.selectAll(container.toArray())
        .append("svg")
        .attr("width", () -> width)
        .attr("height", () -> height)
        .attr("id", _.uniqueId("d3svg"))
    @svg = svg

    svgGroup = svg.append("g")
    @svgGroup = svgGroup
    
    if not graph.labels?
      graph.labels = graph.nodes

    newNode = (d) ->
      node =
        index: d
        name: graph.labels[d]
      return node
    newlink = (d, nodes) ->
      link =
        source: nodes[d[0]]
        target: nodes[d[1]]
      return link
    nodes = (newNode(d) for d in graph.nodes)
    @nodes = nodes
    links = (newlink(d, nodes) for d in graph.edges)
    
    force
      .nodes(nodes)
      .links(links)
      .start()
    
    nodes = force.nodes()
    links = force.links()
      
    link =
      svgGroup
      .selectAll(".link")
      .data(links)
      .enter()
      .append("line")
      .attr("class", "link")
      .style("stroke-width", () -> 1.0)
      .style("stroke", "black")
    
    nodeg =
      svgGroup
        .selectAll(".node")
        .data(nodes)
        .enter()
        .append("g")
        .attr("class", "node")
        #.call(force.drag)
        
    radius = 10

    nodeg
      .append("circle")
      .attr("fill", color(0))
      .attr("r", radius)
    nodeg
      .append("text")
      .text((d) -> d.name)
      .attr("x", 0)
      .attr("y", radius / 2.0)
      #.attr("fill", "black")
      .attr("stroke", "black")
      .attr("text-anchor", "middle")

    tick = () ->
      link
        .attr("x1", (d) -> d.source.x)
        .attr("y1", (d) -> d.source.y)
        .attr("x2", (d) -> d.target.x)
        .attr("y2", (d) -> d.target.y)
      nodeg
        .attr("transform", (d) -> "translate(#{d.x}, #{d.y})")
        .attr("cx", (d) -> d.x)
        .attr("cy", (d) -> d.y)
    
    force.on "tick", tick
        
    nodeg.call(@dragBehavior(force, tick))

    jqsvg = $("#" + svg.attr("id"))
    return jqsvg

  makeParseJSON: (callback) ->
    f = (data) ->
      json = JSON.parse(data)
      graph =
        nodes: []
        labels: []
        edges: []

      maxid = 0
      proc = (node, depth=0) ->
        thatid = maxid
        graph.nodes.push(thatid)
        cblog = Math.log(node.cutBool) / Math.log(2.0)
        cblog = Math.round(cblog * 100) / 100
        label = cblog + ":" + depth
        graph.labels.push(label)
        maxid += 1
        for child in node.children
          otherid = proc(child, depth + 1)
          graph.edges.push([thatid, otherid])
        return thatid
      proc(json)

      #console.log(graph)

      callback(graph)
    return f
      #showDecomposition([1600, 800], graph)

