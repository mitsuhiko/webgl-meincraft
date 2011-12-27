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
    @displays[name] = new Display this, name


public = self.webglmc ?= {}
public.DebugPanel = DebugPanel
