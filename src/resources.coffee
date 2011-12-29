RESOURCES = [
  ['shaders/simple', 'assets/shaders/simple.glsl'],
  ['blocks/grass', 'assets/textures/grass.png']
  ['blocks/granite', 'assets/textures/granite.png']
  ['blocks/stone', 'assets/textures/stone.png']
  ['blocks/rock', 'assets/textures/rock.png']
  ['blocks/water', 'assets/textures/water.png']
  ['blocks/sand', 'assets/textures/sand.png']
]


makeDefaultResourceManager = ->
  resmgr = new webglmc.ResourceManager
  resmgr.addFromList RESOURCES
  resmgr


public = self.webglmc ?= {}
public.makeDefaultResourceManager = makeDefaultResourceManager
