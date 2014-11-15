class window.VisualDecomposition

  showDecomposition: (size, graph) ->
    
    [width, height] = size
    color = d3.scale.category20()
    
    force =
      d3
        .layout.force()
        .charge(-120)
        .linkDistance(30)
        .size([width, height])
    tmpdiv = emhHTML.div("") # { style: "visibility: hidden;" })
    tmpdiv.prependTo('body')
    svg = 
      d3.selectAll(tmpdiv.toArray())
        .append("svg")
        .attr("width", () -> width)
        .attr("height", () -> height)    
        .attr("id", _.uniqueId("d3svg"))

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
      svg
      .selectAll(".link")
      .data(links)
      .enter()
      .append("line")
      .attr("class", "link")
      .style("stroke-width", () -> 1.0)
      .style("stroke", "black")
    
    nodeg = 
      svg
        .selectAll(".node")
        .data(nodes)
        .enter()
        .append("g")
        .attr("class", "node")
        .call(force.drag)
        
    radius = 1

    nodeg
      .append("circle")
      .attr("fill", color(0))
      .attr("r", radius)
    nodeg
      .append("text")
      .text((d) -> d.name)
      .attr("x", 0)
      .attr("y", radius / 2.0)
      .attr("fill", "black")
      .attr("stroke", "red")
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

      console.log(graph)

      callback(graph)
    return f
      #showDecomposition([1600, 800], graph)

