
main = ->

  isnot = (o) -> (o_) -> o_ isnt o

  itemgetter = (i) -> (o) -> o[i]

  randrange = (a1, a2) ->
    if a2 is undefined
      [min, max] = [0, a1]
    else
      [min, max] = [a1, a2]
    return min + Math.floor(Math.random()*(max-min))

  zip = (arrays...) -> arrays[0].map (_,i) -> arrays.map (a) -> a[i]
  zipWith = (f, arrays...) -> (zip arrays...).map (a) -> f a...
  reduce = (f, arr) -> arr.reduce f
  map = (f, arr) -> arr.map f

  op =
    plus: (a, b) -> a + b
    minus: (a, b) -> a - b

  sum = (arr) -> reduce op.plus, arr

  avg = (xs...) -> (xs.reduce (a, b) -> a + b) / xs.length

  uniqueId = (prefix = '') -> prefix + Math.random().toString()

  dashToCamel = (s) -> s.replace /-[a-z]/g, (m) -> m[1].toUpperCase()

  prettyPrintTime = (t, precision='s') ->
    str = ""
    h = t // (60*60)
    str += "#{h} ч."
    return str if precision == 'h'
    m = (t % (60*60)) // 60
    str += " #{m} мин."
    return str if precision == 'm'
    s = t % 60
    str += " #{s} ч."
    return str

  class Point
    constructor: (x, y, @demand) ->
      @data = {} # simulation data

      Point::radius = 8

      @warehouse = false
      if @demand == undefined
        @warehouse = true
        @demand = 0
      [@x, @y] = [x, y]

      mapCanvas.$.drawArc \
          layer: true,
          draggable: true,
          bringToFront: true,
          data: { point: @ },
          fillStyle: if @warehouse then '#37A42C' else "#F65E3B",
          x: x, y: y,
          radius: Point::radius,
          dragstart: (@dragstart.bind @),
          drag: (@drag.bind @),
          dragstop: (@dragstop.bind @),
          click: (@click.bind @),
          dblclick: (@dblclick.bind @)

    resetData: ->
      @data.demand = @demand

    removeLayer: ->
      mapCanvas.$.removeLayers (l) => l.data.point == @

    dragstart: => @stillDragging = true
    drag: (l) => @x = l.x; @y = l.y;
    # HACK dragstop fires before click
    dragstop: => setTimeout (=> @stillDragging = false), 100
    click: (l) =>
      mapCanvas.pointSelected(@) if not @stillDragging
    dblclick: ->
      return if @warehouse
      mapCanvas.removePoint @

    distanceTo: (p) ->
      [x1, y1] = mapCanvas.toReal @x, @y
      [x2, y2] = mapCanvas.toReal p.x, p.y
      return Math.sqrt((x1 - x2)**2 + (y1 - y2)**2)

  class Path
    constructor: (@followCursor = off) ->
      @points = []
      @cars = []

      mapCanvas.$.addLayer \
          type: 'function',
          data: { path: @ },
          fn: (@draw.bind @)

    draw: (ctx) ->
      return if not @points.length
      ctx.globalAlpha = 0.4
      ctx.lineWidth = 2
      ctx.strokeStyle = '#000'
      ctx.lineCap = 'round'
      ctx.lineJoin = 'round'
      ctx.beginPath()
      ctx.moveTo @points[0].x, @points[0].y
      for p in @points[1..]
        ctx.lineTo p.x, p.y
      if @followCursor
        ctx.lineTo mapCanvas.curX, mapCanvas.curY
      ctx.stroke()

      if @points.length > 1
        i = mapCanvas.paths.indexOf @
        [ax, ay] = zipWith avg, (@points.map (p) -> [p.x, p.y])...
        ctx.font = 'normal 1em Arial';
        ctx.textAlign = 'center'
        ctx.fillStyle = '#000'
        ctx.globalAlpha = 0.4
        ctx.fillText \
            'Маршрут ' + (i+1),
            ax,
            ay
        ctx.globalAlpha = 1
        ctx.fillStyle = '#F65E3B'
        ctx.fillText \
            @demand() + ' шт.',
            ax,
            ay + 16

    removeLayer: ->
      mapCanvas.$.removeLayers (l) => l.data.path == @

    addPoint: (p) ->
      @points.push p
      pathsTable.update()

    removePoint: (p) ->
      @points = @points.filter isnot p
      if (@points.filter (p) -> not p.warehouse).length == 0
        mapCanvas.removePath @
      pathsTable.update()

    addCar: (c) ->
      return if c in @cars
      @cars.push c
      carsTable.update()

    removeCar: (c) ->
      @cars = @cars.filter isnot c
      carsTable.update()

    length: -> sum zipWith ((pp, p) -> pp.distanceTo p), @points[0..-2], @points[1..]

    demand: -> sum map (itemgetter 'demand'), @points

  class Car
    constructor: (@hired = false, @capacity = 200) ->
      @data = {} # simulation data
      @resetData()

    resetData: ->
      @data.t = 0 # total time spent working
      @data.trunk = 0
      @data.paths = {} # path index -> true
      @data.boxCount = 0
      @data.distance = 0
      @data.distanceFee = 0
      @data.constantFee = if @hired then config.dailyHired else config.dailyOwn
      @data.overtimeFee = 0
      @data.minUnitsPenalty = 0
      @data.minWorkTimePenalty = 0
      @data.expeditorFee = if @hired then config.expeditor else 0
      @data.totalFee = @data.constantFee + @data.expeditorFee

  class Table
    constructor: (@id, @addRemoveBtn = on, @vertical = off) ->
      @$ = $ '#' + id

    updateHorizontal: ->
      @$.find('tr')
        .slice(1) # skip header
        .remove()

      tbody = @$.children('tbody')
      for row in @rows()
        tbody.append(
          $('<tr>').append(
            ($('<td>').append(td) for td in row)...
          ).append(
            if @addRemoveBtn
            then $('<td>').append(
                    $('<button>')
                      .append('Удалить')
                      .button()
                      .click(@remove.bind(@, row))
                  )
            else ''
          )
        )

    updateVertical: ->
      @$.find('td').remove()

      for row in @rows()
        @$.find('tr').each (i) ->
          $(this).append(
            $('<td>').append row[i]
          )

    update: -> if @vertical then @updateVertical() else @updateHorizontal()

    rows: -> throw new Error 'Subclass should supply rows method.'
    remove: (row) -> throw new Error 'Subclass should supply remove method.'

  $.widget "ui.suffixSpinner", $.ui.spinner, {
    _create: (->
      this._super()
      this.options.default = this.options.default or this.element.attr('default') or 0
      this.options.suffix = this.options.suffix or this.element.attr('suffix') or ''
      this.element.val(this.options.default+' '+this.options.suffix)
    ),
    _format: ((value) ->
      value + ' ' + this.options.suffix
    ),
    _parse: ((value) ->
      parseInt value
    )
  }

  pathsTable = new (class extends Table
    rows: ->
      for i, path of mapCanvas.paths
        pointsCount = path.points
          .filter((p) -> not p.warehouse)
          .length
        [(parseInt(i)+1), pointsCount, path.demand()]
    remove: ([i, _...]) ->
      mapCanvas.removePath mapCanvas.paths[parseInt(i)-1]
  ) 'paths-table'

  marketsTable = new (class extends Table
    rows: ->
      for i, p of mapCanvas.points
        continue if p.warehouse
        demand = $("<input type='text'>")
        demand.suffixSpinner \
            min: 1, max: 9999,
            default: p.demand, suffix: 'шт',
            change: do (p = p) -> (e) ->
              p.demand = parseInt e.target.value
              pathsTable.update()
              mapCanvas.$.drawLayers()
        demand.width 80
        demand = demand.parent() # jqueryui wraps it
        [i, demand]
    remove: ([i, _...]) ->
      mapCanvas.removePoint mapCanvas.points[i]
  ) 'markets-table'

  carsTable = new (class extends Table
    constructor: ->
      $('#car-add').button().click(@addCar.bind @)
      super
    rows: ->
      for i, car of mapCanvas.cars
        id1 = uniqueId()
        hired = $ "<input type='radio' name='hired#{id1}' id='#{id1}'>"
        hired.attr('checked', 'checked') if car.hired
        hiredLabel = $("<label for='#{id1}'>").append('Наёмная')

        id2 = uniqueId()
        own = $("<input type='radio' name='hired#{id1}' id='#{id2}'>")
            .change(do (car = car) -> (e) -> car.hired = $(this).is(':checked'))
        own.attr('checked', 'checked') if not car.hired
        ownLabel = $("<label for='#{id2}'>").append('Собственная')
        hiredOwn = $('<div>').append(hired, hiredLabel, own, ownLabel).buttonset()

        capacity = $("<input type='text'>")
        capacity.suffixSpinner \
            min: 1, max: 9999,
            default: car.capacity, suffix: 'шт',
            change: do (car = car) -> (e) ->
              car.capacity = parseInt e.target.value
        capacity.width 80
        capacity = capacity.parent() # jqueryui wraps it

        routes = $ '<div>'
        for j, p of mapCanvas.paths
          id = uniqueId()
          box = $ "<input type='checkbox' id='#{id}'>"
          box.attr('checked', 'checked') if car in p.cars
          box.change do (car = car, p = p) -> (e) ->
            if $(this).is(':checked')
              p.addCar car
            else
              p.removeCar car
          lbl = $("<label for='#{id}'>").append(parseInt(j)+1)
          routes.append box, lbl
        routes.buttonset()

        [(parseInt(i)+1), hiredOwn, capacity, routes]
    addCar: ->
      mapCanvas.addCar new Car
    remove: ([i, _...])->
      mapCanvas.removeCar mapCanvas.cars[i-1]
  ) 'cars-table'

  resultTable = new (class extends Table
    constructor: ->
      $('#calculate').button().click(@update.bind @)
      $('a[href="#tabs-result"]').click(@update.bind @)
      super
    rows: ->
      do simulate
      total = 0
      rows = []
      for i, c of mapCanvas.cars
        row = [parseInt(i)+1]
        row.push if c.hired then 'Наёмная' else 'Своя'
        row.push ([(parseInt(j)+1) for j, _ of c.data.paths].join ', ') or 'ни одного'
        row.push prettyPrintTime c.data.t, 'm'
        row.push c.data.boxCount + ' шт'
        row.push (c.data.distance/1000).toFixed(2) + ' км'
        row.push c.data.distanceFee.toFixed(2) + ' руб'
        row.push c.data.constantFee.toFixed(2) + ' руб'
        row.push c.data.overtimeFee.toFixed(2) + ' руб'
        row.push c.data.minUnitsPenalty.toFixed(2) + ' руб'
        row.push c.data.minWorkTimePenalty.toFixed(2) + ' руб'
        row.push c.data.expeditorFee.toFixed(2) + ' руб'
        row.push c.data.totalFee.toFixed(2) + ' руб'
        total += c.data.totalFee
        rows.push row
      $('#total-total').text "Всего: #{ total.toFixed(2) } руб"
      return rows
  ) 'result-table', false, true

  simulate = ->
    c.resetData() for c in mapCanvas.cars
    p.resetData() for p in mapCanvas.points

    log = -> console.log "simulate:", arguments...

    for i, path of mapCanvas.paths
      cars = path.cars.slice() # copy
      log 'cars:', cars
      c = cars.pop()
      continue if not c

      pp = path.points[0]
      pointsQueue = path.points.slice()
      log 'points queue:', pointsQueue
      while (p = pointsQueue.shift()) and c
        log 'point:', p
        while p.data.demand > 0 or p.warehouse
          d = pp.distanceTo p
          log 'driving from', pp, 'to', p, "(#{d} m)"

          if p.warehouse
            log 'destination is a warehouse'
            t = d/config.speed + c.capacity*config.unloadSpeed
          else
            log 'destination is a market'
            if c.data.trunk == 0
              pointsQueue.unshift p
              pointsQueue.unshift path.points[0]
              break
            supply = Math.min(p.data.demand, c.data.trunk)
            t = d/config.speed \ # time spent on road
                + supply*config.unloadSpeed \ # time spent on unload
                + config.paperSpeed # time spent on papers

          if c.data.t + t > config.driverMaxWorkTime
            log 'car', c, 'reached work time limit'
            # TODO? drive home (applies to own cars or does not apply at all?)
            c = cars.pop()
            break if not c
            # start from warehouse
            log 'popped next car', c
            pp = path.points[0]
            pointsQueue.unshift p
            pointsQueue.unshift path.points[0]
            break

          if p.warehouse
            c.data.trunk = c.capacity
          else
            c.data.paths[i] = true
            c.data.trunk -= supply
            p.data.demand -= supply
            c.data.boxCount += supply

          c.data.distance += d
          c.data.distanceFee += (if c.hired then config.kmHired else config.kmOwn)*d/1000
          c.data.totalFee += c.data.distanceFee
          c.data.t += t

          if c.data.t > config.driverWorkTime \
          and not c.data.overtimeFee # count only once per driver
            c.data.overtimeFee += config.driverOvertime*(c.data.t-config.driverWorkTime)
            c.data.totalFee += c.data.overtimeFee

          if p.warehouse
            break

        pp = p

    for c in mapCanvas.cars
      # minimum transported units penalty
      if c.data.boxCount < config.minUnits
        c.data.minUnitsPenalty += config.minUnitsPenalty * (config.minUnits - c.data.boxCount)
        c.data.totalFee += c.data.minUnitsPenalty
      # minimum work time penalty
      if c.data.t < config.minWorkTime
        c.data.minWorkTimePenalty += if c.hired then config.minOwnWorkTimePenalty else config.minHiredWorkTimePenalty
        c.data.totalFee += c.data.minWorkTimePenalty


  config =
    init: ->
      @$ = $ '#tabs-config'
      $('#config-apply').button().click @apply.bind @
      @apply()

    apply: ->
      @$.find('input[wrapme="spinner"]').each ->
        config[dashToCamel this.id] = $(this).suffixSpinner('value')

      @speed = @speed*0.277778 # km/h to m/s
      @paperSpeed = @paperSpeed*60 # m to s
      @driverWorkTime = @driverWorkTime*60*60 # h to s
      @driverMaxWorkTime = @driverMaxWorkTime*60*60 # h to s
      @driverOvertime = @driverOvertime/60/60 # rub/h to rub/s
      @minWorkTime = @minWorkTime*60*60 # h to s

      mapCanvas.setRealSize @mapRealWidth, @mapRealHeight

  # wrap wrapme-stuff
  do ->
    $('[wrapme="spinner"]').each (i) ->
      $(this).suffixSpinner \
          min: 1,
          max: 999999
      $(this).width($(this).attr('width_') or 80)

#     $('[wrapme="button"]').each (i) -> $(this).button()

  tabs =
    init: ->
      @$ = $ '#tabs'
      @$.tabs()


  mapCanvas =
    points: []
    paths: []
    cars: []

    init: ->
      @$ = $ '#map-canvas'

      do @initBg
      do @initCrosshair
      do @initPointsInfo
      do @initHelp

      do config.init
      do tabs.init

      @pathMode = false

      @w = @$.width(); @h = @$.height()

      # HACK purely for events
      @$.drawRect \
          layer: true,
          fillStyle: 'rgba(0, 0, 0, 0)',
          x: @w/2, y: @h/2,
          width: @w, height: @h,
          dblclick: (@dblclick.bind @)

      @addPoint(new Point @w/2, @h/2)

      # add random points
      [hw, hh] = [@w/2, @h/2]
      for i in [0..7]
        [kx, ky] = [(i & 1 << 2) >> 2, (i & 1 << 1) >> 1]
        [x, y] = [randrange(hw*kx, hw + hw*kx)
                 ,randrange(hh*ky, hh + hh*ky)]
        @addPoint(new Point(x, y, randrange(100)))

      for i in [1..4] by 2
        # add a path
        path = new Path
        path.addPoint @points[0]
        for p in @points[i..i+1]
          path.addPoint p
        path.addPoint @points[0]
        @addPath path

      # add some cars
      car = new Car
      @addCar car
      p.addCar car for p in @paths

      @$.drawLayers()

    setRealSize: (w, h) -> @realW = w; @realH = h

    toCanvas: (x, y) -> [x*@w/@realW, y*@h/@realH].map Math.round
    toReal: (x, y) -> [x*@realW/@w, y*@realH/@h].map Math.round

    initBg: ->
      bg = $ '<canvas>'
      step = 15
      bg[0].width = bg[0].height = step
      bg.drawLine \
          strokeStyle: '#BBADA0',
          strokeWidth: 1,
          x1: step, y1: 0,
          x2: step, y2: step,
          x3: 0,    y3: step

      @$.css 'background': "url(#{ bg[0].toDataURL('image/png') }) repeat"

    initCrosshair: ->
      x = y = null
      @$.on 'mousemove', (e) =>
        @curX = x = Math.round (e.pageX - @$.offset().left)
        @curY = y = Math.round (e.pageY - @$.offset().top)
      @$.on 'mouseout', (e) =>
        x = y = null
        @$.drawLayers()
      @$.addLayer \
          type: 'function',
          name: 'crosshair',
          fn: (ctx) =>
            return if x == null

            ctx.globalAlpha = 1

            @$.drawLine \
                strokeStyle: '#8F7A66',
                strokeWidth: 1,
                x1: x - .5, y1: .5,
                x2: x - .5, y2: @h + .5

            @$.drawLine \
                strokeStyle: '#8F7A66',
                strokeWidth: 1,
                x1: .5,      y1: y + .5,
                x2: @w + .5, y2: y + .5

            [rx, ry] = @toReal x, y
            ctx.font = 'normal 1em Arial';
            ctx.fillStyle = '#8F7A66'
            l = x < @w/2
            t = y < @h/2
            ctx.textAlign = if l then 'left' else 'right'
            ctx.fillText \
                rx + ' м',
                x + (if l then 4 else -4),
                if t then @h-4 else 16
            ctx.textAlign = if l then 'right' else 'left'
            ctx.fillText \
                ry + ' м',
                if l then @w - 4 else 4,
                y + (if t then 16 else -4)

    initPointsInfo: ->
      @$.addLayer \
          type: 'function',
          fn: ((ctx) =>
            ctx.globalAlpha = 1
            ctx.font = 'normal 1em Arial';

            for i, p of @points
              ctx.textAlign = 'left'
              ctx.fillStyle = '#8F7A66'
              ctx.fillText \
                  if p.warehouse then 'Склад' else 'Магазин ' + i,
                  p.x + 16,
                  p.y + 6
              if p.demand
                ctx.textAlign = 'right'
                ctx.fillStyle = '#F65E3B'
                ctx.fillText \
                    p.demand + ' шт.',
                    p.x + -16,
                    p.y + 6
          )

    initHelp: ->
      mousedown = =>
        @$.off 'mousedown', mousedown
        $('#help').fadeOut()
      @$.on 'mousedown', mousedown
      click = ->
        $(this).off 'click', click
        $(this).fadeOut()
      $('#help').on 'click', click

    addPath: (p) ->
      @paths.push p
      pathsTable.update()
      carsTable.update()

    removePath: (p) ->
      @paths = @paths.filter isnot p
      p.removeLayer()
      pathsTable.update()
      carsTable.update()
      @$.drawLayers()

    addPoint: (p) ->
      @points.push p
      marketsTable.update()

    removePoint: (p) ->
      @points = @points.filter isnot p
      path.removePoint p for path in @paths
      p.removeLayer()
      marketsTable.update()
      @$.drawLayers()

    addCar: (c) ->
      return if c in @cars
      @cars.push c
      carsTable.update()

    removeCar: (c) ->
      @cars = @cars.filter isnot c
      carsTable.update()

    dblclick: (l) ->
      @addPoint(new Point(l.eventX, l.eventY, 1))

    pointSelected: (p) ->
      # path creation
      if p.warehouse
        @togglePathMode()
        if @pathMode
          path = new Path true
          path.addPoint p
          @addPath path
        else
          path = @paths[@paths.length-1]
          path.followCursor = false
          path.addPoint p
          if path.points.every((p) -> p.warehouse)
            path.removeLayer()
            @removePath path
      if @pathMode
        if not @paths.some((path)-> p in path.points)
          @paths[@paths.length-1].addPoint p

    togglePathMode: -> @pathMode = not @pathMode

  do mapCanvas.init

$ main
