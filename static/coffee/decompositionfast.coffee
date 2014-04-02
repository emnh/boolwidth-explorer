imBinOp = (fn, b1, b2) ->
  newb1 = new BitterSet()
  newb1.or(b1)  # set equal
  newb1[fn](b2) # perform op
  newb1

#ImBitterSet = {}
#jquery.extend(ImBitterSet,
BitterSet.prototype.imxor = (b2) -> imBinOp('xor', @, b2)
BitterSet.prototype.imor = (b2) -> imBinOp('or', @, b2)
BitterSet.prototype.imand = (b2) -> imBinOp('and', @, b2)
BitterSet.prototype.imset = (b2) -> imBinOp('set', @, b2)
BitterSet.prototype.imclear = (b2) -> imBinOp('clear', @, b2)
BitterSet.prototype.union = BitterSet.prototype.imor
BitterSet.prototype.intersect = BitterSet.prototype.imand
BitterSet.prototype.equals = (b2) -> @.imxor(b2).length() == 0
BitterSet.prototype.isSubset = (b2) -> @.imor(b2).equals(b2)
BitterSet.prototype.copy = (b2) -> (new BitterSet()).or(@)

class window.BitSampler

  constructor: (@state) ->
    @mat = @state.mat
    @hoods = []
    arrayToBitSet = (ar) ->
      b = new BitterSet()
      b.set(i) for x,i in ar when x == 1
      b
    @bitrows = (arrayToBitSet(row) for row in @mat)
    @bitcols = (arrayToBitSet(col) for col in @transpose(@mat))
    @colct = @mat.cols
    @rowct = @mat.rows
    #console.log(@bitsetToArray(@bitrows[0], @colct))
    #console.log(@bitsetToArray(@bitrows[1], @colct))
    #console.log(@bitsetToArray(@bitrows[0].equals(@bitrows[0]), @colct))
    #console.log(@bitrows[0].isSubset(@bitrows[1]))
    #console.log(@bitsetToArray(@bitrows[0], @colct))
    #console.log(@bitsetToArray(@bitrows[1], @colct))

  bitsetToArray: (set,length) ->
    (set.get(i) | 0 for i in [0..length-1])

  isPartialHood: (pat, mask) ->
    maskedrows = (row.imand(mask) for row in @bitrows)
    subsetrows = (row for row in maskedrows when row.isSubset(pat))
    #console.log("pat", pat.toString())
    #(console.log("s", x.toString()) for x in subsetrows)
    rowunion = subsetrows.reduce(((a, b) -> a.union(b)), new BitterSet())
    ret = pat.equals(rowunion) | 0
    #console.log(ret)
    ret

  transpose: (mat) ->
    rmat = ([] for x in mat[0])
    for row,i in mat
      for x,j in row
        rmat[j][i] = mat[i][j]
    rmat

  getSampleInner: (state) ->
    #console.log("sample", state.sample.toString())
    if state.sample_length < @colct
      # select nth question mark as new position
      getnext = (val) ->
        newsample =
          if val == 0
            state.sample.imclear(state.sample_length)
          else
            state.sample.imset(state.sample_length)
        #console.log("set/clr ", val, sample_length, sample.toString(), newsample.toString())
        newsample
      nextsamples = (getnext(val) for val in [0, 1])
      mask = state.mask.imset(state.sample_length)
      #(console.log("a", x.toString()) for x in nextsamples)
      isPartial = (@isPartialHood(nextsample, mask) for nextsample in nextsamples)
      #console.log("ispartial", isPartial)
      prob =
        switch (isPartial[0] + isPartial[1])
          when 0
            state.prob
          when 1
            nextval = if isPartial[1] > 0 then 1 else 0
            @getSampleInner
              sample: nextsamples[nextval]
              sample_length: state.sample_length + 1
              prob: state.prob
              mask: mask
          when 2
            #console.log("I haz a choice")
            rand = Math.floor(Math.random()*2)
            @getSampleInner
              sample: nextsamples[rand]
              sample_length: state.sample_length + 1
              prob: state.prob*0.5
              mask: mask
    else
      prob = state.prob
    return prob

  getSample: () ->
    @getSampleInner
      sample: new BitterSet()
      sample_length: 0
      prob: 1
      mask: new BitterSet()

  getEstimate: (samplect) ->
    samples = (1 / @getSample() for i in [1..samplect])
    ret =
      estimate: util.average(samples) # r.estimate for r in results)
      results: samples
      samples: samples
