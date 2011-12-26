ChunkArray = Uint8Array

CUBE_SIZE = 1.0
VIEW_DISTANCE = 4
BLOCK_TYPES =
  air:          0
  grass:        1
  stone:        2
  granite:      3


parseKey = (key) ->
  [x, y, z] = key.split('|')
  [+x, +y, +z]

div = (x, y) ->
  Math.floor x / y

mod = (x, y) ->
  (x % y + y) % y

makeBlockAtlas = ->
  builder = new webglmc.AtlasBuilder 1024, 1024, gridAdd: true
  for key, blockID of BLOCK_TYPES
    if blockID == 0
      continue
    img = webglmc.resmgr.resources["blocks/#{key}"]
    builder.add blockID, img
  builder.makeAtlas mipmaps: true

makeNewChunk = (chunkSize) ->

forceChunkType = (chunk) ->
  if !chunk instanceof ChunkArray
    chunk = new ChunkArray chunk
  chunk


class World
  constructor: (seed) ->
    @seed = seed
    @generator = new webglmc.WorldGenerator this
    @chunkSize = 16
    @chunks = {}
    @cachedVBOs = {}
    @dirtyVBOs = {}
    @shader = webglmc.resmgr.resources['shaders/simple']

    @atlas = makeBlockAtlas()

  getBlockTexture: (blockID) ->
    @atlas.slices[blockID]

  getBlock: (x, y, z) ->
    cx = div x, @chunkSize
    cy = div y, @chunkSize
    cz = div z, @chunkSize
    chunk = this.getChunk cx, cy, cz
    if !chunk?
      return 0
    inX = mod x, @chunkSize
    inY = mod y, @chunkSize
    inZ = mod z, @chunkSize
    rv = chunk[inX + inY * @chunkSize + inZ * @chunkSize * @chunkSize]
    rv

  setBlock: (x, y, z, type) ->
    cx = div x, @chunkSize
    cy = div y, @chunkSize
    cz = div z, @chunkSize
    chunk = this.getChunk cx, cy, cz, true
    inX = mod x, @chunkSize
    inY = mod y, @chunkSize
    inZ = mod z, @chunkSize
    oldType = chunk[inX + inY * @chunkSize + inZ * @chunkSize * @chunkSize]
    chunk[inX + inY * @chunkSize + inZ * @chunkSize * @chunkSize] = type

    this.markVBODirty cx, cy, cz

    # in case we replace air with non air at an edge block we need
    # to mark the vbos nearly as dirty
    if ((type == 0) != (oldType == 0))
      if (mod(x + 1, @chunkSize) == 0) then this.markVBODirty cx + 1, cy, cz
      if (mod(x - 1, @chunkSize) == 0) then this.markVBODirty cx - 1, cy, cz
      if (mod(y + 1, @chunkSize) == 0) then this.markVBODirty cx, cy + 1, cz
      if (mod(y - 1, @chunkSize) == 0) then this.markVBODirty cx, cy - 1, cz
      if (mod(z + 1, @chunkSize) == 0) then this.markVBODirty cx, cy, cz + 1
      if (mod(z - 1, @chunkSize) == 0) then this.markVBODirty cx, cy, cz - 1

  getChunk: (x, y, z, create = false) ->
    key = "#{x}|#{y}|#{z}"
    chunk = @chunks[key]
    if !chunk? && create
      @chunks[key] = chunk = new ChunkArray @chunkSize * @chunkSize * @chunkSize
    chunk

  setChunk: (x, y, z, chunk) ->
    key = "#{x}|#{y}|#{z}"
    @chunks[key] = forceChunkType chunk
    @dirtyVBOs[key] = true
    this.markVBODirty x + 1, y, z
    this.markVBODirty x - 1, y, z
    this.markVBODirty x, y + 1, z
    this.markVBODirty x, y - 1, z
    this.markVBODirty x, y, z + 1
    this.markVBODirty x, y, z - 1

  updateVBO: (x, y, z) ->
    chunk = this.getChunk x, y, z
    if !chunk
      return null
    maker = new webglmc.CubeMaker CUBE_SIZE

    offX = x * @chunkSize
    offY = y * @chunkSize
    offZ = z * @chunkSize

    isAir = (cx, cy, cz) =>
      if cx >= 0 && cy >= 0 && cz >= 0 &&
         cx < @chunkSize && cy < @chunkSize && cz < @chunkSize
        return chunk[cx + cy * @chunkSize + cz * @chunkSize * @chunkSize] == 0
      return this.getBlock(offX + cx, offY + cy, offZ + cz) == 0
      
    addSide = (side, id) =>
      texture = this.getBlockTexture id
      maker.addSide side, offX + cx * CUBE_SIZE, offY + cy * CUBE_SIZE,
        offZ + cz * CUBE_SIZE, texture

    for cz in [0...@chunkSize]
      for cy in [0...@chunkSize]
        for cx in [0...@chunkSize]
          blockID = chunk[cx + cy * @chunkSize + cz * @chunkSize * @chunkSize]
          if blockID == 0
            continue
          if isAir(cx - 1, cy, cz) then addSide('left', blockID)
          if isAir(cx + 1, cy, cz) then addSide('right', blockID)
          if isAir(cx, cy - 1, cz) then addSide('bottom', blockID)
          if isAir(cx, cy + 1, cz) then addSide('top', blockID)
          if isAir(cx, cy, cz - 1) then addSide('far', blockID)
          if isAir(cx, cy, cz + 1) then addSide('near', blockID)

    if maker.vertexCount > 0
      maker.makeVBO()

  markVBODirty: (x, y, z) ->
    @dirtyVBOs["#{x}|#{y}|#{z}"] = true

  getChunkVBO: (x, y, z) ->
    key = "#{x}|#{y}|#{z}"
    chunk = @chunks[key]
    if !chunk
      return null
    vbo = @cachedVBOs[key]
    if @dirtyVBOs[key] || !vbo?
      if vbo?
        vbo.destroy()
      vbo = this.updateVBO x, y, z
      delete @dirtyVBOs[key]
      if vbo
        @cachedVBOs[key] = vbo
    vbo

  makeChunkAABB: (x, y, z) ->
    size = CUBE_SIZE * @chunkSize
    v1 = [size * x - CUBE_SIZE / 2,
          size * y - CUBE_SIZE / 2,
          size * z - CUBE_SIZE / 2]
    v2 = [size, size, size]
    [vec3.create(v1), vec3.add(v1, v2, vec3.create())]

  iterVisibleVBOs: (callback) ->
    frustum = webglmc.engine.getCurrentFrustum()
    cameraPos = webglmc.engine.getCameraPos()
    rv = []

    for key, chunk of @chunks
      [x, y, z] = parseKey key
      vbo = this.getChunkVBO x, y, z
      if !vbo
        continue
      [vec1, vec2] = this.makeChunkAABB x, y, z

      # XXX: frustum culling does not work properly
      if frustum.testAABB(vec1, vec2) >= 0
        distance = vec3.subtract vec1, cameraPos
        rv.push vbo: vbo, distance: vec3.length(distance)

    rv.sort (a, b) -> a.distance - b.distance
    for info in rv
      callback info.vbo

  chunkAtCameraPosition: ->
    [x, y, z] = webglmc.engine.getCameraPos()
    [Math.floor(x / CUBE_SIZE / @chunkSize),
     Math.floor(y / CUBE_SIZE / @chunkSize),
     Math.floor(z / CUBE_SIZE / @chunkSize)]

  requestMissingChunks: ->
    [x, y, z] = this.chunkAtCameraPosition()
    height = Math.ceil @generator.maxHeight / @chunkSize
    for cx in [x - VIEW_DISTANCE..x + VIEW_DISTANCE]
      for cy in [0..height]
        for cz in [z - VIEW_DISTANCE..z + VIEW_DISTANCE]
          chunk = this.getChunk cx, cy, cz
          if !chunk
            this.requestChunk cx, cy, cz

  requestChunk: (x, y, z) ->
    # ensure chunk exists so that we don't request chunks
    # multiple times in requestMissingChunks
    this.getChunk x, y, z, true
    @generator.generateChunk x, y, z

  draw: ->
    @shader.use()
    @atlas.texture.bind()
    this.iterVisibleVBOs (vbo) ->
      vbo.draw()


public = self.webglmc ?= {}
public.World = World
public.BLOCK_TYPES = BLOCK_TYPES
