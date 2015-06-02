
$ ->
  mkcell = -> {
      value: ko.observable 0
    }
  mkrow = -> {
      cells: ko.observableArray []
    }
  mkrel = -> {
      rows: ko.observableArray []

      h: -> @rows().length
      w: -> @rows()[0].cells().length
      at: (i, j) -> @rows()[i].cells()[j].value()
      set: (i, j, v) -> @rows()[i].cells()[j].value(v)
      row: (i) -> @rows()[i].cells().map (c) -> c.value()
      col: (j) -> @rows().map (r) -> r.cells()[j].value()

      addCol: ->
        for r in @rows()
          r.cells.push mkcell()
        @
      delCol: ->
        for r in @rows()
          return if r.cells().length < 2
          r.cells.pop()
        @
      addRow: ->
        row = mkrow()
        for x in (@rows()[0]?.cells || -> [])()
          row.cells.push mkcell()
        @rows.push row
        @
      delRow: ->
        @rows.pop() if @rows().length > 1
        @
    }

  model =
    rels: ko.observableArray []
    addRel: ->
      model.rels.push mkrel().addRow().addRow().addCol().addCol()
      @
    delRel: ->
      model.rels.pop() if @rels().length > 1
      @

    result: ko.observable()
    calc: ->
      @result model.rels().reduce (r, p) ->
        console.log 'add', ko.toJS(r), ko.toJS(p)
        return unless r and p
        return if r.w() != p.h()
        res = mkrel()
        res.addRow() for i in [0...r.h()]
        res.addCol() for j in [0...p.w()]
        for i in [0...r.h()]
          for j in [0...p.w()]
            console.log 'row', i, r.row(i), 'col', j, p.col(j)
            res.set i, j, maximum zipWith Math.min, r.row(i), p.col(j)
        console.log 'ret', res
        return res

  window.model = model
  model.addRel()

  ko.applyBindings model, $('#view')[0]
