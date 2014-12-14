
zeropad = (s, l, zero='0') ->
  while s.length < l
    s = zero + s
  return s

traverse = (tree, visitors) ->
  return unless tree
  {pre, in: in_, post} = visitors
  pre tree if pre
  traverse tree.left, visitors
  in_ tree if in_
  traverse tree.right, visitors
  post tree if post

blockeq = (a, b) -> (zip a, b).every ([a, b]) -> a == b

makeEncoder = (tree) -> (block) ->
  stack = []
  found = {}
  try
    traverse tree,
      pre: (n) ->
        throw found if n.block and blockeq n.block, block
        stack.push '0'
      in: ->
        stack.pop()
        stack.push '1'
      post: ->
        stack.pop()
  catch e
    if e is found
      return stack
    else
      throw e
  throw new Error "Couldn't find block #{block} in the tree"

makeDecoder = (tree) -> (msg) ->
  node = tree
  for s in msg
    switch s
      when '0' then node = node.left
      when '1' then node = node.right
  return node.block

makeCodec = (tree) -> [(makeEncoder tree), (makeDecoder tree)]

randstr = (length, base=2) ->
  Math.random().toString(base).slice(2, 2 + length)

entropy = (ps) -> - sum map ((p) -> p * log2 p), ps
entropy_max = (ps) -> log2 ps.length

ent_ratio = (ps) -> entropy(ps)/entropy_max(ps)
redundancy = (ps) -> 1 - ent_ratio ps

$ ->
  p =
    0: .3
    1: .7
  k = 1000
  m = 3

  config.define
    title: 'p<sub>0</sub>'
    default: p[0]
    valid: (v) -> v > 0 and v < 1
    change: (v) ->
      p[0] = v
      p[1] = 1 - v
    $:
      min: 0.01
      max: 0.99

  config.define
    title: 'Длина последовательности'
    default: k
    valid: (v) -> v > 1
    change: (v) -> k = v

  config.define
    title: 'Длина блока'
    default: m
    valid: (v) -> v > 0
    change: (v) -> m = v

  for selector in ['#sequence', '#code', '#decoded']
    $(selector).spinner spin: -> no
    $(selector).css 'margin-right', '.4em'
    $(selector).parent().children('.ui-spinner-button').remove()

  $('#apply-config').button().click ->
    symcount = Object.keys(p).length

    numToBlock = (n) -> (zeropad n.toString(symcount), m).split('')
    blocks = map numToBlock, range symcount**m
    blocks_probs = zip blocks, map_ blocks, (b) -> product map_ b, (s) -> p[s]

    nodes = map_ blocks_probs, ([b, p]) -> { block: b, probability: p }

    getprob = (n) -> n.probability
    while len(nodes) > 1
      nodes.sort upon compare, getprob
      [left, right] = loosers = nodes.slice 0, 2
      nodes.splice 0, 2, {left, right, probability: sum map_ loosers, getprob}
    tree = nodes[0]

    [encode, decode] = makeCodec tree

    sequences = ncalls_ k, -> randstr(m).split('')
    codes = map encode, sequences
    decoded = map decode, codes

    $('#sequence').val sequences.map((s) -> s.join('')).join(',')
    $('#code').val codes.map((s) -> s.join('')).join(',')
    $('#decoded').val decoded.map((s) -> s.join('')).join(',')

    $('#avg-length-est').text sprintf '%.3f', (sum map len, codes)/k
    $('#avg-length').text sprintf '%.3f', sum map_ blocks_probs, ([b, p]) -> (len encode b)*p
    relent = (ps) -> (entropy ps) / (entropy_max ps)
    $('#relative-entropy').text sprintf '%.3f', relent_val = relent map_ blocks_probs, ([_, p]) -> p
    $('#redundancy').text sprintf '%.3f', 1 - relent_val

    graph = cytoscape
      container: $('#tree')[0]
      style: cytoscape.stylesheet()
        .selector('node')
          .css({
            'content': 'data(label)'
          })
        .selector('node[block > 0]')
          .css({
            'background-color': 'OrangeRed ',
          })
        .selector('edge')
          .css({
            'content': 'data(label)'
            'target-arrow-shape': 'triangle',
            'width': 4,
            'line-color': '#bbb',
            'target-arrow-color': '#bbb'
          })
        .selector('.highlighted')
          .css({
            'background-color': '#61bffc',
            'line-color': '#61bffc',
            'target-arrow-color': '#61bffc',
            'transition-property': 'background-color, line-color, target-arrow-color',
            'transition-duration': '0.5s'
          })
      layout:
        name: 'breadthfirst',
        directed: true,
        padding: 10
    traverse tree,
      pre: (node) ->
        node._id = 'id' + Math.random().toString()
        if node.block
          label = "#{node.block.join ''} / #{sprintf '%.3f', node.probability}"
          block = yes
        else
          label = sprintf '%.3f', node.probability
          block = no
        graph.add
          group: "nodes"
          data: { id: node._id, label: label, block: block }
    traverse tree,
      pre: (node) ->
        return if node.block
        graph.add
          group: 'edges'
          data: {source: node._id, target: node.left._id, label: '0'}
        graph.add
          group: 'edges'
          data: {source: node._id, target: node.right._id, label: '1'}



  $('#apply-config').click()


