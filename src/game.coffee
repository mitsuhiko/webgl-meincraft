WIDTH = 640
HEIGHT = 480
DEBUG = true


class Game
  initGame: ->
    {engine} = webglmc

    # Default perspective matrix
    aspect = engine.canvas.width / engine.canvas.height
    engine.projection.set mat4.perspective(45.0, aspect, 0.1, 1000.0)

    # Initialize the test world
    blockTypes = webglmc.BLOCK_TYPES
    @world = new webglmc.World
    @world.setBlock 0, 0, -2, blockTypes.grass
    @world.setBlock 0, 0, -1, blockTypes.grass
    @world.setBlock 0, 0, 0, blockTypes.stone
    @world.setBlock 0, 0, 1, blockTypes.grass
    @world.setBlock 0, 0, 2, blockTypes.grass

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

    modelView.identity()
    modelView.translate([0.0, -3.0, -13.0])
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
