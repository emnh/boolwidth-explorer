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
        .call(force.drag)
        
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

    force.on "tick", () ->
      link
        .attr("x1", (d) -> d.source.x)
        .attr("y1", (d) -> d.source.y)
        .attr("x2", (d) -> d.target.x)
        .attr("y2", (d) -> d.target.y)

      nodeg
        .attr("transform", (d) -> "translate(#{d.x}, #{d.y})")
        .attr("cx", (d) -> d.x)
        .attr("cy", (d) -> d.y)
    
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

