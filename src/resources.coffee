RESOURCES = [
  ['shaders/simple', 'assets/shaders/simple.glsl'],
  ['selection', 'assets/textures/selection.png.texture'],
  ['blocks/grass01', 'assets/textures/grass01.png']
  ['blocks/grass02', 'assets/textures/grass02.png']
  ['blocks/grass03', 'assets/textures/grass03.png']
  ['blocks/grass04', 'assets/textures/grass04.png']
  ['blocks/granite', 'assets/textures/granite.png']
  ['blocks/stone', 'assets/textures/stone.png']
  ['blocks/rock01', 'assets/textures/rock01.png']
  ['blocks/rock02', 'assets/textures/rock02.png']
  ['blocks/water', 'assets/textures/water.png']
  ['blocks/sand', 'assets/textures/sand.png']
]


makeDefaultResourceManager = ->
  resmgr = new webglmc.ResourceManager
  resmgr.addFromList RESOURCES
  resmgr


public = self.webglmc ?= {}
public.makeDefaultResourceManager = makeDefaultResourceManager
