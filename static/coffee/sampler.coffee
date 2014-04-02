INNER_SAMPLE_COUNT = 100

class window.SearchTree
  constructor: (state) ->
    if state
      @debug = state.debug
    else
      @debug = false
    @root = null # root of tree

  addChild: (argstate, parent=null) ->
    if @debug
      console.log("st branch", argstate)
    # used for breadth first search
    node =
      state: argstate
      children: []
    if parent == null
      @root = node
    else
      parent.children.push(node)
    node

  addLeaf: (argstate, parent) ->
    if @debug
      console.log("st solution", argstate)
    if parent == undefined # safety hatch
      throw "parent must not be null for leaves"
    #@pushThenBranch(argstate)
    node = @addChild(argstate, parent)
    node.leaf = true
    delete node.children

  getSolutions: () ->
    solutions = []
    proc = (tree) ->
      if tree.children? and tree.children.length > 0
        proc(c) for c in tree.children
        if tree.leaf
          throw "node should not be both leaf and parent"
      else if tree.leaf? and tree.leaf == true
        solutions.push(tree.state)
    proc @root
    solutions

class window.Sampler

  # TODO: estimate: let the selection order be free
  # TODO: estimate idea, train neural network with count based on vertex degrees

  constructor: (@state) ->
    @mat = @state.mat
    @hoods = []

  isSubset: (pat) ->
    (row for row in @mat when pat.every((e, i) -> e == '?' or row[i] <= e))
  
  isSubsetSum: (rows, pat) ->
    atLeastOneOneInRows = (e, i) ->
      if e == 1
        rows.some((row) -> row[i] == 1)
      else
        true
    pat.every(atLeastOneOneInRows)

  isPartialHood: (pat) ->
    rows = @isSubset(pat)
    @isSubsetSum(rows, pat)

  getRoughEstimate: (exact) ->
    deg = BiGraph.getDegrees(@mat)

    a = (x for x in deg when x > 0)
    a.sort((a,b) -> b - a)
    b = (x for x in deg when x > 0)
    b.sort((a,b) -> a - b)

    f = (x, y) -> (1 + 1/y)*x
    rest = a.reduce(f, 1)
    rest2 = b.reduce(f, 1)

    # Random Graph Estimate
    mul = 6
    p = 0
    for row in @mat
      for x in row when x == 1
        p++
    #console.log("Probability", p, (@mat.cols * @mat.rows), p / (@mat.cols * @mat.rows))
    p /= (@mat.cols * @mat.rows)
    rndest = Math.round(mul*Math.log(@mat.rows)*Math.log(@mat.cols)/p)

    result =
      deg0: a
      deg1: b
      acc: (estimate) -> Math.round(estimate / exact * 100) / 100
      rest: Math.round(rest)
      rest2: Math.round(rest2)
      avgest: (rest + rest2) / 2
      rndest: Math.round(rndest)
      p: p
    result

  spliterate: () ->
    # X = left
    # Z = im(X)
    # X = A U B
    # |A U B| = |A| + |B| - |A ^ B| = |A - A^B| + |B - A ^ B| + |A ^ B|
    # Z = im(A) U im(B)
    # F = im(A) ^ im(B)
    # |Z| = |im(A U B)| = |im(A)| * |im(B)| / |im(A ^ B)|
    # |Z| = |im(A U B)| = |im(A - A ^ B)| * |im(B - A ^ B)| * |im(A ^ B)|
    mat = @mat
    graph = new BiGraph()
    graph.from_mat(mat)

    mid = mat.rows / 2
    A = mat.slice(0, mid)
    B = mat.slice(mid)
    union = (r1, r2) ->
      (r1[i] | r2[i] for x, i in r1)
    intersect = (r1, r2) ->
      (r1[i] & r2[i] for x, i in r1)

    Ac = @count(A)
    Bc = @count(B)
    imA = A.reduce(union)
    imB = B.reduce(union)
    F = intersect(imA, imB)

    rmat = ([] for x in mat[0])
    for row,i in mat
      for x,j in row
        rmat[j][i] = mat[i][j]

    imF = (rmat[i] for x,i in F when x == 1)
    imFidx = (i for x,i in F when x == 1)

    imAnoB = ([i, rmat[i]] for x,i in F when i < mid and x != 1)
    imBnoA = ([i, rmat[i]] for x,i in F when i >= mid and x != 1)
    # TODO: check for empty before calling iterate
    imAnoBhoods = @iterate((x[1] for x in imAnoB))
    imBnoAhoods = @iterate((x[1] for x in imBnoA))
    imAnoBc = imAnoBhoods.count
    imBnoAc = imBnoAhoods.count

    hjoin = {}
    samplect = 10 # O(n^2)
    hoods1 = (h1 for {sample: h1} in imAnoBhoods.tree.getSolutions())
    hoods2 = (h2 for {sample: h2} in imBnoAhoods.tree.getSolutions())
    selectrandom = (ar) ->
      num = Math.floor(Math.random() * ar.length)
      ar[num]
    hoods1sampleidx  = (selectrandom(hoods1) for i in [1..samplect])
    hoods2sampleidx  = (selectrandom(hoods2) for i in [1..samplect])
    for h1 in hoods1sampleidx
      for h2 in hoods2sampleidx
        do (h1, h2) ->
          nhood = union(h1, h2)
          hjoin[nhood] = 1
    ratio = Object.keys(hjoin).length / (samplect * samplect)
    
    colorRow = (indices, color) ->
      for i in indices
        row = $(".bigraph_table tr:eq(#{i+1})")
        row.css("background", color)
    colorCol = (indices, color) ->
      for i in indices
        row = $(".bigraph_table td:nth-child(#{i+2})")
        row.css("background", color)

    #colorLine(F, 'tr', 'cyan')
    colorCol(imFidx, 'magenta')
    colorCol((i for [i, row] in imAnoB), 'cyan')
    colorCol((i for [i, row] in imBnoA), 'pink')

    imFc = @count(imF)
    table = $('bigraph_table')
    console.log("A", A, imA, Ac)
    console.log("B", B, imB, Bc)
    console.log("AnoB", imAnoB, imAnoBc)
    console.log("BnoA", imBnoA, imBnoAc)
    console.log("F", F, imFc)
    console.log("imF", imF, imFc)
    console.log("upper", Ac * Bc, Ac * Bc / imFc)
    console.log("lower", imAnoBc * imBnoAc, imAnoBc * imBnoAc * imFc)
    console.log("avg", Math.pow(Math.E, (Math.log(Ac * Bc) + Math.log(imAnoBc * imBnoAc)) / 2))
    console.log("length check", mat.cols, imAnoB.length + imBnoA.length + imF.length)
    console.log("hjoin", Object.keys(hjoin).length, ratio, Ac * Bc * ratio)
    state = {}
    state.A = A
    state.B = B

    #groups = []
    #group = []
    #overlap = (group, pat) ->
    #  (row for row in group when pat.every((e, i) -> e == '?' or row[i] < e))
    #for row,i in mat
    #  if not(overlap(group,row))
    #    group.push(row)
    #  else
    #    groups.push(group)
    #    group = []

  @count: (mat) ->
    if mat.length > 0
      s = new Sampler
            mat: mat
      s.iterate().count
    else
      1

  iterate: () ->
    st = new SearchTree()
    solct =  0
    @itersub = (state) ->
      parent = st.addChild(state, state.tree)
      if state.sample.length >= @mat[0].length
        solct++
        st.addLeaf({ sample: state.sample }, parent)
      else
        zeroct = @isPartialHood(state.sample.concat([0]))
        onect = @isPartialHood(state.sample.concat([1]))
        switch (onect + zeroct)
          when 0
            solct++
            st.addLeaf({ sample: state.sample }, parent)
          when 1
            nextval = if onect > 0 then 1 else 0
            @itersub
              sample: state.sample.concat([nextval])
              tree: parent
          when 2
            @itersub
              sample: state.sample.concat([0])
              tree: parent
            @itersub
              sample: state.sample.concat([1])
              tree: parent
    
    #cc = @connectedComponents(@mat)
    state =
      sample: []
      tree: null
    st.addChild state
    @itersub state
    result =
      count: solct
      tree: st

  getQPosSample: (sample, prob) ->
    qpos = (i for x,i in sample when x == '?')
    qcount = qpos.length
    if qcount == 0 # @mat[0].length
      return prob
    else
      # select nth question mark as new position
      newposrand = Math.floor(Math.random() * qcount)
      newposition = qpos[newposrand]
      getnext = (val) ->
        newsample = ((if i == newposition   then val else x) for x,i in sample)
        newsample
      vals =
        for val in [0, 1]
          ispartial = @isPartialHood(getnext(val))
          ispartial
      prob = switch (vals[0] + vals[1])
        when 0
          prob
        when 1
          nextval = if vals[1] > 0 then 1 else 0
          prob = @getQPosSample(getnext(nextval), prob)
        when 2
          rand = Math.floor(Math.random()*2)
          prob = @getQPosSample(getnext(rand), prob*0.5)
      return prob

  getSamplesBranch: (args) ->
    state = args.state
    switch (args.childcount)
      when 0
        # shouldn't happen, because sample length would exceed row length in earlier check
        loopvars.done = args.solution(state)
      when 1
        nextval = if args.onect > 0 then 1 else 0
        args.branch
          sample: state.sample.concat([nextval])
          prob: state.prob
          estimate: state.estimate
          depth: state.depth + 1
          parentNode: state.node
      when 2
        rand = Math.floor(Math.random()*2)
        newprob = state.prob * 0.5
        if state.depth < args.loopvars.maxdepth
          estimate = state.estimate
        else
          estimate = state.estimate * 2 # assumes same type
        args.branch
          sample: state.sample.concat([rand])
          prob: newprob
          estimate: estimate
          depth: state.depth + 1
          parentNode: state.node
        if state.depth < args.loopvars.maxdepth
          opposite = rand ^ 1
          args.branch
            sample: state.sample.concat([opposite])
            prob: newprob
            estimate: estimate
            depth: state.depth + 1
            parentNode: state.node
          args.loopvars.branchct++


  getSamples: (in_sample, in_prob) ->
    if @state.inner_samplect?
      samplect = @state.inner_samplect
    else
      throw "missing inner samplect"
    stack = []
    samples = []
    branchPoints = []
    st = new SearchTree()
    branch = (argstate) ->
      argstate.node = st.addChild(argstate, argstate.parentNode)
      stack.push(argstate)
    solution = (argstate) ->
      st.addLeaf(argstate, argstate.parentNode)
      samples.push
        sample: argstate.sample
        estimate: argstate.estimate
      samplect--
      return samplect <= 0

    branch
      sample: in_sample
      prob: in_prob
      estimate: 1
      depth: 0
      parentNode: null
    loopvars =
      done: false
      ct: 0
      branchct: 0
      maxdepth: Math.ceil(Math.log(samplect) / Math.log(2))
    while stack.length > 0 and not loopvars.done
      state = stack.pop()
      loopvars.ct++
      zeroct = @isPartialHood(state.sample.concat([0]))
      onect = @isPartialHood(state.sample.concat([1]))
      if state.sample.length >= @mat[0].length
        loopvars.done = solution(state)
      else
        @getSamplesBranch
          state: state
          branch: branch
          childcount: zeroct + onect
          onect: onect
          solution: solution
          loopvars: loopvars
    ret =
      searchtree: st
      samples: samples
      estimate: util.sum(x.estimate for x in samples)

  getAbstractEstimate: (samplect, getSampleM) ->
    samples = (getSampleM() for i in [1..samplect])
    util.average(samples)

  getEstimate: (samplect) ->
    results = (@getSamples([], 1) for i in [1..samplect])
    ret =
      estimate: util.average(r.estimate for r in results)
      results: results
      samples: r.estimate for r in results
  
  getQPosEstimate: (samplect) ->
    initsample = ('?' for x in [1..@mat[0].length])
    samples = (1 / @getQPosSample(initsample, 1) for i in [1..samplect])
    ret =
      estimate: util.average(samples) # r.estimate for r in results)
      results: samples
      samples: samples


