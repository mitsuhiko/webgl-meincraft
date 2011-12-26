class WorldGeneratorProcess extends webglmc.Process
  constructor: (seed) ->
    @perlin = new webglmc.PerlinGenerator seed

  isSolid: (x, y, z) ->
    nx = x * 0.01
    ny = y * 0.02
    nz = z * 0.01
    noise = @perlin.simpleNoise3D nx, ny, nz
    noise > 0.0

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

    # Spawn background worker for the actual world generation.
    @backgroundGenerator = webglmc.startProcess
      process:          'webglmc.WorldGeneratorProcess'
      args:             [world.seed]
      onNotification:   (data) =>
        @world.setChunk data.x, data.y, data.z, data.chunk
        webglmc.engine.popThrobber()

  generateChunk: (x, y, z) ->
    webglmc.engine.pushThrobber()
    @backgroundGenerator.generateChunk
      x:          x
      y:          y
      z:          z
      chunkSize:  @world.chunkSize


public = self.webglmc ?= {}
public.WorldGenerator = WorldGenerator
public.WorldGeneratorProcess = WorldGeneratorProcess
