fs = require 'fs'
maker = require 'makerjs'
ProgressBar = require "progress"
convert = require 'convert-svg-to-jpeg'
AudioContext = require('web-audio-api').AudioContext
bar = new ProgressBar('Analyze: [:bar] :percent :etas', { total: 100 })
AudioDataAnalyzer = require('./../../library/audioDataAnalyzer').analyzer
getData = (fpath,cb)->
  options={
    peaksAmount: 200,
    detectFormat: 'ogg'
  }
  audioDataAnalyzer = new AudioDataAnalyzer()
  audioDataAnalyzer.setDetectFormat(options.detectFormat)
  audioDataAnalyzer.getPeaks fpath, options.peaksAmount, (error, peaks)->
    console.log error
    console.log peaks
    cb peaks

module.exports = (Design)->
  Design.upload = (req, res, id, cb)->
    StorageContainer = Design.app.models.StorageContainer
    StorageContainer.getContainers (err, containers)->
      if containers.some (e)-> return e.name == material_id 
        StorageContainer.upload(req, res, {container: material_id}, cb);
      else
        StorageContainer.createContainer {name: id}, (err, c)->
          StorageContainer.upload(req, res, {container: c.name}, cb)
    

    Material.remoteMethod 'upload',
      http: {path: '/:id/upload', verb: 'post'},
      accepts: [
        {arg: 'req', type: 'object', 'http': {source: 'req'}},
        {arg: 'res', type: 'object', 'http': {source: 'res'}},
        {arg: 'id', type: 'string'}
      ],
      returns: {arg: 'status', type: 'string'}

  Design.generateDesign = (sound, cb)->
    console.log sound
    fs.writeFile 'temp.mp3', sound, (err, data)->
      getData 'temp.mp3', (peaks)->
        chunkSize = Math.floor(peaks.length/72)
        i = 0
        sum = 0
        newDataPoints = []
        for datapoint, index in peaks
          if datapoint < 0
            datapoint = datapoint * -1
          sum+= datapoint
          i++
          if i is chunkSize
            i=0
            newDataPoints.push sum/chunkSize
            sum= 0
        while newDataPoints.length isnt 72 
          newDataPoints.pop()
        for peak, index in newDataPoints
          newDataPoints[index] = peak*6
          if newDataPoints[index] > 500
            newDataPoints[index] = 500
        console.log newDataPoints
        coordinates = []
        for datapoint, index in newDataPoints
          x1 = 1050 + ((300)*Math.cos(index*0.0872665))
          y1 = 1050 + ((300)*Math.sin(index*0.0872665))
          x2 = 1050 + ((300+(datapoint))*Math.cos(index*0.0872665))
          y2 = 1050 + ((300+(datapoint))*Math.sin(index*0.0872665))
          obj= {
            type:"line"
            origin: [x1,y1]
            end: [x2,y2]
          } 
          coordinates.push obj
        circle1={
          type: "circle",
          origin: [1050,1050],
          radius: 1050
        }
        coordinates.push circle1
      
        options = {
          strokeWidth: 20
        }
        svg = maker.exporter.toSVG(coordinates,options)
        convert.convert(svg)
        .then (buffer)->
          cb null, buffer

  Design.remoteMethod 'generateDesign',
    accepts:
      arg: 'sound'
      type: 'file'
    returns:[
      {
        arg: 'design'
        type: 'file'
        root: true
      },
      {
        arg: 'Content-Type'
        type: 'string'
        http: { target: 'header' }
      }
    ]
    http:
      path: '/generateDesign'
      verb: 'post'