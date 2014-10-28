class window.VisualGraph

  drawGraph: (graph, chart, table) ->
    leftnodes =
      for name,i in graph.leftids
        node =
          col: 0
          name: name
          colindex: i
          graphnode: graph.nodes[name]
    rightnodes =
      for name,i in graph.rightids
        node =
          col: 1
          name: name
          colindex: i
          graphnode: graph.nodes[name]
    nodes = leftnodes.concat(rightnodes)
    #nodes = graph.leftids.concat(graph.rightids)
    nodesByName = {}
    (nodesByName[node.name] = node for node in nodes)
    edgeByIdx = []

    makeEdge = (x, y) ->
      edge =
        left: nodesByName[x]
        right: nodesByName[y]
        hover: false
      if not(edgeByIdx[edge.left.colindex])
        edgeByIdx[edge.left.colindex] = []
      edgeByIdx[edge.left.colindex][edge.right.colindex] = edge
      if not(edgeByIdx[edge.right.colindex])
        edgeByIdx[edge.right.colindex] = []
      edgeByIdx[edge.right.colindex][edge.left.colindex] = edge
      edge
    edgeNodes = (makeEdge(x, y) for [x, y] in graph.edges)

    components = graph.connectedComponents()

    xpos = (d, i) ->
      10 + d.col * 300
    ypos = (d, i) ->
      30 + d.colindex * 40

    color = d3.scale.category20()
    
    # Mark node in matrix and graph visuals
    mark = (i, j, color, edge) ->
      row = $(".bigraph_table tr:eq(#{i+1})")
      row.css("background", color)
      col = $(".bigraph_table tr td:nth-child(#{j+2})")
      col.css("background", color)
      if edge != undefined
        d3.select('g circle').attr("r", 10)
        #lines.attr("r", 10)

    group = chart
      .selectAll(".circle")
      .data(nodes)
      .enter()
      .append('g')
      .attr("transform", (d) -> "translate(#{xpos(d)}, #{ypos(d)})")

    me = (d, i) ->
      switch d.col
        when 0
          row = $(".bigraph_table tr:eq(#{d.colindex+1})")
          row.css("background", color(d.graphnode.marked))
        when 1
          col = $(".bigraph_table tr td:nth-child(#{d.colindex+2})")
          col.css("background", color(d.graphnode.marked))
          #edges = edgeByIdx[i][d.colindex]
      lines
        .filter((edge, i) -> (edge.left == d) or (edge.right == d))
        .style("stroke-width", 3)
        .style("stroke", "red")

    ml = (d, i) ->
      switch d.col
        when 0
          row = $(".bigraph_table tr:eq(#{d.colindex+1})")
          row.css("background", "")
          #for e in d.edgeByIdx[d.colindex]
        when 1
          col = $(".bigraph_table tr td:nth-child(#{d.colindex+2})")
          col.css("background", "")
      lines
        .filter((edge, i) -> (edge.left == d) or (edge.right == d))
        .style("stroke-width", 1)
        .style("stroke", "black")

    circles = group
      .append('circle')
      .attr("r", 8)
      .attr("fill", (d, i) -> color(d.graphnode.marked))
      .on("mouseenter", me)
      .on("mouseleave", ml)

    text = group
      .append('text')
      .attr('dx', 0)
      .attr('dy', -15)
      .attr("font-family", "sans-serif")
      .attr("font-size", "20px")
      .attr("fill", "black")
      .text((d, i) -> d.colindex + 1)

    lines = chart.selectAll(".line")
      .data(edgeNodes)
      .enter()
      .append("line")
      .attr("x1", (d, i) -> xpos(d.left, i) + 10)
      .attr("y1", (d, i) -> ypos(d.left, i))
      .attr("x2", (d, i) -> xpos(d.right, i) - 10)
      .attr("y2", (d, i) -> ypos(d.right, i))
      .style("stroke-width", 1)
      .style("stroke", "black")
 
    cells = table.find('td')
    mfo = (e) ->
      elem = e.target
      [i, j] = $(elem).data('index')
      edge = edgeByIdx[i][j]
      mark(i, j, "red")
    mfl = (e) ->
      elem = e.target
      [i, j] = $(elem).data('index')
      edge = edgeByIdx[i][j]
      mark(i, j, "")
    cells.on("mouseover", mfo)
    cells.on("mouseleave", mfl)
