NOTHING = 0
FLYING_ROCK = 1
GROUND = 2


class GeneratorState

  constructor: (chunkSize) ->
    @chunkSize = chunkSize
    @cacheSizeX = @chunkSize
    @cacheSizeY = @chunkSize + 1
    @cacheSizeZ = @chunkSize
    @blockSourceCache = new Uint8Array @cacheSizeX * @cacheSizeY * @cacheSizeZ

  init: (gen, offX, offY, offZ) ->
    {cacheSizeX, cacheSizeY, cacheSizeZ} = this

    @offX = offX
    @offY = offY
    @offZ = offZ

    sc = @blockSourceCache
    for cz in [0...cacheSizeZ] by 1
      for cy in [0...cacheSizeY] by 1
        for cx in [0...cacheSizeX] by 1
          source = gen.getBlockSource offX + cx, offY + cy, offZ + cz
          sc[cx + cy * cacheSizeX + cz * cacheSizeX * cacheSizeY] = source

  getBlockSource: (cx, cy, cz) ->
    @blockSourceCache[cx + cy * @cacheSizeX + cz * @cacheSizeX * @cacheSizeY]


class WorldGeneratorProcess extends webglmc.Process
  constructor: (seed) ->
    super()
    @perlin = new webglmc.PerlinGenerator seed
    @cachedState = null
    @cachedChunk = null
    @waterLevel = 16

  isFlyingRock: (x, y, z) ->
    nx = x * 0.01
    ny = y * 0.01
    nz = z * 0.01
    heightOff = @perlin.simpleNoise2D(nx * 3.0, nz * 3.0) * 0.2

    mx = (nx % 1.0 + 1.0) % 1.0
    my = ((ny + heightOff) % 1.4 + 1.4) % 1.4
    mz = (nz % 1.0 + 1.0) % 1.0

    # falloff from the top
    if my > 0.9
      return false
    if my > 0.8
      plateauFalloff = 1.0 - (my - 0.8) * 10
    else
      plateauFalloff = 1.0

    # falloff from the center
    a = (mx - 0.5) * 1.5
    b = (my - 1.0) * 0.8
    c = (mz - 0.5) * 1.5
    centerFalloff = 0.1 / (a * a + b * b + c * c)

    noise = @perlin.noise3D nx, ny * 0.5, nz, 4
    density = noise * centerFalloff * plateauFalloff
    density > 0.1

  getGroundHeight: (x, z) ->
    nx = x * 0.01
    nz = z * 0.01
    noise = @perlin.noise2D(nx, nz, 3) * 0.5 + 0.5
    noise * 30

  getGrassVariation: (x, y, z) ->
    nx = x * 1.2
    ny = y * 1.4
    nz = z * 1.1
    noise = @perlin.simpleNoise3D(nx, ny, nz) * 0.5 + 0.5
    variation = Math.floor(noise * 4) + 1
    webglmc.BLOCK_TYPES["grass0#{variation}"]

  getRockVariation: (x, y, z) ->
    nx = 0.3 + x * 1.1
    ny = 0.4 + y * 1.1
    nz = 0.5 + z * 1.05
    noise = @perlin.simpleNoise3D(nx, ny, nz) * 0.5 + 0.5
    noise = Math.floor(noise * 3)
    if noise > 0.4
      return webglmc.BLOCK_TYPES.rock01
    return webglmc.BLOCK_TYPES.rock02

  getBlockSource: (x, y, z) ->
    # Ground level blocks
    if y < this.getGroundHeight x, z
      return GROUND

    # Flying rocks
    if this.isFlyingRock x, y, z
      return FLYING_ROCK

    NOTHING

  getBlock: (state, cx, cy, cz) ->
    x = state.offX + cx
    y = state.offY + cy
    z = state.offZ + cz
    blockSource = state.getBlockSource cx, cy, cz

    if !blockSource
      if y < @waterLevel
        return webglmc.BLOCK_TYPES.water
      return webglmc.BLOCK_TYPES.air

    if blockSource == FLYING_ROCK
      if !state.getBlockSource cx, cy + 1, cz
        return this.getGrassVariation x, y, z
      return this.getRockVariation x, y, z

    if blockSource == GROUND
      if y < @waterLevel - 4
        return webglmc.BLOCK_TYPES.stone
      if @waterLevel - 1 <= y <= @waterLevel + 1
        return webglmc.BLOCK_TYPES.sand

    return this.getGrassVariation x, y, z

  getGeneratorState: (offX, offY, offZ, chunkSize) ->
    if !@cachedState || @cachedState.chunkSize != chunkSize
      @cachedState = new GeneratorState chunkSize
    @cachedState.init this, offX, offY, offZ
    @cachedState

  getChunkArray: (chunkSize) ->
    dim = chunkSize * chunkSize * chunkSize
    if !@cachedChunk || @cachedChunk.length != dim
      @cachedChunk = new Uint8Array dim
    @cachedChunk

  generateChunk: (def) ->
    {chunkSize, x, y, z} = def

    offX = x * chunkSize
    offY = y * chunkSize
    offZ = z * chunkSize

    # Since generateChunk is not reentrant and JavaScript does not
    # support multithreading we can savely keep them around.  These
    # functions will cache them in the background so that we do not
    # need any memory allocations during world generation
    state = this.getGeneratorState offX, offY, offZ, chunkSize
    chunk = this.getChunkArray chunkSize

    for cz in [0...chunkSize] by 1
      for cy in [0...chunkSize] by 1
        for cx in [0...chunkSize] by 1
          blockID = this.getBlock state, cx, cy, cz
          chunk[cx + cy * chunkSize + cz * chunkSize * chunkSize] = blockID

    this.notifyParent x: x, y: y, z: z, chunk: chunk


class WorldGenerator
  constructor: (world) ->
    @world = world

    numberOfWorkers = parseInt webglmc.getRuntimeParameter 'workers', 4

    # Spawn a few workers for the actual world generation.
    @manager = new webglmc.ProcessManager numberOfWorkers,
      process:        'webglmc.WorldGeneratorProcess'
      args:           [world.seed]
      onNotification: (data) =>
        this.processGeneratedChunk data.x, data.y, data.z, data.chunk

    @manager.addStatusDisplay('Worldgen worker load')

  generateChunk: (x, y, z) ->
    @manager.getWorker().generateChunk
      x:          x
      y:          y
      z:          z
      chunkSize:  @world.chunkSize

  processGeneratedChunk: (x, y, z, chunk) ->
    @world.setRequestedChunk x, y, z, chunk


publicInterface = self.webglmc ?= {}
publicInterface.WorldGenerator = WorldGenerator
publicInterface.WorldGeneratorProcess = WorldGeneratorProcess
