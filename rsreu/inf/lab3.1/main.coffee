
noErrorIntervalsToErrors = (intervals) ->
  concatMap_ intervals, (n) -> (replicate n, 0).concat [1]

errorsToNoErrorIntervals = (errors) ->
  concatMap_ (group errors), (chunk) -> if chunk[0] \
    then replicate (len(chunk) - 1), 0 \
    else [len(chunk)]

$ ->
  p = 1.1 * 10**-4
  m = 24
  n = 3 * 10**5

  config.define
    title: 'p'
    default: p
    valid: (v) -> v > 0 and v < 1
    change: (v) -> p = v
    $:
      min: 10**-5
      max: 1 - 10**-5
      step: 10**-5

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
    genNoerrorIntervalLength = -> Math.round log Math.random(), (1 - p)

    noerrorIntervals = []
    i = 0; while i < n
      noerrorIntervals.push interval = genNoerrorIntervalLength()
      i += interval + 1
    errors = noErrorIntervalsToErrors noerrorIntervals
    blocks = splitEvery m, errors

    $('#error-intervals').val noerrorIntervals.join ','
    $('#error-coeff').text sprintf '%.4f', len(noerrorIntervals) / n

    errBlocksCount = len filter_ blocks, (b) -> 1 in b
    $('#grouping-coeff').text sprintf '%.4f', ((log len noerrorIntervals) - (log errBlocksCount))/(log m)
    $('#block-error-coeff').text sprintf '%.4f', errBlocksCount / (len blocks)

    noerrorBlockIntervals = errorsToNoErrorIntervals map_ blocks, (b) -> 0 + (1 in b)
    $('#block-intervals').val noerrorBlockIntervals.join(',')

  $('#apply-config').click()



