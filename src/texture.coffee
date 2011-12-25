class Texture
  constructor: (width, height, storedWidth, storedHeight, offsetX, offsetY) ->
    @id = -1
    @width = width
    @height = height
    @storedWidth = storedWidth
    @storedHeight = storedHeight
    @offsetX = offsetX
    @offsetY = offsetY
    @parent = null

  bind: ->
    gl = webglmc.engine.gl
    gl.activeTexture gl.TEXTURE0
    gl.bindTexture gl.TEXTURE_2D, @id
    loc = webglmc.engine.currentShader.getUniformLocation "uTexture"
    if loc >= 0
      gl.uniform1i loc, 0

  destroy: ->
    if @parent
      return
    webglmc.engine.gl.deleteTexture @id

  slice: (x, y, width, height) ->
    return new TextureSlice this, @offsetX + x,
      @offsetY + y, width, height


class TextureSlice extends Texture
  constructor: (texture, offsetX, offsetY, width, height) ->
    super(width, height, texture.storedWidth, texture.storedHeight,
          offsetX, offsetY)
    @parent = texture
    @id = texture.id


textureFromImage = (image, options) ->
  gl = webglmc.engine.gl

  texture = new Texture image.width, image.height, image.width,
    image.height, 0, 0, filtering
  texture.id = gl.createTexture()

  filtering = options.filtering || 'LINEAR'
  filter = gl[filtering]

  gl.bindTexture gl.TEXTURE_2D, texture.id
  gl.pixelStorei gl.UNPACK_FLIP_Y_WEBGL, true
  gl.texImage2D gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, image
  gl.texParameteri gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, filter
  gl.texParameteri gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, filter

  if options.clampToEdge
    gl.texParameteri gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE
    gl.texParameteri gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE

  gl.bindTexture gl.TEXTURE_2D, null

  console.debug "Created texture from '#{image.src}' [dim=#{image.width
    }x#{image.height}, filtering=#{filtering}] ->", texture

  texture


public = window.webglmc ?= {}
public.Texture = Texture
public.textureFromImage = textureFromImage
