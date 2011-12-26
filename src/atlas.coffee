class Atlas
  constructor: (texture, slices) ->
    @texture = texture
    @slices = slices

  destroy: ->
    if @texture
      @texture.destroy()
      @texture = null


class AtlasNode
  constructor: (x, y, width, height) ->
    @x = x
    @y = y
    @width = width
    @height = height
    @left = null
    @right = null
    @inUse = false

  insertChild: (width, height) ->
    if @left
      return @left.insertChild(width, height) ||
             @right.insertChild(width, height)

    if @inUse || width > @width || height > @height
      return null

    if @width == width && @height == height
      @inUse = true
      return this

    if @width - width > @height - height
      @left = new AtlasNode @x, @y, width, @height
      @right = new AtlasNode @x + width, @y, @width - width, @height
    else
      @left = new AtlasNode @x, @y, @width, height
      @right = new AtlasNode @x, @y + height, @width, @height - height

    @left.insertChild(width, height)


class AtlasBuilder
  constructor: (width, height, options = {}) ->
    @canvas = $('<canvas></canvas>')
      .attr('width', width)
      .attr('height', height)[0]
    @ctx = @canvas.getContext('2d')
    @padding = options.padding ? 0
    @gridAdd = options.gridAdd ? false
    @slices = {}
    @root = new AtlasNode 0, 0, width, height

  drawOnCanvas: (x, y, img, gridAdd) ->
    times = if gridAdd then 3 else 1
    for ry in [0...times]
      posy = y + (ry * img.height)
      for rx in [0...times]
        posx = x + (rx * img.width)
        @ctx.drawImage img, 0, 0, img.width, img.height,
                       posx, posy, img.width, img.height

  add: (key, img, gridAdd = @gridAdd) ->
    width = img.width + @padding * 2
    height = img.height + @padding * 2
    if gridAdd
      width *= 3
      height *= 3

    node = @root.insertChild width, height
    if !node
      return false

    this.drawOnCanvas node.x, node.y, img, gridAdd
    @slices[key] =
      x: node.x + (if gridAdd then img.width else 0) + @padding
      y: node.y + (if gridAdd then img.height else 0) + @padding
      width: img.width
      height: img.height

    true

  makeAtlas: (options = {}) ->
    texture = webglmc.textureFromImage @canvas, options
    slices = {}
    for key, def of @slices
      slices[key] = texture.slice def.x, texture.height - def.y - def.height,
        def.width, def.height
    new Atlas texture, slices


public = this.webglmc ?= {}
public.AtlasBuilder = AtlasBuilder
