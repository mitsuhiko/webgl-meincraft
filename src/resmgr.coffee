forceAbsolute = (url) ->
  if !/^(https?|file):\/\//.test url
    url = document.baseURI.match(/^(.*)\//)[0] + url
  url


class ResourceManager
  constructor: ->
    @resourceDefs = {}
    @callbacks = {}
    @resources = {}
    @loaded = 0
    @total = 0

  add: (shortName, filename, def = {}, callback = null) ->
    typeSource = 'explicit'
    if !def.type?
      def.type = this.guessType filename
      typeSource = 'extension'
    def.shortName = shortName
    def.filename = forceAbsolute(filename)
    def.key = "#{def.type}/#{filename}"

    console.debug "Requesting resource '#{webglmc.autoShortenFilename def.filename
      }' [type=#{def.type}, from=#{typeSource}]"

    if callback && @resources[def.key]?
      if shortName && !@resourceDefs[shortName]?
        @resourceDefs[shortName] = @resources[def.key]
      return callback(@resources[def.key])

    @resourceDefs[def.key] = def
    delete @resources[def.key]
    @total++
    if callback?
      (@callbacks[def.key] ?= []).push callback
    this.triggerLoading def.key

  addFromList: (resources) ->
    for args in resources
      this.add.apply this, args

  guessType: (filename) ->
    return 'image' if /\.(png|gif|jpe?g)$/.test filename
    return 'texture' if /\.texture$/.test filename
    return 'shader' if /\.glsl$/.test filename
    console.error "Could not guess type from resource #{filename}"

  wait: (callback) ->
    if this.doneLoading()
      callback()
    else
      (@callbacks.__all__ ?= []).push callback

  triggerLoading: (key) ->
    def = @resourceDefs[key]
    this.loaders[def.type] this, def, (obj) =>
      if def.shortName?
        @resources[def.shortName] = obj
      @resources[key] = obj
      callbacks = @callbacks[key]
      delete @callbacks[key]
      @loaded++
      if callbacks
        for callback in callbacks
          callback(obj)
      if this.doneLoading()
        this.notifyWaiters()

  doneLoading: ->
    @loaded >= @total

  notifyWaiters: ->
    callbacks = @callbacks.__all__ || []
    delete @callbacks.__all__
    for callback in callbacks
      callback()

  loaders:
    image: (mgr, def, callback) ->
      rv = new Image()
      rv.onload = =>
        console.debug "Loaded image from '#{webglmc.autoShortenFilename def.filename
          }' [dim=#{rv.width }x#{rv.height}] ->", rv
        callback rv
      rv.src = def.filename

    shader: (mgr, def, callback) ->
      webglmc.loadShader def.filename, (shader) ->
        callback shader

    texture: (mgr, def, callback) ->
      imageFilename = def.image
      if !imageFilename
        imageFilename = def.filename.match(/^(.*)\.texture$/)[1]
      mgr.add null, imageFilename, {}, (image) =>
        callback webglmc.Texture.fromImage(image, def)


public = self.webglmc ?= {}
public.ResourceManager = ResourceManager
