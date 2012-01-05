dirname = (filename) ->
  filename.match(/^(.*\/)/)[1]


joinFilename = (parentFile, file) ->
  dirname(parentFile) + file


autoShortenFilename = (filename) ->
  base = dirname document.baseURI
  if filename.substr(0, base.length) == base
    filename = filename.substr base.length
  filename


floatColorFromHex = (hex) ->
  if hex.match /^#/
    hex = hex.substr 1
  r = parseInt(hex.substr(0, 2), 16) / 255.0
  g = parseInt(hex.substr(2, 2), 16) / 255.0
  b = parseInt(hex.substr(4, 2), 16) / 255.0
  if hex.length > 6
    a = parseInt(hex.susbstr(6, 2), 16) / 255.0
  else
    a = 1.0
  vec4.create([r, g, b, a])


public = self.webglmc ?= {}
public.dirname = dirname
public.joinFilename = joinFilename
public.autoShortenFilename = autoShortenFilename
public.floatColorFromHex = floatColorFromHex
