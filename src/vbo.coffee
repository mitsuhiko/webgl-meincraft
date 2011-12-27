class Buffer
  constructor: (name, size) ->
    {gl} = webglmc.engine
    @name = name
    @size = size
    @isIndex = name == '__index__'
    @isSpecial = name[0] == '_'
    @type = if @isIndex then gl.ELEMENT_ARRAY_BUFFER else gl.ARRAY_BUFFER
    if @isIndex
      @elementType = gl.UNSIGNED_SHORT
      @elementSize = 2
    else
      @elementType = gl.FLOAT
      @elementSize = 4


class LocalBuffer extends Buffer
  isOnDevice: false
  isInterleavedBuffer: false
  constructor: (name, size, vertices) ->
    super name, size
    {gl} = webglmc.engine
    if @elementType == gl.UNSIGNED_SHORT
      @vertices = new Uint16Array vertices
    else
      @vertices = new Float32Array vertices


class RemoteBuffer extends Buffer
  isOnDevice: true
  constructor: (name, size, id) ->
    super name, size
    @id = id
    @stride = 0
    @offset = 0


class InterleavedRemoteBuffer extends RemoteBuffer
  isInterleavedBuffer: true
  constructor: (name, size, stride, offset) ->
    super name, size, null
    @stride = stride
    @offset = offset


class VertexBufferObject
  constructor: (drawMode, count, options = {}) ->
    @drawMode = webglmc.engine.gl[drawMode]
    @count = count
    @interleaved = options.interleaved ? true
    @buffers = {}
    @uploaded = false

  addIndexBuffer: (vertices) ->
    this.addBuffer '__index__', 1, vertices

  addBuffer: (name, size, vertices) ->
    @buffers[name] ?= new LocalBuffer name, size, vertices

  uploadInterleaved: ->
    {gl} = webglmc.engine
    stride = 0
    count = 0
    offsets = []

    for name, buffer of @buffers
      if buffer.isSpecial
        continue
      offsets.push [name, stride, buffer]
      stride += buffer.size
      if count == 0
        count = buffer.vertices.length / buffer.size

    vertices = new Float32Array count * stride
    for i in [0...count]
      dstOffset = stride * i
      for [name, bufferOffset, buffer] in offsets
        srcOffset = i * buffer.size
        for j in [0...buffer.size]
          vertices[dstOffset + bufferOffset + j] = buffer.vertices[srcOffset + j]

    id = gl.createBuffer()
    gl.bindBuffer gl.ARRAY_BUFFER, id
    gl.bufferData gl.ARRAY_BUFFER, vertices, gl.STATIC_DRAW
    @buffers.__interleaved__ = new RemoteBuffer '__interleaved__', buffer.size, id

    for [name, offset, buffer] in offsets
      @buffers[name] = new InterleavedRemoteBuffer name, buffer.size,
        stride * buffer.elementSize, offset * buffer.elementSize

  uploadSeparateBuffers: ->
    {gl} = webglmc.engine
    for name, buffer of @buffers
      if buffer.isInterleavedBuffer || buffer.isOnDevice
        continue
      bufferType = buffer.type
      id = gl.createBuffer()
      gl.bindBuffer bufferType, id
      gl.bufferData bufferType, buffer.vertices, gl.STATIC_DRAW
      @buffers[name] = new RemoteBuffer name, buffer.size, id

  upload: ->
    if !@uploaded
      if @interleaved
        this.uploadInterleaved()
      this.uploadSeparateBuffers()

  destroy: ->
    gl = webglmc.engine.gl
    for name, buffer of @buffers
      if buffer.isOnDevice && buffer.id?
        gl.deleteBuffer buffer.id
    @buffers = {}
    @count = 0

  draw: ->
    if !@count then return

    {engine} = webglmc
    {gl} = engine
    drawElements = @buffers.__index__?

    engine.flushUniforms()

    if buffer = @buffers.__interleaved__
      gl.bindBuffer gl.ARRAY_BUFFER, buffer.id

    for name, buffer of @buffers
      if buffer.isSpecial
        continue
      if buffer.id != null
        gl.bindBuffer gl.ARRAY_BUFFER, buffer.id

      loc = engine.currentShader.getAttribLocation name
      if loc >= 0
        gl.vertexAttribPointer loc, buffer.size, buffer.elementType,
          false, buffer.stride, buffer.offset
        gl.enableVertexAttribArray loc

    if drawElements
      gl.bindBuffer gl.ELEMENT_ARRAY_BUFFER, @buffers.__index__.id
      gl.drawElements @drawMode, @count, gl.UNSIGNED_SHORT, 0
    else
      gl.drawArrays @drawMode, 0, @count


public = self.webglmc ?= {}
public.VertexBufferObject = VertexBufferObject
