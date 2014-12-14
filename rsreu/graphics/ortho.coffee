
main = ->
  op =
    plus: (a, b) -> a + b
    minus: (a, b) -> a - b

  zip = (arrays...) -> arrays[0].map (_,i) -> arrays.map (a) -> a[i]
  zipWith = (f, arrays...) -> (zip arrays...).map (a) -> f a...
  reduce = (f, arr) -> arr.reduce f
  map = (f, arr) -> arr.map f

  sum = (arr) -> reduce op.plus, arr

  distance = (p1, p2) -> Math.sqrt sum map ((x) -> x**2), zipWith op.minus, p1, p2

  rotate = (a, i=1) ->
    a = a.slice()
    while i--
      a.unshift a.pop()
    return a

  class Body
    constructor: (o) ->
      @eye =
        theta: 0
        phi  : 0
        rho  : 500
        zoom : 300
        offsetX: 0
        offsetY: 0
      @world = o.world
      @edgesIndices = o.edgesIndices
      @trianglesIndices = o.trianglesIndices

    viewTransform: ->
      return (
        [
          (
            @eye.zoom * (
              - p[0]*Math.sin(@eye.theta) \
              + p[1]*Math.cos(@eye.theta)
            ) \
            + @eye.offsetX
          ),

          (
            @eye.zoom * (
              - p[0]*Math.cos(@eye.phi)*Math.cos(@eye.theta) \
              - p[1]*Math.cos(@eye.phi)*Math.sin(@eye.theta) \
              + p[2]*Math.sin(@eye.phi)
            ) \
            + @eye.offsetY
          ),
        ] for p in @world
      )

    screenTransform: ->
      view = (
        [
          (
            - @eye.zoom*p[0]*Math.sin(@eye.theta) \
            + @eye.zoom*p[1]*Math.cos(@eye.theta)
          ),

          (
            - @eye.zoom*p[0]*Math.cos(@eye.phi)*Math.cos(@eye.theta) \
            - @eye.zoom*p[1]*Math.cos(@eye.phi)*Math.sin(@eye.theta) \
            + @eye.zoom*p[2]*Math.sin(@eye.phi)
          ),

          (
            - @eye.zoom*p[0]*Math.sin(@eye.phi)*Math.cos(@eye.theta) \
            - @eye.zoom*p[1]*Math.sin(@eye.phi)*Math.sin(@eye.theta) \
            - @eye.zoom*p[2]*Math.cos(@eye.phi) \
            + @eye.rho
          ),
        ] for p in @world
      )
      screen = (
        [
          @eye.offsetX + @eye.zoom*p[0]/p[2],
          @eye.offsetY + @eye.zoom*p[1]/p[2],
        ] for p in view
      )
      return screen

  octahedron_world = (
    (
      (
        ((-1)**i)*(j == (i//2))
      ) for j in [0..2]
    ) for i in [0..5]
  )
  octahedron = new Body {
    world: octahedron_world
    edgesIndices: do =>
      ixs = []
      for i1, p1 of octahedron_world
        for i2, p2 of octahedron_world
          if i1 == i2
            continue
          if distance(p1, p2) > (Math.sqrt(2) + 0.01)
            continue
          ixs.push [i1, i2]
      return ixs
    trianglesIndices: do =>
      w = octahedron_world # w.length == 6
      triangles = []
      ixs = [2,4,3,5]
      for [i1, i2] in zip ixs, (rotate ixs)
        triangles.push [i1, i2, 0]
        triangles.push [i1, i2, 1]
      return triangles
  }


  cube_world = (
    (
      (
        (-1)**((i >> j) & 1)*.5
      ) for j in [0..2]
    ) for i in [0..7]
  )
  cube = new Body {
    world: cube_world
    edgesIndices: do =>
      ixs = []
      for i1, p1 of cube_world
        for i2, p2 of cube_world
          if i1 == i2
            continue
          if distance(p1, p2) > (1 + 0.01)
            continue
          ixs.push [i1, i2]
      return ixs
    trianglesIndices: do =>
      w = cube_world
      triangles = []
      ixs = [0,1,3,2]
      ixsr = (rotate ixs)
      for [i1, i2, i3, i3r] in zip ixs, ixsr, (map ((i) -> i + 4), ixs), (map ((i) -> i + 4), ixsr)
        triangles.push [i1, i2, i3]
        triangles.push [i1+4, i2+4, i3r-4]
      for inc in [0, 4]
        for rot in [0, 2]
          ixs_ = rotate ixs, rot
          ixs_ = map ((i) -> i + inc), ixs_
          triangles.push (ixs_.slice 0, 3)

      return triangles
  }

  class Canvas
    constructor: (@body, id) ->
      @modes = ['rotate', 'zoom', 'move']

      @$ = $ '#' + id

      @w = @$.width(); @h = @$.height()

      @$.addLayer \
          type: 'function',
          name: 'body',
          fn: (ctx) =>
            ctx.lineWidth = 1
            ctx.globalAlpha = 1
            ctx.strokeStyle = 'white'
            ctx.fillStyle = 'black'
            points = @transform()
            for [i1, i2, i3] in @body.trianglesIndices
              [x1, y1] = map Math.round, points[i1]
              [x2, y2] = map Math.round, points[i2]
              [x3, y3] = map Math.round, points[i3]
              ctx.beginPath()
              ctx.moveTo x1 + @w / 2 + .5, y1 + @h / 2 + .5
              ctx.lineTo x2 + @w / 2 + .5, y2 + @h / 2 + .5
              ctx.lineTo x3 + @w / 2 + .5, y3 + @h / 2 + .5
              ctx.fill()
            for [i1, i2] in @body.edgesIndices
              [x1, y1] = map Math.round, points[i1]
              [x2, y2] = map Math.round, points[i2]
              ctx.beginPath()
              ctx.moveTo x1 + @w / 2 + .5, y1 + @h / 2 + .5
              ctx.lineTo x2 + @w / 2 + .5, y2 + @h / 2 + .5
              ctx.stroke()

      do @initCoordinatesLayer
      do @initEvents

      @$.drawLayers()

    initEvents: ->
      leftDown = false
      middleDown = false
      @$.on 'mousemove', (e) =>
        x = Math.round (e.pageX - @$.offset().left)
        y = Math.round (e.pageY - @$.offset().top)
        switch @modes[0]
          when 'zoom'
            @body.eye.rho = 400 + 200 * y / @h
            @body.eye.zoom = 200 + 200 * Math.max 2 * x / @w, 0.1
          when 'move'
            @body.eye.offsetX = x - @$.width()/2
            @body.eye.offsetY = y - @$.height()/2
          when 'rotate'
            @body.eye.theta = Math.PI * x / @w
            @body.eye.phi   = 2*Math.PI * y / @h
        @$.drawLayers()
      @$.on 'click', (e) =>
        @modes = rotate(@modes)

   class CanvasOrtho extends Canvas
    transform: -> @body.viewTransform()

    initCoordinatesLayer: ->
      @$.addLayer \
          type: 'function',
          name: 'coords',
          fn: (ctx) =>
            ctx.globalAlpha = .6
            ctx.font = 'normal 1em Arial'
            ctx.textAlign = 'right'
            ctx.textBaseline = 'top'
            ctx.fillStyle = 'black'
            ctx.strokeStyle = 'black'
            ctx.fillText \
                "
                #{@modes[0]}
                θ = #{@body.eye.theta.toFixed(3)}
                φ = #{@body.eye.phi.toFixed(3)}",
                @w - 8,
                8

  ortho = new CanvasOrtho octahedron, 'ortho-canvas'
  orthoCube = new CanvasOrtho cube, 'ortho-cube-canvas'

  class CanvasPersp extends Canvas
    transform: -> @body.screenTransform()

    initCoordinatesLayer: ->
      @$.addLayer \
          type: 'function',
          name: 'coords',
          fn: (ctx) =>
            ctx.globalAlpha = .6
            ctx.font = 'normal 1em Arial'
            ctx.textAlign = 'right'
            ctx.textBaseline = 'top'
            ctx.fillStyle = 'black'
            ctx.strokeStyle = 'black'
            ctx.fillText \
                "
                #{@modes[0]}
                θ = #{@body.eye.theta.toFixed(3)}
                φ = #{@body.eye.phi.toFixed(3)}
                ρ = #{@body.eye.rho.toFixed(3)}
                d = #{@body.eye.zoom.toFixed(3)}",
                @w - 8,
                8

  perspective = new CanvasPersp octahedron, 'persp-canvas'
  perspectiveCube = new CanvasPersp cube, 'persp-cube-canvas'

$ main
