
assert = (bool, msg='no message supplied') ->
  throw new Error "Assertion Error: #{msg}" if not bool

# meta
flip2 = (f) -> (a, b, rest...) -> f.call this, b, a, rest...

memo1 = (f) ->
  cache = Object.create null
  return (a) ->
    return cache[a] if a of cache
    v = f.call @, arguments...
    cache[a] = v
    return v

upon = (binop, g) -> (a, b) -> binop (g a), (g b)

compose = (f, g) -> (args...) -> f g args...

partial1 = (f, a) -> (rest...) -> f a, rest...

# math
exp = (x) -> Math.exp x

log = (x, base=no) -> if base then Math.log(x)/Math.log(base) else Math.log(x)
log2 = (x) -> log x, 2

factorial = memo1 (n) ->
  if n < 2
    return 1
  return n * factorial n - 1

binomial = (n, k) -> factorial(n)/(factorial(n - k)*factorial(k))

op =
  not: (a) -> !a
  intnot: (a) -> 0 + !a

  eq:  (a, b) -> a == b
  add: (a, b) -> a + b
  mul: (a, b) -> a * b
  and: (a, b) -> a and b
  or:  (a, b) -> a or b
  xor: (a, b) -> a ^ b

binaryField = new class
  bit = (i, n) -> (n & (1 << i)) >> i

  degree: (p) -> if p == 0 then -1 else Math.floor log2 p
  add: op.xor
  mul: (p, h) -> reduce op.xor,
                        (map_ \
                          (filter_ (range Math.max 0, @degree p),
                                   (n) -> bit p, n),
                          (n) -> h << n),
                        r
  divmod: (p, h) ->
    assert h > 0, 'division by zero'
    hd = @degree h
    m = p
    md = @degree m
    d = 0
    while md >= hd
      d ^= 1 << (md - hd)
      m ^= h << (md - hd)
      md = @degree m
    return [d, m]
  div: (p, h) -> (@divmod p, h)[0]
  mod: (p, h) -> (@divmod p, h)[1]

###
do test = ->
  try
    bf = binaryField
    for p1 in [0...2**4]
      divzok = yes
      try
        bf.div p1, 0 # should throw
        divzok = no
      assert divzok, 'division by zero throws'
      assert (p1 == bf.mul p1, 1), 'bf.mul 1 identity'
      for p2 in [0...2**4]
        mul = bf.mul p1, p2
        mul1 = bf.mul p2, p1
        assert mul == mul1, 'bf.mul commutativity'
        assert 0 == mul, 'bf.mul 0' if p1 == 0 or p2 == 0
        assert (p1 == bf.div mul, p2), 'bf.mul is inverse of bf.div' if p2 != 0
        assert (0 == bf.mod mul, p2), 'bf.mod == 0' if mul != 0
  catch e
    try
      console.log p1.toString(2), p2.toString(2)
    catch e2
      console.log p1, p2
    throw e
  console.log 'test ok'
###

# arrays
zip = (arrays...) -> arrays[0].map (_,i) -> arrays.map (a) -> a[i]

zipWith = (f, arrays...) -> (zip arrays...).map (a) -> f a...
zipWith_ = flip2 zipWith

reduce = (f, arr, zero) ->
  switch arguments.length
    when 2
      arr.reduce f
    when 3
      arr.reduce f, zero

reduce_ = flip2 reduce

map = (f, arr) -> arr.map f
map_ = flip2 map

filter = (f, arr) -> arr.filter f
filter_ = flip2 filter

range = (args...) ->
  switch args.length
    when 1
      [end] = args
      return [0...end]
    when 2
      [start, end] = args
      return [start...end]
    when 3
      [start, end, step] = args
      return (i for i in [start...end] by step)
    else throw new Error 'Invalid number of arguments'

frange = (start, end, step) ->
  switch typeof step
    when 'number'
      return (i for i in [start...end] by step)
    when 'function'
      data = []
      x = start
      while x < end
        data.push x
        x += step x
      return data

sum = (arr) -> reduce op.add, arr, 0
product = (arr) -> reduce op.mul, arr, 1

maximum = (arr) -> reduce_ arr, (a, b) -> if a > b then a else b
minimum = (arr) -> reduce_ arr, (a, b) -> if a < b then a else b

compare = (a, b) -> switch true
  when a < b  then -1
  when a == b then 0
  when a > b  then 1

len = (a) ->
  switch typeof a.length
    when 'number' then return a.length
    when 'function' then return a.length()

splitEvery = (n, arr) ->
  assert n > 0
  result = []
  chunk = []
  for x, i in arr
    if i and i % n == 0
      result.push chunk
      chunk = []
    chunk.push x
  return result

ncalls = (f, n, args...) -> ((f args...) for i in [0...n])
ncalls_ = flip2 ncalls

concat = (arr) -> [].concat arr...

concatMap = compose concat, map
concatMap_ = flip2 concatMap

replicate = (n, e) -> (e for i in [0...n])

groupBy = (f, arr) ->
  return [] if not len(arr)
  pe = arr[0]
  chunks = []
  chunk = [pe]
  for e in arr.slice 1
    if f pe, e
      chunk.push e
    else
      chunks.push chunk
      chunk = [e]
    pe = e
  return chunks
groupBy_ = flip2 groupBy

group = (arr) -> groupBy op.eq, arr
