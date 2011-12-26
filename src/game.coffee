WIDTH = 640
HEIGHT = 480
DEBUG = true


class Game
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

  run: ->
    webglmc.resmgr.wait =>
      this.initGame()
      this.mainloop()

  mainloop: ->
    webglmc.engine.mainloop (dt) =>
      this.updateGame dt
      this.render()

  updateGame: (dt) ->

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
