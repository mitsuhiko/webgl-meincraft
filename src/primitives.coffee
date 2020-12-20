CUBE_INDEXES = [0, 1, 2, 0, 2, 3]
CUBE_VERTICES =
  near:
    positions: [
      [-1.0, -1.0,  1.0]
      [ 1.0, -1.0,  1.0]
      [ 1.0,  1.0,  1.0]
      [-1.0,  1.0,  1.0]
    ]
    normals: [0, 0, 1]
    texcoords: [
      [0.0,  0.0]
      [1.0,  0.0]
      [1.0,  1.0]
      [0.0,  1.0]
    ]
  far:
    positions: [
      [-1.0, -1.0, -1.0]
      [-1.0,  1.0, -1.0]
      [ 1.0,  1.0, -1.0]
      [ 1.0, -1.0, -1.0]
    ]
    normals: [0, 0, -1]
    texcoords: [
      [0.0,  0.0]
      [1.0,  0.0]
      [1.0,  1.0]
      [0.0,  1.0]
    ]
  top:
    positions: [
      [-1.0,  1.0, -1.0]
      [-1.0,  1.0,  1.0]
      [ 1.0,  1.0,  1.0]
      [ 1.0,  1.0, -1.0]
    ]
    normals: [0, 1, 0]
    texcoords: [
      [0.0,  0.0]
      [1.0,  0.0]
      [1.0,  1.0]
      [0.0,  1.0]
    ]
  bottom:
    positions: [
      [-1.0, -1.0, -1.0]
      [ 1.0, -1.0, -1.0]
      [ 1.0, -1.0,  1.0]
      [-1.0, -1.0,  1.0]
    ]
    normals: [0, -1, 0]
    texcoords: [
      [0.0,  0.0]
      [1.0,  0.0]
      [1.0,  1.0]
      [0.0,  1.0]
    ]
  right:
    positions: [
      [ 1.0, -1.0, -1.0]
      [ 1.0,  1.0, -1.0]
      [ 1.0,  1.0,  1.0]
      [ 1.0, -1.0,  1.0]
    ]
    normals: [1, 0, 0]
    texcoords: [
      [0.0,  0.0]
      [1.0,  0.0]
      [1.0,  1.0]
      [0.0,  1.0]
    ]
  left:
    positions: [
      [-1.0, -1.0, -1.0]
      [-1.0, -1.0,  1.0]
      [-1.0,  1.0,  1.0]
      [-1.0,  1.0, -1.0]
    ]
    normals: [-1, 0, 0]
    texcoords: [
      [0.0,  0.0]
      [1.0,  0.0]
      [1.0,  1.0]
      [0.0,  1.0]
    ]


class CubeMaker
  constructor: (defaultSize = 1, useIndexes = null) ->
    @defaultSize = defaultSize
    @useIndexes = useIndexes ? webglmc.getRuntimeParameter('useIndexes') == '1'
    @vertexCount = 0
    @positions = []
    @normals = []
    @texcoords = []
    @indexes = []

  addAllSides: (x, y, z, texture = null, size = @defaultSize) ->
    addSide 'left', x, y, z, texture, size
    addSide 'right', x, y, z, texture, size
    addSide 'top', x, y, z, texture, size
    addSide 'bottom', x, y, z, texture, size
    addSide 'left', x, y, z, texture, size
    addSide 'right', x, y, z, texture, size

  addSide: (side, x, y, z, texture = null, size = @defaultSize) ->
    halfsize = size / 2
    iterable = if !@useIndexes then CUBE_INDEXES else [0..3]
    def = CUBE_VERTICES[side]

    if !texture
      if @texcoords.length > 0
        throw "Attempted to add null texture to cube with texcoords"
    else
      facX = texture.width / texture.storedWidth
      facY = texture.height / texture.storedHeight
      offX = texture.offsetX / texture.storedWidth
      offY = texture.offsetY / texture.storedHeight

    [nx, ny, nz] = def.normals
    for i in iterable
      [cx, cy, cz] = def.positions[i]
      @positions.push x + (cx * halfsize)
      @positions.push y + (cy * halfsize)
      @positions.push z + (cz * halfsize)
      @normals.push nx, ny, nz

      if texture
        [tx, ty] = def.texcoords[i]
        @texcoords.push tx * facX + offX
        @texcoords.push ty * facY + offY

    if @useIndexes
      for index in CUBE_INDEXES
        @indexes.push @vertexCount + index
      @vertexCount += 4
    else
      @vertexCount += 6

  makeVBO: (upload = true) ->
    count = if @useIndexes then @indexes.length else @vertexCount
    vbo = new webglmc.VertexBufferObject 'TRIANGLES', count
    vbo.addBuffer 'aVertexPosition', 3, @positions
    vbo.addBuffer 'aVertexNormal', 3, @normals
    vbo.addBuffer 'aTextureCoord', 2, @texcoords
    if @useIndexes
      vbo.addIndexBuffer @indexes
    if upload
      vbo.upload()
    vbo


publicInterface = self.webglmc ?= {}
publicInterface.CubeMaker = CubeMaker
