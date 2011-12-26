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


startProcess = (workerName, args, callback) ->
  worker = new Worker workerBase + 'process.js'
  worker.addEventListener 'message', (event) =>
    {data} = event
    if data.type == 'notify'
      callback data.value
    else if data.type == 'console'
      console[data.level]("%c[#{workerName}]: ",
        'background: #D4F2F3; color: #133C3D', data.args...)
  worker.addEventListener 'error', (event) =>
    console.error 'Error in worker: ', event.message
  console.log "Starting worker #{workerName} args=", args
  worker.postMessage cmd: '__init__', worker: workerName, args: args
  return new ProcessProxy worker, workerName


class ProcessProxy

  constructor: (worker, workerName) ->
    @_worker = worker
    for key, callable of findClass(workerName).prototype
      if key in ['constructor', 'run', 'notifyParent']
        continue
      do (key) =>
        this[key] = (args...) -> this._worker.postMessage cmd: key, args: args


class Process

  notifyParent: (value) ->
    postMessage type: 'notify', value: value

  run: ->


public = self.webglmc ?= {}
public.Process = Process
public.startProcess = startProcess


if startWorkerSupport
  importScripts '../lib/gl-matrix.js', 'perlin.js', 'worldgen.js'

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
