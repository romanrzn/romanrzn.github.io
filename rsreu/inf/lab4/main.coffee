
$ ->
  [n, k, g, msg] = [7, 4, 0b1011, 0b0110]

  config.define
    title: 'n'
    default: n
    valid: (v) -> v > 1 and v > k
    change: (v) -> n = v
  config.define
    title: 'k'
    default: k
    valid: (v) -> v > 1 and n > v
    change: (v) -> k = v

  binStrValidator = (len) -> (_, v) ->
    (v.length > 0) \
      and (v.length <= len) \
      and (v.split('').every (c) -> c in ['0', '1'])

  config.define
    title: 'Образующий полином'
    default: sprintf "%0#{k}b", g
    valid: -> (binStrValidator k) arguments...
    change: (_, v) -> g = parseInt v, 2
  config.define
    title: 'Информационная последовательность'
    default: sprintf "%0#{k}b", msg
    valid: -> (binStrValidator k) arguments...
    change: (_, v) -> msg = parseInt v, 2

  encode = (msg) ->
    code = msg << binaryField.degree g
    code = code ^ binaryField.mod code, g
    return code

  decode = (code) ->
    mod = binaryField.mod code, g
    throw new Error 'mod /= 0' if mod
    decoded = code >> binaryField.degree g
    return decoded

  $('#result-code').spinner spin: -> no
  $('#result-code').css 'margin-right', '.4em'
  $('#result-code').parent().children('.ui-spinner-button').remove()

  $('#apply-config').button().click ->
    $('#encoded').text sprintf "%0#{n}b", encode msg
    $('#decoded').text sprintf "%0#{k}b", decode encode msg

  $('#apply-config').click()






