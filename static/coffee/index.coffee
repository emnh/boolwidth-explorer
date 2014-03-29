$ = jQuery
H = emhHTML

$(document).ready ->
  
  # tabs
  updateGraphText = (graph) ->
    fg = formatGraph(graph)
    $("#graphtext textarea").val fg
    return
  updateTreeText = (graph) ->
    fg = formatTree(graph)
    $("#treetext textarea").val fg
    return
  $("ul.tabs a").click ->
    $(".pane > div").hide()
    $($(this).attr("href")).show()
    return

  $("ul.tabs a")[0].click()

  graphpane = $('#graphpane')
  graphdiv = $('#graphvis')
  gselect = getFileNameSelector('graphselect')
  graphpane.prepend(gselect)

  graphvis =
    new force_view
      container: graphdiv
  updateGraphText graphvis.graph
  
  selectgraph = (evt) ->
    f = (data) ->
      g = new Graph()
      g.parseDimacs(data)
      #console.log(g.nodes, g.edges)
      #console.log(graphvis.nodes, graphvis.edges)
      mapNode = (node, idx) ->
        id: idx
        node: node
      nodes = (mapNode(node, idx) for idx,node of g.noderev)
      #(console.log(e[0], e[1]) for e in g.edges)
      mapEdge = (e) ->
        link =
          source: g.noderev[e[0]]
          target: g.noderev[e[1]]
      links = (mapEdge(e) for e in g.edges)
      console.log("nodes", nodes)
      console.log("links", links)
      graphvis =
        new force_view
          container: $('#graphvis')
          graph:
            nodes: nodes
            links: links
    fname = evt.target.value
    $.get(fname, "", f)
  gselect.change selectgraph

  #graphvis.nodes.addNode()

  packvis = new pack_view("#treevis", graphvis)
  updateTreeText packvis.state.root

  graphvis.redraw_callbacks.push ->
    packvis.redraw_pack()
    return

  graphvis.redraw_callbacks.push ->
    updateGraphText graphvis.graph
    return

  packvis.markNodes = graphvis.markNodes
  clusterobj = new cluster_view("#clustervis", packvis)
  return

