
config = null
$ -> config = new class
  container = $ '#config'

  onvalues = (f) -> (e) ->
    f.call this, $(e.currentTarget).spinner("value"), $(e.currentTarget).val(), e

  define: (descr) ->
    descr.$ ?= {}
    if not descr.type
      descr.type = do ->
        if descr.default
          switch typeof descr.default
            when 'string'
              if -1 != descr.default.indexOf '\n'
                return 'textarea'
              return 'input'
            when 'number'
              if not descr.$.step
                if descr.default % 1 != 0
                  descr.$.step = 0.01
              return 'spinner'

    descr.valid = (-> yes) if not descr.valid
    if descr.change
      descr.$.change = (e) ->
        try
          if (onvalues descr.valid) e
            (onvalues descr.change) e
            $(e.currentTarget).css 'background', 'transparent'
          else
            throw (onvalues -> arguments) e
        catch err
          $(e.currentTarget).css 'background', 'orangered'
          $(e.currentTarget).focus()
          console.log 'validation error:', err

    row = $ '<div>'
    container.append row

    title = $ '<span>'
    title.html descr.title + ':'
    title.css 'margin-right', '1em'
    row.append title

    switch descr.type
      when 'textarea'
        node = $ "<textarea>"
        row.append node
        descr.$.spin = -> no
        node.spinner descr.$
        node.css 'margin-right', '.4em'
        node.parent().children('.ui-spinner-button').remove()
      when 'input'
        node = $ "<input>"
        row.append node
        descr.$.spin = -> no
        node.spinner descr.$
        node.css 'margin-right', '.4em'
        node.parent().children('.ui-spinner-button').remove()
      when 'spinner'
        node = $ "<input>"
        row.append node
        node.spinner descr.$

    node.val descr.default

    return node
