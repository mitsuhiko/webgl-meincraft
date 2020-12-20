makeQuadVBO = (texture) ->
  vbo = new webglmc.VertexBufferObject 'TRIANGLES', 6
  vbo.addBuffer 'aVertexPosition', 3, [
    1, 1, 0, -1, 1, 0, -1, -1, 0,
    1, 1, 0, -1, -1, 0, 1, -1, 0
  ]
  vbo.addBuffer 'aTextureCoord', 2, texture.scaleCoords [
    1, 1, 0, 1, 0, 0,
    1, 1, 0, 0, 1, 0
  ]
  vbo.upload()
  vbo


class Processor extends webglmc.ContextObject
  @withStack 'processor'

  constructor: (shader, fbo = null) ->
    super()
    @shader = shader
    if fbo
      @fbo = fbo
      @fboManaged = false
    else
      @fbo = new webglmc.FrameBufferObject
      @fboManaged = true
    @vbo = makeQuadVBO @fbo.texture

  destroy: ->
    @fbo.destroy() if @fboManaged
    @vbo.destroy()

  bind: ->
    @fbo.push()

  unbind: ->
    @fbo.pop()
    this.draw()

  draw: ->
    {gl} = webglmc.engine
    @shader.push()
    gl.clearColor 1.0, 1.0, 1.0, 1.0
    gl.clear gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT
    @fbo.texture.push()
    @vbo.draw()
    @fbo.texture.pop()
    @shader.pop()


publicInterface = self.webglmc ?= {}
publicInterface.Processor = Processor
