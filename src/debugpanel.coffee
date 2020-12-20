class Display
  constructor: (panel, name) ->
    @panel = panel

    row = $('<tr></tr>').appendTo(panel.element)
    @keyElement = $('<th></th>').text(name).appendTo(row)
    @valueElement = $('<td></td>').appendTo(row)
    this.setText('')

  setVisible: (value) ->
    if value
      @element.show()
    else
      @element.hide()

  setText: (value) ->
    @valueElement.text(value)

  getText: ->
    @valueElement.text()


class DebugPanel
  constructor: ->
    @displays = {}
    @element = $('<table id=debugpanel></table>').appendTo('body')

  addDisplay: (name) ->
    @displays[name] ?= new Display this, name


parameters = null
getRuntimeParameter = (key, def=null) ->
  if !parameters?
    parameters = {}
    for item in window.location.search.substr(1).split('&')
      [k, v] = item.split('=', 2)
      parameters[k] = v
  parameters[key] ? def


bench = (benchName, callback) ->
  name = "bench [#{benchName}]"
  display = webglmc.debugPanel.addDisplay name
  now = Date.now()
  callback()
  display.setText "#{(Date.now() - now) / 1000}ms"


publicInterface = self.webglmc ?= {}
publicInterface.DebugPanel = DebugPanel
publicInterface.getRuntimeParameter = getRuntimeParameter
publicInterface.bench = bench
