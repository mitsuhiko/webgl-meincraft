class RaycastHit

  constructor: (distance, side = null) ->
    @distance = distance
    @side = side


class Ray
  constructor: (origin, direction) ->
    @origin = origin
    @direction = vec3.normalize direction

  this.betweenTwoPoints = (origin, otherPoint) ->
    direction = vec3.subtract origin, otherPoint, vec3.create()
    return new Ray origin, direction

  this.fromScreenSpaceNearToFar = (x, y) ->
    {engine} = webglmc
    ivp = engine.getInverseViewProjection()
    if !ivp
      return null

    vec = vec4.create()
    vec[0] = x * 2.0 / engine.width - 1.0
    vec[1] = (engine.height - y) * 2.0 / engine.height - 1.0
    vec[2] = 0.0
    vec[3] = 1.0
    origin = mat4.multiplyVec4 ivp, vec, vec4.create()

    if !origin[3]
      return null
    new Ray vec4.toVec3(origin), engine.getForward()

  intersectsAABB: (aabb, checkInside = true) ->
    {vec1, vec2} = aabb
    lowt = 0.0
    didHit = false
    sideHit = null

    if checkInside &&
       @origin[0] > vec1[0] && @origin[1] > vec1[1] && @origin[0] > vec1[2] &&
       @origin[0] < vec2[0] && @origin[1] < vec2[1] && @origin[2] < vec2[2]
        return new RaycastHit 0, 'inside'

    checkHit = (vec, s, sa, sb, side) =>
      if vec == vec1
        cond = @origin[s] <= vec[s] && @direction[s] > 0.0
      else
        cond = @origin[s] >= vec[s] && @direction[s] < 0.0
      if !cond
        return

      t = (vec[s] - @origin[s]) / @direction[s]
      if t >= 0.0
        hit = vec3.scale @direction, t, vec3.create()
        hit = vec3.add hit, @origin
        if (!didHit || t < lowt) &&
           hit[sa] >= vec1[sa] && hit[sa] <= vec2[sa] &&
           hit[sb] >= vec1[sb] && hit[sb] <= vec2[sb]
          didHit = true
          lowt = t
          sideHit = side

    checkHit vec1, 0, 1, 2, 'left'
    checkHit vec2, 0, 1, 2, 'right'
    checkHit vec1, 1, 0, 2, 'bottom'
    checkHit vec2, 1, 0, 2, 'top'
    checkHit vec1, 2, 0, 1, 'far'
    checkHit vec2, 2, 0, 1, 'near'

    if didHit then new RaycastHit(lowt, sideHit) else null


public = self.webglmc ?= {}
public.Ray = Ray
public.RaycastHit = RaycastHit
