# GET home page. 
exports.index = (req, res) ->
  res.render "index",
    title: "Express3"
  return
