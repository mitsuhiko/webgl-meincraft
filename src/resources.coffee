RESOURCES = [
  ['shaders/simple', 'assets/shaders/simple.glsl'],
  ['blocks/grass', 'assets/textures/grass.png']
  ['blocks/granite', 'assets/textures/granite.png']
  ['blocks/stone', 'assets/textures/stone.png']
]


makeDefaultResourceManager = ->
  resmgr = new webglmc.ResourceManager
  resmgr.addFromList RESOURCES
  resmgr


public = window.webglmc ?= {}
public.makeDefaultResourceManager = makeDefaultResourceManager
