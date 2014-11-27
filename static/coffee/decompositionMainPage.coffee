class window.DecompositionMainPage
  @decompositionPath = "/json/decomposition"

  decompGraph: () ->
    vd = new VisualDecomposition()
    after = (graph) ->
      #vd.showDecomposition([$('window').width(),$('window').height()], graph)
      vd.createDecomposition([1600, 1600], graph)
      $("#mainContent").empty()
      vd.showDecomposition($("#mainContent"))
    parseJSON = vd.makeParseJSON(after)
    $.get(@decompositionPath, "", parseJSON)

  decompTree: () ->
    await $.get(@decompositionPath, "", (defer data))
    json = json.Parse(data)
    console.log(json)

  constructor: () ->
    @decompGraph()
    $("#decompGraph").click (() -> @decompGraph())
    $("#decompTree").click (() -> @decompTree())
