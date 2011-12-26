WIDTH = 640
HEIGHT = 480
DEBUG = true

keyMapping =
  65:     'strafeLeft'    # A
  68:     'strafeRight'   # D
  87:     'moveForward'   # W
  83:     'moveBackward'  # S
  38:     'lookUp'        # Arrow Up
  40:     'lookDown'      # Arrow Down
  37:     'lookLeft'      # Arrow Left
  39:     'lookRight'     # Arrow Right


class Game
  constructor: ->
    @actions = {}
    for code, action of keyMapping
      @actions[action] = false

  initGame: ->
    {engine} = webglmc

    # Initialize a small new world
    @cam = new webglmc.Camera
    @cam.position = vec3.create([0.0, 40.0, -60.0])
    @cam.lookAtOrigin()

    @world = new webglmc.World
    worldGen = new webglmc.WorldGenerator @world, 42
    for x in [-32..32]
      for z in [-32..32]
        worldGen.generateChunkColumn x, z

  initEventHandlers: ->
    $('body')
      .bind 'keydown', (event) =>
        this.onKeyDown event
      .bind 'keyup', (event) =>
        this.onKeyUp event

  onKeyDown: (event) ->
    action = keyMapping[event.which]
    if action?
      @actions[action] = true

  onKeyUp: (event) ->
    action = keyMapping[event.which]
    if action?
      @actions[action] = false

  run: ->
    webglmc.resmgr.wait =>
      this.initGame()
      this.initEventHandlers()
      this.mainloop()

  mainloop: ->
    webglmc.engine.mainloop (dt) =>
      this.updateGame dt
      this.render()

  updateGame: (dt) ->
    if @actions.moveForward
      @cam.moveForward dt * 10
    if @actions.moveBackward
      @cam.moveBackward dt * 10
    if @actions.strafeLeft
      @cam.strafeLeft dt * 10
    if @actions.strafeRight
      @cam.strafeRight dt * 10
    if @actions.lookUp
      @cam.rotateScreenY -dt * 0.5
    if @actions.lookDown
      @cam.rotateScreenY dt * 0.5
    if @actions.lookLeft
      @cam.rotateScreenX -dt * 0.5
    if @actions.lookRight
      @cam.rotateScreenX dt * 0.5

  render: ->
    {gl, modelView} = webglmc.engine

    gl.clearColor 0.0, 0.0, 0.0, 1.0
    gl.enable gl.DEPTH_TEST
    gl.depthFunc gl.LEQUAL
    gl.clear gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT

    @cam.apply()
    @world.draw()


initEngineAndGame = (width, height, debug) ->
  canvas = $('<canvas></canvas>')
    .attr('width', WIDTH)
    .attr('height', HEIGHT)
    .appendTo('body')[0]

  webglmc.engine = new webglmc.Engine(canvas, DEBUG)
  webglmc.resmgr = webglmc.makeDefaultResourceManager()
  webglmc.game = new Game
  webglmc.game.run()


$(document).ready ->
  initEngineAndGame(WIDTH, HEIGHT, DEBUG)


public = window.webglmc ?= {}
public.game = null
public.resmgr = null
public.engine = null
