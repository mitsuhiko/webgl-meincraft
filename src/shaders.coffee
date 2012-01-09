lastSourceID = 0
shaderSourceCache = {}
shaderReverseMapping = {}


onShaderError = (type, log, stage, filename = '<string>') ->
  filename = webglmc.autoShortenFilename filename
  console.error "Shader error when #{stage} #{type} #{filename}"
  console.debug "Shader debug information:"
  lines = log.split /\r?\n/
  for line in lines
    match = line.match /(\w+):\s+(\d+):(\d+):\s*(.*)$/
    if match
      [dummy, level, sourceID, lineno, message] = match
      errorFilename = webglmc.autoShortenFilename shaderReverseMapping[sourceID]
      console.warn "[#{level}] #{errorFilename}:#{lineno}: #{message}"
    else
      console.log line
  throw "Abort: Unable to load shader '#{filename}' because of errors"


shaderFromSource = (type, source, filename = null) ->
  gl = webglmc.engine.gl
  shader = gl.createShader gl[type]
  source = "#define #{type}\n#{source}"
  gl.shaderSource shader, source
  gl.compileShader shader
  if !gl.getShaderParameter shader, gl.COMPILE_STATUS
    log = gl.getShaderInfoLog shader
    onShaderError type, log, 'compiling', filename
  shader


preprocessSource = (filename, source, sourceID, callback) ->
  lines = []
  shadersToInclude = 0
  processingDone = false
  checkDone = ->
    if processingDone && shadersToInclude == 0
      callback lines.join('\n')

  lines.push '#line 0 ' + sourceID

  for line in source.split /\r?\n/
    if match = line.match /^\s*#include\s+"(.*?)"\s*$/
      insertLocation = lines.length
      lines.push null
      shadersToInclude++
      do (insertLocation) ->
        loadShaderSource webglmc.joinFilename(filename, match[1]), (source) ->
          lines[insertLocation] = source + '\n#line ' + insertLocation +
            ' ' + sourceID
          shadersToInclude--
          checkDone()
    else
      lines.push line

  processingDone = true
  checkDone()


loadShaderSource = (filename, callback) ->
  process = (source) ->
    entry = shaderSourceCache[filename]
    if !entry
      shaderSourceCache[filename] = entry = [source, lastSourceID++]
      shaderReverseMapping[entry[1]] = filename
    preprocessSource filename, source, entry[1], callback
  cached = shaderSourceCache[filename]
  if cached?
    process cached[0]
  else
    console.debug "Loading shader source '#{webglmc.autoShortenFilename filename}'"
    $.ajax
      url:      filename
      dataType: 'text'
      success:  process


loadShader = (filename, callback) ->
  loadShaderSource filename, (source) ->
    callback new Shader(source, filename)


class Shader extends webglmc.ContextObject
  @withStack 'shader'

  constructor: (source, filename = null) ->
    {gl} = webglmc.engine

    @prog = gl.createProgram()
    @vertexShader = shaderFromSource 'VERTEX_SHADER', source, filename
    @fragmentShader = shaderFromSource 'FRAGMENT_SHADER', source, filename
    gl.attachShader @prog, @vertexShader
    gl.attachShader @prog, @fragmentShader
    gl.linkProgram @prog

    @attribCache = {}
    @uniformCache = {}

    # This value is changed by the engine automatically.  It's used to find out
    # if a shader has older values on the graphics device than are stored in
    # the engine's uniform matrix stack.
    @_uniformVersion = 0

    if !gl.getProgramParameter @prog, gl.LINK_STATUS
      log = gl.getProgramInfoLog @prog
      onShaderError 'PROGRAM', log, 'linking', filename

    console.debug "Compiled shader from '#{filename}' ->", this

  getUniformLocation: (name) ->
    @uniformCache[name] ?= webglmc.engine.gl.getUniformLocation @prog, name

  getAttribLocation: (name) ->
    @attribCache[name] ?= webglmc.engine.gl.getAttribLocation @prog, name

  uniform1i: (name, value) ->
    loc = this.getUniformLocation name
    webglmc.engine.gl.uniform1i loc, value if loc

  uniform1f: (name, value) ->
    loc = this.getUniformLocation name
    webglmc.engine.gl.uniform1f loc, value if loc

  uniform2f: (name, value1, value2) ->
    loc = this.getUniformLocation name
    webglmc.engine.gl.uniform2f loc, value1, value2 if loc

  uniform2fv: (name, value) ->
    loc = this.getUniformLocation name
    webglmc.engine.gl.uniform2fv loc, value if loc

  uniform3fv: (name, value) ->
    loc = this.getUniformLocation name
    webglmc.engine.gl.uniform3fv loc, value if loc

  uniform4fv: (name, value) ->
    loc = this.getUniformLocation name
    webglmc.engine.gl.uniform4fv loc, value if loc

  uniformMatrix3fv: (name, value) ->
    loc = this.getUniformLocation name
    webglmc.engine.gl.uniformMatrix3fv loc, false, value if loc

  uniformMatrix4fv: (name, value) ->
    loc = this.getUniformLocation name
    webglmc.engine.gl.uniformMatrix4fv loc, false, value if loc

  bind: ->
    webglmc.engine.gl.useProgram @prog

  unbind: ->
    webglmc.engine.gl.useProgram null

  destroy: ->
    {gl} = webglmc.engine
    gl.destroyProgram @prog
    gl.destroyShader @vertexShader
    gl.destroyShader @fragmentShader


public = self.webglmc ?= {}
public.Shader = Shader
public.loadShader = loadShader
