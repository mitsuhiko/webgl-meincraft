class Frustum
  constructor: ->
    @planes = (vec4.create() for x in [1..6])

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
      if (rv = this.planeTest plane, vec1, vec2) == 0
        return -1
      pointsVisible += rv

    if pointsVisible == 48 then 1 else 0


getCurrentFrustum = ->
  mvp = webglmc.engine.modelView.top
  frustum = new Frustum

  # left plane
  vec = frustum.planes[0]
  vec[0] = mvp[3] + mvp[0]
  vec[1] = mvp[7] + mvp[4]
  vec[2] = mvp[11] + mvp[8]
  vec[3] = mvp[15] + mvp[12]
  vec4.normalize vec

  # right plane
  vec = frustum.planes[1]
  vec[0] = mvp[3] - mvp[0]
  vec[1] = mvp[7] - mvp[4]
  vec[2] = mvp[11] - mvp[8]
  vec[3] = mvp[15] - mvp[12]
  vec4.normalize vec

  # bottom plane
  vec = frustum.planes[2]
  vec[0] = mvp[3] + mvp[1]
  vec[1] = mvp[7] + mvp[5]
  vec[2] = mvp[11] + mvp[9]
  vec[3] = mvp[15] + mvp[13]
  vec4.normalize vec

  # top plane
  vec = frustum.planes[3]
  vec[0] = mvp[3] - mvp[1]
  vec[1] = mvp[7] - mvp[5]
  vec[2] = mvp[11] - mvp[9]
  vec[3] = mvp[15] - mvp[13]
  vec4.normalize vec

  # near plane
  vec = frustum.planes[4]
  vec[0] = mvp[3] + mvp[2]
  vec[1] = mvp[7] + mvp[6]
  vec[2] = mvp[11] + mvp[10]
  vec[3] = mvp[15] + mvp[14]
  vec4.normalize vec

  # far plane
  vec = frustum.planes[5]
  vec[0] = mvp[3] - mvp[2]
  vec[1] = mvp[7] - mvp[6]
  vec[2] = mvp[11] - mvp[10]
  vec[3] = mvp[15] - mvp[14]
  vec4.normalize vec

  frustum


public = window.webglmc ?= {}
public.Frustum = Frustum
public.getCurrentFrustum = getCurrentFrustum
