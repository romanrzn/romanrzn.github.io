
$ ->
  l = 24
  p = 5 * 10 ** -5
  m = 8
  n = 30000
  v = 20000

  config.define
    title: 'p<sub>ош</sub>'
    default: p
    valid: (v) -> v > 0 and v < 1
    change: (v) -> p = v
    $:
      min: 10 ** -8
      max: 1 - 10 ** -8
      step: 10 * -5

  config.define
    title: 'Число неинформационных элементов в блоке l'
    default: l
    valid: (v) -> l > 1
    change: (v) -> l = v

  config.define
    title: 'Число повторяемых при переспросе комбинаций M'
    default: m
    valid: (v) -> v > 1
    change: (v) -> m = v

  config.define
    title: 'Общее число переданных кадров N'
    default: n
    valid: (v) -> n > 1
    change: (v) -> n = v

  config.define
    title: 'Число переспросов V'
    default: v
    valid: (v_) -> v_ > 1
    change: (v_) -> v = v_

  $('#apply-config').button().click ->
    f = (k) -> (k/(k+1)) * ((n - v*(m - l))/n)

    data = map_ (frange 0, n, (x) -> if x < 100 then 10 else 100), (k) -> [k, f k]

    $.plot "#plot", [data]

  $('#apply-config').click()



