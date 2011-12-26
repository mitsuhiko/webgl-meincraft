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
    @throbber = $('<img src=assets/throbber.gif id=throbber>')
      .appendTo('body')
      .hide()
    @throbberLevel = 0

    # To force antialiasing pass antialias: true as options
    @gl = makeGLContext canvas, @debug
    @aspect = @canvas.width / @canvas.height
    @currentShader = null

    @gl.enable @gl.DEPTH_TEST
    @gl.depthFunc @gl.LEQUAL
    @gl.enable @gl.CULL_FACE
    @gl.cullFace @gl.BACK

    @model = new MatrixStack
    @view = new MatrixStack
    @projection = new MatrixStack
    this.markMVPDirty()

    console.debug 'Render canvas =', @canvas
    console.debug 'WebGL context =', @gl

  pushThrobber: ->
    if @throbberLevel++ == 0
      @throbber.fadeIn()

  popThrobber: ->
    if --@throbberLevel == 0
      @throbber.fadeOut()

  markMVPDirty: ->
    @_deviceUniformDirty = true
    @_frustum = null
    @_mvp = null
    @_modelView = null
    @_normal = null
    @_iview = null

  getModelView: ->
    @_modelView ?= mat4.multiply @view.top, @model.top

  getModelViewProjection: ->
    @_mvp ?= mat4.multiply @projection.top, this.getModelView(), mat4.create()

  getNormal: ->
    @_normal = mat4.toInverseMat3 @model.top

  getCurrentFrustum: ->
    @_frustum ?= new webglmc.Frustum this.getModelViewProjection()

  getInverseView: ->
    @_iview ?= mat4.inverse @view.top, mat4.create()

  getCameraPos: ->
    iview = this.getInverseView()
    vec3.create [iview[12], iview[13], iview[14]]

  flushUniforms: ->
    if !@_deviceUniformDirty
      return

    loc = @currentShader.getUniformLocation "uModelMatrix"
    @gl.uniformMatrix4fv loc, false, @model.top if loc
    loc = @currentShader.getUniformLocation "uViewMatrix"
    @gl.uniformMatrix4fv loc, false, @view.top if loc
    loc = @currentShader.getUniformLocation "uModelViewMatrix"
    @gl.uniformMatrix4fv loc, false, this.getModelView() if loc
    loc = @currentShader.getUniformLocation "uProjectionMatrix"
    @gl.uniformMatrix4fv loc, false, @projection.top if loc
    loc = @currentShader.getUniformLocation "uModelViewProjectionMatrix"
    @gl.uniformMatrix4fv loc, false, this.getModelViewProjection() if loc
    loc = @currentShader.getUniformLocation "uNormalMatrix"
    @gl.uniformMatrix3fv loc, false, this.getNormal() if loc

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


public = self.webglmc ?= {}
public.Engine = Engine
