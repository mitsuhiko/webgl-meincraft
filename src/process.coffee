if window?
  workerBase = 'compiled/'
  startWorkerSupport = false
else
  workerBase = './'
  startWorkerSupport = true


findClass = (name) ->
  rv = self
  for piece in name.split(/\./)
    rv = rv[piece]
  rv


startProcess = (options) ->
  args = options.args ? []
  callback = options.onNotification

  worker = new Worker workerBase + 'process.js'
  worker.addEventListener 'message', (event) =>
    {data} = event
    if data.type == 'notify'
      if callback?
        callback data.value, data.done
    else if data.type == 'console'
      console[data.level]("%c[#{options.process}]: ",
        'background: #D4F2F3; color: #133C3D', data.args...)

  worker.addEventListener 'error', (event) =>
    console.error 'Error in worker: ', event.message

  console.log "Starting process #{options.process} as worker args=", args
  worker.postMessage cmd: '__init__', worker: options.process, args: args
  return new ProcessProxy worker, options.process, options.onBeforeCall


class ProcessProxy
  constructor: (worker, processClass, onBeforeCall) ->
    @_worker = worker
    for key, callable of findClass(processClass).prototype
      if key in ['constructor', 'run', 'notifyParent']
        continue
      do (key) =>
        this[key] = (args...) ->
          onBeforeCall?(key, args)
          this._worker.postMessage cmd: key, args: args
          undefined


class Process
  notifyParent: (value, done = true) ->
    postMessage type: 'notify', value: value, done: done

  run: ->


class ProcessManager
  constructor: (workers, options) ->
    @workers = []
    @display = null
    @onNotification = options.onNotification
    @load = {}
    for n in [0...workers]
      this.addWorker options

  addWorker: (options) ->
    num = @workers.length
    @load[num] = 0
    @workers.push startProcess
      process:        options.process
      args:           options.args
      onBeforeCall:   (name, args) =>
        this.updateDisplay()
        webglmc.engine.pushThrobber()
        options.onBeforeCall?(name, args)
        @load[num] += 1
      onNotification: (data, done) =>
        this.handleWorkerResult num, data, done

  getWorker: ->
    workers = ([load, num] for num, load of @load)
    workers.sort (a, b) ->
      a[0] - b[0]
    @workers[workers[0][1]]

  handleWorkerResult: (num, data, done) ->
    webglmc.engine.popThrobber()
    if done
      @load[num] -= 1
    this.updateDisplay()
    this.onNotification data

  updateDisplay: ->
    if !@display
      return

    pieces = []
    for num, load of @load
      pieces.push "w(#{num}) = #{load}"

    @display.setText pieces.join(', ')

  addStatusDisplay: (name) ->
    @display = webglmc.debugPanel.addDisplay name
    this.updateDisplay()


publicInterface = self.webglmc ?= {}
publicInterface.Process = Process
publicInterface.ProcessManager = ProcessManager
publicInterface.startProcess = startProcess


if startWorkerSupport
  importScripts '../lib/gl-matrix.js', 'perlin.js', 'world.js', 'worldgen.js'

  instance = null
  commandQueue = []

  makeLogger = (level) ->
    (args...) -> postMessage type: 'console', level: level, args: args
  this.console =
    log: makeLogger 'log'
    debug: makeLogger 'debug'
    warn: makeLogger 'warn'
    error: makeLogger 'error'

  kickOff = ->
    setTimeout((-> instance.run()), 0)
    for [cmd, args] in commandQueue
      instance[cmd](args...)
    
  executeCommand = (cmd, args) ->
    if instance
      if !instance[cmd]?
        console.error 'Tried to call unexisting callback name=', cmd
      instance[cmd](args...)
    else
      commandQueue.push [cmd, args]

  self.addEventListener 'message', (event) ->
    {data} = event
    if data.cmd == '__init__'
      cls = findClass data.worker
      instance = new cls data.args...
      console.log 'Started up args=', data.args
      kickOff()
    else if instance
      executeCommand data.cmd, data.args
