NUMBER_OF_WORKERS = 4


mod = (x, y) ->
  (x % y + y) % y


class WorldGeneratorProcess extends webglmc.Process
  constructor: (seed) ->
    @perlin = new webglmc.PerlinGenerator seed

  isSolid: (x, y, z) ->
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

    noise = @perlin.simpleNoise3D nx, ny * 0.5, nz
    density = noise * centerFalloff * plateauFalloff
    density > 0.1

  generateChunk: (def) ->
    blockTypes = webglmc.BLOCK_TYPES
    {chunkSize, x, y, z} = def
    chunk = new Array(Math.pow(chunkSize, 3))
    offX = x * chunkSize
    offY = y * chunkSize
    offZ = z * chunkSize

    for cz in [0...chunkSize]
      for cy in [0...chunkSize]
        for cx in [0...chunkSize]
          isSolid = this.isSolid offX + cx, offY + cy, offZ + cz
          block = blockTypes.air
          if isSolid
            if !this.isSolid offX + cx, offY + cy + 1, offZ + cz
              block = blockTypes.grass
            else
              block = blockTypes.rock
          chunk[cx + cy * chunkSize + cz * chunkSize * chunkSize] = block

    this.notifyParent x: x, y: y, z: z, chunk: chunk


class WorldGenerator
  constructor: (world) ->
    @world = world

    # Spawn a few workers for the actual world generation.
    @manager = new webglmc.ProcessManager NUMBER_OF_WORKERS,
      process:        'webglmc.WorldGeneratorProcess'
      args:           [world.seed]
      onNotification: (data) =>
        this.processGeneratedChunk data.x, data.y, data.z, data.chunk

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
