keyMapping =
  65:     'strafeLeft'    # A
  68:     'strafeRight'   # D
  87:     'moveForward'   # W
  83:     'moveBackward'  # S
  38:     'lookUp'        # Arrow Up
  40:     'lookDown'      # Arrow Down
  37:     'lookLeft'      # Arrow Left
  39:     'lookRight'     # Arrow Right
  69:     'putBlock'      # E
  81:     'removeBlock'   # Q



class Game
  constructor: ->
    @actions = {}
    for code, action of keyMapping
      @actions[action] = false

  initGame: ->
    {engine} = webglmc

    # Initialize a small new world
    @cam = new webglmc.Camera
    @cam.position = vec3.create([-20.0, 60.0, -20.0])
    @cam.lookAt vec3.create([-0.5, 20.0, 0.5])

    @world = new webglmc.World
    @currentSelection = null

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
      if @currentSelection
        s = @currentSelection
        if action == 'removeBlock'
          this.removeBlock s.x, s.y, s.z
        else if action == 'putBlock'
          this.putBlock s.x, s.y, s.z, s.hit.side
      false

  onKeyUp: (event) ->
    action = keyMapping[event.which]
    if action?
      @actions[action] = false
      false

  removeBlock: (x, y, z) ->
    @world.setBlock x, y, z, 0

  putBlock: (x, y, z, side) ->
    switch side
      when 'top' then y += 1
      when 'bottom' then y -= 1
      when 'right' then x += 1
      when 'left' then x -= 1
      when 'near' then z += 1
      when 'far' then z -= 1
    @world.setBlock x, y, z, webglmc.BLOCK_TYPES.stone

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

    @cam.apply()
    @world.requestMissingChunks()
    @currentSelection = @world.pickCloseBlockAtScreenCenter()

  render: ->
    {gl} = webglmc.engine

    gl.clearColor 0.0, 0.0, 0.0, 1.0
    gl.clear gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT

    @world.draw()
    if @currentSelection
      s = @currentSelection
      @world.drawBlockHighlight s.x, s.y, s.z, s.hit.side


initEngineAndGame = (selector, debug) ->
  canvas = $(selector)[0]

  webglmc.debugPanel = new webglmc.DebugPanel()
  webglmc.engine = new webglmc.Engine(canvas, debug)
  webglmc.resmgr = webglmc.makeDefaultResourceManager()
  webglmc.game = new Game
  webglmc.game.run()


$(document).ready ->
  debug = webglmc.getRuntimeParameter('debug') == '1'
  initEngineAndGame '#viewport', debug


public = self.webglmc ?= {}
public.game = null
public.debugPanel = null
public.resmgr = null
public.engine = null
