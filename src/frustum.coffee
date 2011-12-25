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
    @modelView = @matrixState.add "uModelViewMatrix"
    @projection = @matrixState.add "uProjectionMatrix"
    @currentShader = null

    console.debug 'Render canvas =', @canvas
    console.debug 'WebGL context =', @gl

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


class Frustum
  constructor: (mvp) ->
    @planes = (vec4.create() for x in [1..6])

    # left plane
    vec = @planes[0]
    vec[0] = mvp[3] + mvp[0]
    vec[1] = mvp[7] + mvp[4]
    vec[2] = mvp[11] + mvp[8]
    vec[3] = mvp[15] + mvp[12]
    vec4.normalize vec

    # right plane
    vec = @planes[1]
    vec[0] = mvp[3] - mvp[0]
    vec[1] = mvp[7] - mvp[4]
    vec[2] = mvp[11] - mvp[8]
    vec[3] = mvp[15] - mvp[12]
    vec4.normalize vec

    # bottom plane
    vec = @planes[2]
    vec[0] = mvp[3] + mvp[1]
    vec[1] = mvp[7] + mvp[5]
    vec[2] = mvp[11] + mvp[9]
    vec[3] = mvp[15] + mvp[13]
    vec4.normalize vec

    # top plane
    vec = @planes[3]
    vec[0] = mvp[3] - mvp[1]
    vec[1] = mvp[7] - mvp[5]
    vec[2] = mvp[11] - mvp[9]
    vec[3] = mvp[15] - mvp[13]
    vec4.normalize vec

    # near plane
    vec = @planes[4]
    vec[0] = mvp[3] + mvp[2]
    vec[1] = mvp[7] + mvp[6]
    vec[2] = mvp[11] + mvp[10]
    vec[3] = mvp[15] + mvp[14]
    vec4.normalize vec

    # far plane
    vec = @planes[5]
    vec[0] = mvp[3] - mvp[2]
    vec[1] = mvp[7] - mvp[6]
    vec[2] = mvp[11] - mvp[10]
    vec[3] = mvp[15] - mvp[14]
    vec4.normalize vec

  planeTest: (plane, vec1, vec2) ->
    p1 = vec1[0] * plane[0]
    p2 = vec1[1] * plane[1]
    p3 = vec1[2] * plane[2]
    d1 = vec2[0] * plane[0]
    d2 = vec2[1] * plane[1]
    d3 = vec2[2] * plane[2]
    w = plane[3]
    points = 0

    if p1 + p2 + p3 + w > 0 then points++
    if p1 + p2 + d3 + w > 0 then points++
    if p1 + d2 + p3 + w > 0 then points++
    if p1 + d2 + d3 + w > 0 then points++
    if d1 + p2 + p3 + w > 0 then points++
    if d1 + p2 + d3 + w > 0 then points++
    if d1 + d2 + p3 + w > 0 then points++
    if d1 + d2 + d3 + w > 0 then points++

    points

  testAABB: (vec1, vec2) ->
    pointsVisible = 0

    for plane in @planes
      if (rv = this.planeTest(plane, vec1, vec2)) == 0
        return -1
      pointsVisible += rv

    if pointsVisible == 48 then 1 else 0


public = window.webglmc ?= {}
public.Frustum = Frustum
