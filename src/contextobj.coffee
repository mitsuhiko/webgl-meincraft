stacks = {}


class ContextObject
  @stack = null

  this.withStack = (name) ->
    @stack = stacks[name] ?= []

  this.hasStack = ->
    @stack != null

  bind: ->

  unbind: ->

  destroy: ->

  push: ->
    stack = @constructor.stack
    stack.push this
    this.bind()

  pop: ->
    this.constructor.pop()

  executeWithContext: (callback) ->
    return callback() if this == @constructor.top()
    this.push()
    try
      callback()
    finally
      this.pop()

  this.top = ->
    @stack[@stack.length - 1]

  this.pop = ->
    current = @stack.pop()
    current.unbind()
    old = this.top()
    if old
      old.bind()


class GLFlagContextObject extends ContextObject
  @withStack 'gl_flags'

  constructor: (funcs) ->
    super()
    this.bind = funcs.bind
    this.unbind = funcs.unbind


withContext = (objects, cb) ->
  idx = 0
  while idx < objects.length
    objects[idx++].push()
  try
    cb()
  finally
    while idx > 0
      objects[--idx].pop()


disabledDepthTest = new GLFlagContextObject
  bind: ->
    {gl} = webglmc.engine
    gl.disable gl.DEPTH_TEST
  unbind: ->
    {gl} = webglmc.engine
    gl.enable gl.DEPTH_TEST


publicInterface = self.webglmc ?= {}
publicInterface.ContextObject = ContextObject
publicInterface.getContextObjectStacks = -> stacks
publicInterface.withContext = withContext
publicInterface.disabledDepthTest = disabledDepthTest
