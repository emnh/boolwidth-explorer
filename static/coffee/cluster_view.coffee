window.cluster_view = (containerid, packobj) ->
  width = $(containerid).width()
  height = $(containerid).height()
  cluster = d3.layout.cluster().size([
    height
    width - 160
  ])
  diagonal = d3.svg.diagonal().projection((d) ->
    [
      d.y
      d.x
    ]
  )
  svg = d3.select(containerid).append("svg").attr("width", width).attr("height", height).append("g").attr("transform", "translate(40,0)")
  nodes = cluster.nodes(packobj.state.root)
  links = cluster.links(nodes)
  link = svg.selectAll(".link").data(links).enter().append("path").attr("class", "link").attr("d", diagonal)
  node = svg.selectAll(".node").data(nodes).enter().append("g").attr("class", "node").attr("transform", (d) ->
    "translate(" + d.y + "," + d.x + ")"
  )
  node.append("circle").attr "r", 4.5
  
  #.attr("transform", "rotate(-90)")
  node.append("text").attr("dx", (d) ->
    (if d.children then -8 else 8)
  ).attr("dy", 3).style("text-anchor", (d) ->
    (if d.children then "end" else "start")
  ).text (d) ->
    d.name

  d3.select(self.frameElement).style "height", height + "px"
  this
