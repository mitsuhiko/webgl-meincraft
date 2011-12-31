class AABB
  constructor: (vec1 = vec3.create(), vec2 = vec3.create()) ->
    @vec1 = vec1
    @vec2 = vec2


public = self.webglmc ?= {}
public.AABB = AABB
