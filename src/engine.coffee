requestAnimationFrame = (
  window.requestAnimationFrame       ||
  window.webkitRequestAnimationFrame ||
  window.mozRequestAnimationFrame    ||
  window.oRequestAnimationFrame      ||
  window.msRequestAnimationFrame)


makeGLContext = (canvas, debug, options) ->
  try
    ctx = canvas.getContext('webgl', options) ||
      canvas.getContext('experimental-webgl', options)
  catch e
    return null
  if debug
    ctx = WebGLDebugUtils.makeDebugContext ctx
  ctx


class Engine
  constructor: (canvas, debug = false) ->
    @debug = debug
    @canvas = canvas
    @gl = makeGLContext canvas, @debug, antialias: true
    @aspect = @canvas.width / @canvas.height
    @currentShader = null

    @modelView = new MatrixStack
    @projection = new MatrixStack
    @_frustum = null
    @_mvp = null
    @_deviceUniformDirty = false

    console.debug 'Render canvas =', @canvas
    console.debug 'WebGL context =', @gl

  markMVPDirty: ->
    @_deviceUniformDirty = true
    @_frustum = null
    @_mvp = null

  getModelViewProjection: ->
    @_mvp ?= mat4.multiply @modelView.top, @projection.top, mat4.create()

  getCurrentFrustum: ->
    @_frustum ?= new webglmc.Frustum this.getModelViewProjection()

  getCameraPos: ->
    mvp = this.getModelViewProjection()
    vec3.create [mvp[12], mvp[13], mvp[14]]

  flushUniforms: ->
    if !@_deviceUniformDirty
      return

    loc = @currentShader.getUniformLocation "uModelViewMatrix"
    @gl.uniformMatrix4fv loc, false, @modelView.top if loc
    loc = @currentShader.getUniformLocation "uProjectionMatrix"
    @gl.uniformMatrix4fv loc, false, @projection.top if loc

    @_deviceUniformDirty = false

  mainloop: (iterate) ->
    lastTimestamp = Date.now()
    step = (timestamp) ->
      iterate (timestamp - lastTimestamp) / 1000
      lastTimestamp = timestamp
      requestAnimationFrame step
    requestAnimationFrame step


class MatrixStack
  constructor: ->
    @top = mat4.identity()
    @stack = []

  set: (value) ->
    @top = value
    webglmc.engine.markMVPDirty()

  identity: ->
    this.set mat4.identity()

  multiply: (mat) ->
    mat4.multiply @top, mat
    webglmc.engine.markMVPDirty()

  translate: (vector) ->
    mat4.translate @top, vector
    webglmc.engine.markMVPDirty()

  rotate: (angle, axis) ->
    mat4.rotate @top, angle, axis
    webglmc.engine.markMVPDirty()

  scale: (vector) ->
    mat4.scale @top, vector
    webglmc.engine.markMVPDirty()

  push: (mat = null) ->
    if !mat
      @stack.push mat4.create mat
      @top = mat4.create mat
    else
      @stack.push mat4.create mat
    null

  pop: ->
    @top = @stack.pop()
    webglmc.engine.markMVPDirty()


public = window.webglmc ?= {}
public.Engine = Engine
