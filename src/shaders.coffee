shaderSourceCache = {}


shaderFromSource = (type, source) ->
  gl = webglmc.engine.gl
  shader = gl.createShader gl[type]
  source = "#define #{type}\n#{source}"
  gl.shaderSource shader, source
  gl.compileShader shader
  if !gl.getShaderParameter shader, gl.COMPILE_STATUS
    throw new Error 'An error ocurred compiling the shader: ' +
      gl.getShaderInfoLog shader
  shader


joinFilename = (parentFile, file) ->
  parentFile.match(/^(.*\/)/)[1] + file


preprocessSource = (filename, source, callback) ->
  lines = []
  shadersToInclude = 0
  processingDone = false
  checkDone = ->
    if processingDone && shadersToInclude == 0
      callback(lines.join('\n'))

  for line in source.split /\r?\n/
    if match = line.match /^\s*#include\s+"(.*?)"\s*$/
      insertLocation = lines.length
      lines.push null
      shadersToInclude++
      do (insertLocation) ->
        loadShaderSource joinFilename(filename, match[1]), (source) ->
          lines[insertLocation] = source
          shadersToInclude--
          checkDone()
    else
      lines.push line

  processingDone = true
  checkDone()


loadShaderSource = (filename, callback) ->
  process = (source) ->
    shaderSourceCache[filename] = source
    preprocessSource filename, source, callback
  cached = shaderSourceCache[filename]
  if cached?
    process cached
  else
    console.debug "Loading shader source '#{filename}'"
    $.ajax
      url:      filename
      dataType: 'text'
      success:  process


loadShader = (filename, callback) ->
  loadShaderSource filename, (source) ->
    callback new Shader(source, filename)


class Shader
  constructor: (source, filename = '<string>') ->
    {gl} = webglmc.engine

    @prog = gl.createProgram()
    vertexShader = shaderFromSource 'VERTEX_SHADER', source
    fragmentShader = shaderFromSource 'FRAGMENT_SHADER', source
    gl.attachShader @prog, vertexShader
    gl.attachShader @prog, fragmentShader
    gl.linkProgram @prog
    console.debug "Compiled shader from '#{filename}' ->", this

    if !gl.getProgramParameter @prog, gl.LINK_STATUS
      throw new Error 'Could not link shaders'

  getUniformLocation: (name) ->
    webglmc.engine.gl.getUniformLocation @prog, name

  getAttribLocation: (name) ->
    webglmc.engine.gl.getAttribLocation @prog, name

  use: (useArrays = true) ->
    webglmc.engine.currentShader = this
    webglmc.engine.gl.useProgram @prog


public = this.webglmc ?= {}
public.Shader = Shader
public.loadShader = loadShader
