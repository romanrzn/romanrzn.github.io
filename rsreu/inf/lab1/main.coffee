
$ ->
  n = 30000
  b = 3
  c = 2

  config.define
    title: 'Количество случайных чисел:'
    default: n
    valid: (v) -> n > 1
    change: (v) -> n = v

  config.define
    title: 'Параметр b'
    default: b
    valid: (v_) -> v_ > 0
    change: (v_) -> b = v_

  config.define
    title: 'Параметр c'
    default: c
    valid: (v_) -> v_ > 0
    change: (v_) -> c = v_

  $('#apply-config').button().click ->
    weibull = (uniform) -> b * (- (log uniform)) ** (1/c)
    weibullDensity = (x) -> (c / b) * (x / b) ** (c - 1) * exp(- (x / b) ** c)

    data = map weibull, ncalls Math.random, n

    min = minimum data
    max = maximum data
    expectation = (sum data) / (len data)
    variance = (sum map_ data, (x) -> (x - expectation)**2) / (len data)
    deviation = Math.sqrt variance

    intervals = 1 + (Math.floor (.5 + (log2 n)))
    intervalSize = (max - min) / intervals

    inrange = (s, e) -> (x) -> s < x and x <= e
    countFilter_ = compose len, filter_
    buckets = map_ (frange min, max, intervalSize), (s) ->
      [s, countFilter_ data, inrange s, s + intervalSize]

    densityStep = intervalSize / 10
    density = map_ (frange min, max, densityStep), (x) -> [x, weibullDensity x]

    plotPlaceholder = $("#plot")
    plot = $.plot plotPlaceholder, [
      {
        data: buckets
        bars:
          show: yes
          barWidth: intervalSize
        yaxis: 1
      }
      {
        data: density
        yaxis: 2
      }
    ], {
      yaxes: [{}, {}]
    }

    mark = (label, x, y) ->
      o = plot.pointOffset x: x, y: y
      plotPlaceholder.append "<div
        style='
          position: absolute;
          left: #{o.left + 6}px;
          top: #{o.top + 16}px'
        >
          #{label}
        </div>"
      ctx = plot.getCanvas().getContext "2d"
      ctx.beginPath()
      o.left += 4;
      ctx.moveTo o.left - 1, o.top - 5
      ctx.lineTo o.left - 1, o.top + 5
      ctx.lineTo o.left + 1, o.top + 5
      ctx.lineTo o.left + 1, o.top - 5
      ctx.fillStyle = "#000"
      ctx.fill()

    mark 'min', min, 0
    mark 'max', max, 0
    mark 'M(x)', expectation, 0
    mark 'M(x) - σ(x)', expectation - deviation, 0
    mark 'M(x) + σ(x)', expectation + deviation, 0

  $('#apply-config').click()



