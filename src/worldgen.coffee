fillInDefaultOptions = (options) ->
  options.maxHeight ?= 32
  options.dampingFactor ?= 0.02
  options


class WorldGenerator
  constructor: (world, seed, options = {}) ->
    @options = fillInDefaultOptions options
    @world = world
    @perlin = new webglmc.PerlinGenerator @seed

  getHeight: (x, z) ->
    noise = @perlin.simpleNoise2D(@options.dampingFactor * x,
                                  @options.dampingFactor * z)
    parseInt (noise * 0.5 + 0.5) * @options.maxHeight

  generateChunkColumn: (x, z) ->
    height = this.getHeight x, z
    for y in [0...height]
      @world.setBlock x, y, z, webglmc.BLOCK_TYPES.stone


public = window.webglmc ?= {}
public.WorldGenerator = WorldGenerator
