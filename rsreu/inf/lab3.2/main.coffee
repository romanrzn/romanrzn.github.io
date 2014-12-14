
alternatingIntervalsToErrors = (intervals) ->
  concatMap_ (splitEvery 2, intervals), ([ne, e]) ->
    concat [(replicate ne, 0), (replicate e, 1)]

errorsToAlternatingIntervals = (errors) ->
  errors.unshift 0 if errors[0] # always starts with good interval
  return concatMap_ (splitEvery 2, group errors), (pair) -> map len, pair

$ ->
  p = [
    [.7, .3]
    [.6, .4]
  ]
  epsilon = .5

  m = 24
  n = 3 * 10**5

  defp = (descr) ->
    {
      subscript
    } = descr
    descr.title ?= "p<sub>#{subscript}</sub>"
    descr.valid ?= (v) -> v > 0 and v < 1
    descr.$ ?= {}
    descr.$.min ?= 10**-5
    descr.$.max ?= 1 - 10**-5
    config.define descr

  defp
    default: p[0][1]
    subscript: '01'
    change: (v) ->
      p[0][1] = v
      p[0][0] = 1 - v
  defp
    default: p[1][0]
    subscript: '10'
    change: (v) ->
      p[1][0] = v
      p[1][1] = 1 - v

  config.define
    title: 'Вероятность ошибки в "плохом" состоянии ε'
    default: epsilon
    valid: (v) -> v > 0 and v < 1
    change: (v) -> epsilon = v

  config.define
    title: 'Длина последовательности N'
    default: n
    valid: (v) -> v > 1
    change: (v) -> n = v

  config.define
    title: 'Длина блока m'
    default: m
    valid: (v) -> v > 0
    change: (v) -> m = v

  for selector in [
    '#error-intervals'
    '#block-intervals'
  ]
    $(selector).spinner spin: -> no
    $(selector).css 'margin-right', '.4em'
    $(selector).parent().children('.ui-spinner-button').remove()

  $('#apply-config').button().click ->
    yesno = (yesprob) -> Math.random() <= yesprob

    errors = []
    STATE_GOOD = 0
    STATE_ERR = 1
    state = STATE_GOOD
    while len(errors) < n
      switch state
        when STATE_GOOD
          errors.push 0
          if yesno p[0][1]
            state = STATE_ERR
        when STATE_ERR
          errors.push 0 + yesno epsilon
          if yesno p[1][0]
            state = STATE_GOOD
    alternatingIntervals = errorsToAlternatingIntervals errors

    blocks = splitEvery m, errors
    alternatingBlockIntervals = errorsToAlternatingIntervals map_ blocks, (b) -> 0 + (1 in b)

    pairs = splitEvery 2, alternatingIntervals
    errorsCount = sum(map_ pairs, (p) -> p[1])
    $('#error-intervals').val (map_ pairs, (pair) -> pair.join '/').join ','
    $('#error-coeff').text sprintf '%.3f', errorsCount / n

    errBlocksCount = len filter_ blocks, (b) -> 1 in b
    $('#grouping-coeff').text sprintf '%.3f', ((log errorsCount) - (log errBlocksCount))/(log m)
    $('#block-error-coeff').text sprintf '%.3f', errBlocksCount / (len blocks)

    $('#block-intervals').val (map_ (splitEvery 2, alternatingBlockIntervals), (pair) -> pair.join '/').join ','

  $('#apply-config').click()



