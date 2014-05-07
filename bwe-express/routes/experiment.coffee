# GET home page. 
exports.experiment = (req, res) ->
  res.render "experiment",
    title: "ACE Experiment"
  return
