$ = jQuery
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
    $(".pane div").hide()
    $($(this).attr("href")).show()
    return

  $("ul.tabs a")[0].click()

  graphvis = new force_view("#graphvis")
  updateGraphText graphvis.graph

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

