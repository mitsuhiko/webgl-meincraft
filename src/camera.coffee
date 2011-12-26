class Camera
  constructor: ->
    @position = vec3.create()
    @forward = vec3.create([0, 0, -1.0])
    @up = vec3.create([0.0, 1.0, 0.0])
    @fov = 45.0
    @near = 0.1
    @far = 200.0

  lookAt: (vec) ->
    vec3.subtract vec, @position, @forward
    vec3.normalize @forward

  lookAtOrigin: ->
    this.lookAt [0.0, 0.0, 0.0]

  rotateScreenX: (angle) ->
    rotmat = mat4.identity()
    mat4.rotate rotmat, -angle, @up
    mat4.multiplyVec3 rotmat, @forward
    vec3.normalize @forward

  rotateScreenY: (angle) ->
    cross = vec3.create()
    rotmat = mat4.identity()
    vec3.cross @up, @forward, cross
    mat4.rotate rotmat, angle, cross
    mat4.multiplyVec3 rotmat, @forward
    vec3.normalize @forward

  rotateScreen: (relx, rely) ->
    this.rotateScreenX relx if relx
    this.rotateScreenY rely if rely

  moveForward: (delta) ->
    vec = vec3.create()
    vec3.scale @forward, delta, vec
    vec3.add @position, vec

  moveBackward: (delta) ->
    vec = vec3.create()
    vec3.scale @forward, delta, vec
    vec3.subtract @position, vec

  strafeLeft: (delta) ->
    vec = vec3.create()
    cross = vec3.create()
    vec3.cross @up, @forward, cross
    vec3.normalize cross
    vec3.scale cross, delta, vec
    vec3.add @position, vec

  strafeRight: (delta) ->
    vec = vec3.create()
    cross = vec3.create()
    vec3.cross @up, @forward, cross
    vec3.normalize cross
    vec3.scale cross, delta, vec
    vec3.subtract @position, vec

  apply: ->
    {engine} = webglmc
    mv = mat4.create()
    ref = vec3.create @position
    vec3.add ref, @forward
    mat4.lookAt @position, ref, @up, mv
    engine.projection.set mat4.perspective(@fov, engine.aspect, @near, @far)
    engine.view.set mv


public = self.webglmc ?= {}
public.Camera = Camera
