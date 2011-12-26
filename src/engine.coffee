requestAnimationFrame = (
  window.requestAnimationFrame       ||
  window.webkitRequestAnimationFrame ||
  window.mozRequestAnimationFrame    ||
  window.oRequestAnimationFrame      ||
  window.msRequestAnimationFrame)


makeGLContext = (canvas, debug) ->
  try
    ctx = canvas.getContext('webgl') || canvas.getContext('experimental-webgl')
  catch e
    return null
  if debug
    ctx = WebGLDebugUtils.makeDebugContext ctx
  ctx


class Engine
  constructor: (canvas, debug = false) ->
    @debug = debug
    @canvas = canvas
    @gl = makeGLContext canvas, @debug
    @matrixState = new MatrixState
    @aspect = @canvas.width / @canvas.height
    @modelView = @matrixState.add "uModelViewMatrix"
    @projection = @matrixState.add "uProjectionMatrix"
    @currentShader = null

    console.debug 'Render canvas =', @canvas
    console.debug 'WebGL context =', @gl

  getCameraPos : ->
    mvp = @modelView.top
    vec3.create mvp[12], mvp[13], mvp[14]

  getCurrentFrustum : ->
    new webglmc.Frustum mat4.multiply(webglmc.engine.projection.top,
                                      webglmc.engine.modelView.top,
                                      mat4.create())

  flushUniforms: (force = false) ->
    if !(@matrixState.dirty || force)
      return
    {engine} = webglmc
    for remoteName, matrix of @matrixState.mapping
      loc = engine.currentShader.getUniformLocation remoteName
      if loc < 0
        continue
      engine.gl.uniformMatrix4fv loc, false, matrix.top
    @matrixState.dirty = false

  mainloop: (iterate) ->
    lastTimestamp = Date.now()
    step = (timestamp) ->
      iterate (timestamp - lastTimestamp) / 1000
      lastTimestamp = timestamp
      requestAnimationFrame step
    requestAnimationFrame step


class MatrixStack
  constructor: (matrixState) ->
    @matrixState = matrixState
    @top = mat4.identity()
    @stack = []

  set: (value) ->
    @top = value
    @matrixState.dirty = true

  identity: ->
    this.set mat4.identity()

  multiply: (mat) ->
    mat4.multiply @top, mat
    @matrixState.dirty = true

  translate: (vector) ->
    mat4.translate @top, vector
    @matrixState.dirty = true

  rotate: (angle, axis) ->
    mat4.rotate @top, angle, axis
    @matrixState.dirty = true

  scale: (vector) ->
    mat4.scale @top, vector
    @matrixState.dirty = true

  push: (mat = null) ->
    if !mat
      @stack.push mat4.create mat
      @top = mat4.create mat
    else
      @stack.push mat4.create mat
    null

  pop: ->
    @top = @stack.pop()
    @matrixState.dirty = true


class MatrixState
  constructor: ->
    @dirty = false
    @mapping = {}

  add: (name) ->
    @mapping[name] = new MatrixStack this


public = window.webglmc ?= {}
public.Engine = Engine
