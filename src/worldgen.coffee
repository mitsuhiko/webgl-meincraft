class WorldGeneratorProcess extends webglmc.Process
  constructor: (seed) ->
    @perlin = new webglmc.PerlinGenerator seed

  generateChunk: (def) ->
    blockTypes = webglmc.BLOCK_TYPES
    {chunkSize, x, y, z, maxHeight} = def
    chunk = new Array(Math.pow(chunkSize, 3))
    offX = x * chunkSize
    offY = y * chunkSize
    offZ = z * chunkSize

    for cz in [0...chunkSize]
      for cx in [0...chunkSize]
        nx = (offX + cx) * 0.01
        nz = (offZ + cz) * 0.01
        noise = @perlin.simpleNoise2D(nx, nz) * 0.5 + 0.5
        columnHeight = noise * maxHeight

        for cy in [0...chunkSize]
          block = 0
          if cy + offY <= columnHeight
            block = blockTypes.grass
          chunk[cx + cy * chunkSize + cz * chunkSize * chunkSize] = block

    this.notifyParent x: x, y: y, z: z, chunk: chunk


class WorldGenerator
  constructor: (world) ->
    @world = world
    @maxHeight = 32

    # Spawn background worker for the actual world generation.
    @backgroundGenerator = webglmc.startProcess
      process:          'webglmc.WorldGeneratorProcess'
      args:             [world.seed]
      onNotification:   (data) =>
        @world.setChunk data.x, data.y, data.z, data.chunk

  generateChunk: (x, y, z) ->
    @backgroundGenerator.generateChunk
      x:          x
      y:          y
      z:          z
      maxHeight:  @maxHeight
      chunkSize:  @world.chunkSize


public = self.webglmc ?= {}
public.WorldGenerator = WorldGenerator
public.WorldGeneratorProcess = WorldGeneratorProcess
