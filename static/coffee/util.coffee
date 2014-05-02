util = {}
window.util = util

# Use Jquery extend instead
util.mergedicts = (obj1, obj2) ->
  for attrname of obj2
    obj1[attrname] = obj2[attrname]

# Use Jquery extend instead
util.getmergedicts = (objs...) ->
  newdict = {}
  for obj in objs
    for attrname of obj
      newdict[attrname] = obj[attrname]
  return newdict
    
util.zip = () ->
  lengthArray = (arr.length for arr in arguments)
  length = Math.min(lengthArray...)
  for i in [0...length]
    arr[i] for arr in arguments

util.average = (samples) ->
  samples.reduce((x, y) -> x + y) / samples.length

util.log2average = (samples) ->
  log2 = Math.log(2)
  samples = (Math.log(x) / log2 for x in samples)
  a = samples.reduce((x, y) -> x + y) / samples.length
  Math.pow(2, a)

util.sum = (samples) ->
  samples.reduce((x, y) -> x + y)

util.max = (ar) ->
  ar.reduce((a, b) -> Math.max(a, b))

util.min = (ar) ->
  ar.reduce((a, b) -> Math.min(a, b))
