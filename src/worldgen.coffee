fillInDefaultOptions = (options) ->
  options.maxHeight ?= 32
  options.dampingFactor ?= 0.02
  options


class WorldGeneratorProcess extends webglmc.Process
  constructor: (seed) ->
    @perlin = new webglmc.PerlinGenerator seed

  generateChunk: (x, y, z) ->
    this.notifyParent "Generate chunk x=#{x}, y=#{y}, z=#{z}"


class WorldGenerator
  constructor: (world, seed, options = {}) ->
    @options = fillInDefaultOptions options
    @world = world
    @perlin = new webglmc.PerlinGenerator seed

    # Spawn background worker for the actual world generation.
    gen = webglmc.startProcess 'webglmc.WorldGeneratorProcess', [seed], (data) =>
      console.log 'Worker result', data
    @backgroundGenerator = gen

  getHeight: (x, z) ->
    noise = @perlin.simpleNoise2D(@options.dampingFactor * x,
                                  @options.dampingFactor * z)
    parseInt (noise * 0.5 + 0.5) * @options.maxHeight

  generateChunkColumn: (x, z) ->
    height = this.getHeight x, z
    for y in [0...height]
      @world.setBlock x, y, z, webglmc.BLOCK_TYPES.stone


public = this.webglmc ?= {}
public.WorldGenerator = WorldGenerator
public.WorldGeneratorProcess = WorldGeneratorProcess
