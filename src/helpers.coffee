dirname = (filename) ->
  filename.match(/^(.*\/)/)[1]


joinFilename = (parentFile, file) ->
  dirname(parentFile) + file


autoShortenFilename = (filename) ->
  base = dirname document.baseURI
  if filename.substr(0, base.length) == base
    filename = filename.substr base.length
  filename


public = self.webglmc ?= {}
public.dirname = dirname
public.joinFilename = joinFilename
public.autoShortenFilename = autoShortenFilename
