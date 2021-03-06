window.getFileNameSelector = (fsid) ->
  H = emhHTML
  fnamelist = "/graphfiles.txt"
  fnameselect = H.select("", { id: fsid })
  fnamelabel = H.label("Graph", { 'for': fnameselect })
  fnamediv = H.div([fnamelabel, fnameselect])
  
  showfnames = (data) ->
    H.option("Generate", { value: "generate" }).appendTo(fnameselect)
    testgraph = "graphdata/graphLib_ours/cycle/c5.dimacs"
    H.option(testgraph, { value: testgraph }).appendTo(fnameselect)
    lines = data.split('\n')
    bname = (fname) ->
      fname.split('/')[-1]
    options = (H.option(line, { value: line }) for line in lines when line != '')
    $(option).appendTo(fnameselect) for option in options
  
  $.ajax
    url: fnamelist
    data: ""
    success: showfnames
    dataType: "text"

  fnamediv
