fs = require 'fs'
convert = require('imagemagick');
maker = require 'makerjs'
ProgressBar = require "progress"
AudioDataAnalyzer = require('./../../library/audioDataAnalyzer').analyzer
path = require 'path'
getData = (fpath,cb)->
  options={
    peaksAmount: 200,
    detectFormat: 'mp3'
  }
  audioDataAnalyzer = new AudioDataAnalyzer()
  audioDataAnalyzer.setDetectFormat(options.detectFormat)
  console.log path.resolve(fpath)
  audioDataAnalyzer.getPeaks fpath, options.peaksAmount, (error, peaks)->
    console.log error
    console.log peaks
    cb peaks

module.exports = (Design)->
  Design.generateDesign = (soundName, cb)->
    getData './tmp/storage/designs/'+soundName, (peaks)->
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
      console.log "this is where it breaks"
      svg = maker.exporter.toSVG(coordinates,options)
      console.log "when making svg"
      fs.writeFile './tmp/storage/designs/'+soundName+'.svg', svg, (err, status)->
        convert.convert ['./tmp/storage/designs/'+soundName+'.svg','-transparent white', './tmp/storage/designs/'+soundName+'.png'], (err, out)->
          cb null, soundName+'.png'

  Design.remoteMethod 'generateDesign',
    accepts:
      arg: 'soundName'
      type: 'string'
    returns:[
      {
        arg: 'design'
        type: 'file'
        root: true
      }
    ]
    http:
      path: '/generateDesign/:soundName'
      verb: 'get'