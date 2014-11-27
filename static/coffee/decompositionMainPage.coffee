class window.DecompositionMainPage

  getDecompositionPath: () ->
    "/json/decomposition"

  getGraphPath: () ->
    "/json/graph"

  decompGraph: () ->
    vd = new VisualDecomposition()
    after = (graph) ->
      #vd.showDecomposition([$('window').width(),$('window').height()], graph)
      vd.createVisualGraph([1600, 1600], graph)
      $("#mainContent").empty()
      vd.showGraph($("#mainContent"))
    parseJSON = vd.makeParseJSON(after)
    $.get(@getDecompositionPath(), "", parseJSON)

  createGraph: (main, graph) ->
    vd = new VisualDecomposition()
    console.log("graph", graph)
    main.append(emhHTML.div(graph.name))
    vd.createVisualGraph([1600, 1600], graph)
    vd.showGraph(main)
    vd

  decompTree: () ->
    await $.get(@getDecompositionPath(), "", (defer decomposition))
    await $.get(@getGraphPath(), "", (defer graph))
    main = $("#mainContent")
    main.empty()
    json = JSON.parse(decomposition)
    nodeId = 0
    treeNodes = {}
    proc = (node, depth=0) ->
      cb = parseInt(node.cutBool) or ""
      if cb > 0
        cb = Math.log(cb) / Math.log(2.0)
        cb = Math.round(cb * 100) / 100
      newChildren = []
      for child in node.children
        newChildren.push(proc(child, depth + 1))
      ret =
        text: cb
        data: nodeId
        children: newChildren
      treeNodes[nodeId] = node
      nodeId += 1
      ret
    json = proc(json)

    container = emhHTML.div()
    main.append(container)
    container.css
      position: "absolute"
      left: "800px"
      top: "0px"
    jstree = container.jstree
      core:
        data:
          [json]

    graph = JSON.parse(graph)
    vd = @createGraph(main, graph)
    currentOrder = 0
    maxOrder = graph.order.reduce((a, b) -> Math.max(a, b)) + 1
    animateOrder = () ->
      currentOrder = (currentOrder + 1) % maxOrder
      nodes = []
      for order, i in graph.order
        if order <= currentOrder
          nodes.push(graph.nodes[i])
      vd.selectNodes(nodes)
    #setInterval animateOrder, 10

    jstree.on "select_node.jstree", (node, selected, event) ->
      console.log(node, selected, event)
      treeId = selected.node.data
      nodes = treeNodes[treeId].nodes
      vd.selectNodes(nodes)

  constructor: () ->
    @decompTree()
    mainPage = @
    $('a[href="#decompGraph"]').click (() -> mainPage.decompGraph())
    $('a[href="#decompTree"]').click (() -> mainPage.decompTree())
