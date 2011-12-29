mod = (x, y) ->
  (x % y + y) % y


class WorldGeneratorProcess extends webglmc.Process
  constructor: (seed) ->
    @perlin = new webglmc.PerlinGenerator seed
    @waterLevel = 16

  isFlyingRock: (x, y, z) ->
    nx = x * 0.01
    ny = y * 0.01
    nz = z * 0.01
    heightOff = @perlin.simpleNoise2D(nx * 3.0, nz * 3.0) * 0.2

    mx = mod nx, 1.0
    my = mod ny + heightOff, 1.4
    mz = mod nz, 1.0

    # falloff from the top
    if my > 0.9
      return false
    if my > 0.8
      plateauFalloff = 1.0 - (my - 0.8) * 10
    else
      plateauFalloff = 1.0

    # falloff from the center
    centerFalloff = 0.1 / (
      Math.pow((mx - 0.5) * 1.5, 2.0) +
      Math.pow((my - 1.0) * 0.8, 2.0) +
      Math.pow((mz - 0.5) * 1.5, 2.0)
    )

    noise = @perlin.noise3D nx, ny * 0.5, nz, 4
    density = noise * centerFalloff * plateauFalloff
    density > 0.1

  isGroundLevel: (x, y, z) ->
    if y > 35
      return false

    nx = x * 0.01
    nz = z * 0.01
    noise = @perlin.noise2D(nx, nz, 3) * 0.5 + 0.5

    y < noise * 30

  isWater: (x, y, z) ->
    y <= @waterLevel

  getBlock: (x, y, z) ->
    blockTypes = webglmc.BLOCK_TYPES

    # Deep below
    if y < -20
      return blockTypes.rock

    # Ground level
    if this.isGroundLevel x, y, z
      if @waterLevel - 1 <= y <= @waterLevel + 1
        return blockTypes.sand
      else if y < @waterLevel
        return blockTypes.stone
      return blockTypes.grass

    # Flying rocks
    if this.isFlyingRock x, y, z
      if y <= @waterLevel + 1
        return blockTypes.stone
      if !this.isFlyingRock x, y + 1, z
        return blockTypes.grass
      return blockTypes.rock

    # Water level
    if this.isWater x, y, z
      return blockTypes.water

    blockTypes.air

  generateChunk: (def) ->
    {chunkSize, x, y, z} = def
    chunk = new Array(Math.pow(chunkSize, 3))
    offX = x * chunkSize
    offY = y * chunkSize
    offZ = z * chunkSize

    for cz in [0...chunkSize]
      for cy in [0...chunkSize]
        for cx in [0...chunkSize]
          blockID = this.getBlock offX + cx, offY + cy, offZ + cz
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
    @world.setChunk x, y, z, chunk


public = self.webglmc ?= {}
public.WorldGenerator = WorldGenerator
public.WorldGeneratorProcess = WorldGeneratorProcess
