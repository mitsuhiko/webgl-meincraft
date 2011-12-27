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


bench = (benchName, callback) ->
  name = "bench [#{benchName}]"
  display = webglmc.debugPanel.addDisplay name
  now = Date.now()
  callback()
  display.setText "#{(Date.now() - now) / 1000}ms"


public = self.webglmc ?= {}
public.DebugPanel = DebugPanel
public.bench = bench
