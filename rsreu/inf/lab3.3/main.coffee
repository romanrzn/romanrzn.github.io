
$ ->
  p = 0.01
  alpha = .5
  m = 24
  n = 3 * 10**5

  config.define
    title: 'p<sub>ош</sub>'
    default: p
    valid: (v) -> v > 0 and v < .5
    change: (v) -> p = v

  config.define
    title: 'Коэффициент группирования α'
    default: alpha
    valid: (v) -> v > 0 and v < 1
    change: (v) -> alpha = v

  config.define
    title: 'Длина последовательности N'
    default: n
    valid: (v) -> v > 1
    change: (v) -> n = v

  config.define
    title: 'Длина блока m'
    default: m
    valid: (v) -> 10 < v and v < 500
    change: (v) -> m = v

  for selector in [
    '#blocks'
  ]
    $(selector).spinner spin: -> no
    $(selector).css 'margin-right', '.4em'
    $(selector).parent().children('.ui-spinner-button').remove()

  $('#apply-config').button().click -> do (p_=p, p=null) ->
    p = [
      [_p00 = (1 - p_*(2*m)**(1-alpha))/(1 - p_*m**(1-alpha)), 1 - _p00]
      [_p10 = 1 - (2 - 2**(1-alpha)), 1 - _p10]
    ]

    console.log JSON.stringify p

    yesno = (yesprob) -> Math.random() <= yesprob

    blockErrors = []
    STATE_GOOD = 0
    STATE_ERR = 1
    state = STATE_GOOD
    while len(blockErrors) < n
      switch state
        when STATE_GOOD
          blockErrors.push 0
          if yesno p[0][1]
            state = STATE_ERR
        when STATE_ERR
          blockErrors.push 1
          if yesno p[1][0]
            state = STATE_GOOD

    $('#blocks').val blockErrors.join ','

    errorBlocksCount = len filter_ blockErrors, (x) -> !!x
    $('#block-error-coeff').text sprintf '%.3f', errorBlocksCount / (len blockErrors)
    $('#grouping-coeff').text sprintf '%.3f', ((log (len blockErrors)*p_*m) - (log errorBlocksCount))/(log m)


  $('#apply-config').click()



