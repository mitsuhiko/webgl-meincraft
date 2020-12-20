class AABB
  constructor: (vec1 = vec3.create(), vec2 = vec3.create()) ->
    @vec1 = vec1
    @vec2 = vec2

  getDimension: ->
    vec3.subtract @vec2, @vec1, vec3.create()


publicInterface = self.webglmc ?= {}
publicInterface.AABB = AABB
