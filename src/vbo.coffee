class Buffer
  isOnDevice: false
  constructor: (name, size) ->
    gl = webglmc.engine.gl
    @name = name
    @size = size
    @isIndex = name == '__index__'
    @type = if @isIndex then gl.ELEMENT_ARRAY_BUFFER else gl.ARRAY_BUFFER


class LocalBuffer extends Buffer
  isOnDevice: false
  constructor: (name, size, vertices) ->
    super name, size
    if @isIndex
      vertices = new Uint16Array vertices
    else
      vertices = new Float32Array vertices
    @vertices = vertices


class RemoteBuffer extends Buffer
  isOnDevice: true
  constructor: (name, size, id) ->
    super name, size
    @id = id


class VertexBufferObject
  constructor: (drawMode, count) ->
    @drawMode = drawMode
    @count = count
    @buffers = {}

  addIndexBuffer: (vertices) ->
    this.addBuffer '__index__', 1, vertices

  addBuffer: (name, size, vertices) ->
    @buffers[name] = buffer = new LocalBuffer name, size, vertices

  upload: ->
    gl = webglmc.engine.gl
    for name, buffer of @buffers
      if buffer.isOnDevice
        continue
      id = gl.createBuffer()
      gl.bindBuffer buffer.type, id
      gl.bufferData buffer.type, buffer.vertices, gl.STATIC_DRAW
      @buffers[name] = new RemoteBuffer name, buffer.size, id

  destroy: ->
    gl = webglmc.engine.gl
    for name, buffer of @buffers
      if buffer.isOnDevice
        gl.deleteBuffer buffer.id
    @buffers = {}
    @count = 0

  draw: ->
    # XXX: support drawing of stuff not yet on the device
    # XXX: code leaves the location enabled for vertex attributes
    {engine} = webglmc
    {gl} = engine

    drawElements = false
    engine.flushUniforms()

    for name, buffer of @buffers
      gl.bindBuffer buffer.type, buffer.id
      if buffer.isIndex
        drawElements = true
        continue

      loc = engine.currentShader.getAttribLocation name
      if loc < 0
        continue

      gl.vertexAttribPointer loc, buffer.size, gl.FLOAT, false, 0, 0
      gl.enableVertexAttribArray loc

    drawMode = gl[@drawMode]
    if drawElements
      gl.drawElements drawMode, @count, gl.UNSIGNED_SHORT, 0
    else
      gl.drawArrays drawMode, 0, @count


public = self.webglmc ?= {}
public.VertexBufferObject = VertexBufferObject
