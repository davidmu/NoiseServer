fs = require 'fs'
convert = require('imagemagick');
maker = require 'makerjs'
ProgressBar = require "progress"
AudioDataAnalyzer = require('./../../library/audioDataAnalyzer').analyzer
AWS = require('aws-sdk')
loopback = require 'loopback'
AWS.config.update({ accessKeyId: 'AKIAIP74NXZZVUHGHC5A', secretAccessKey: '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' })
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
    #console.log error
    #console.log peaks
    cb peaks
module.exports = (Design)->
  #DesignEntry = Design.app.models.DesignEntry
  Design.generateDesign = (soundName, cb)->
    getData './tmp/storage/designs/'+soundName, (peaks)->
      chunkSize = Math.floor(peaks.length/72)
      i = 0
      sum = 0
      designEntry = {}
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
        newDataPoints[index] = peak*2
        if newDataPoints[index] is 0
          newDataPoints[index] = Math.random()*12
        if newDataPoints[index] > 200
          newDataPoints[index] = 200
      coordinates = []
      DesignEntry = Design.app.models.DesignEntry
      designEntry = {}
      for datapoint, index in newDataPoints
        designEntry["dataEntry"+(index+1)] = Math.round(100+datapoint)
        x1 = 350 + ((100)*Math.cos(index*0.0872665))
        y1 = 350 + ((100)*Math.sin(index*0.0872665))
        x2 = 350 + ((100+(datapoint))*Math.cos(index*0.0872665))
        y2 = 350 + ((100+(datapoint))*Math.sin(index*0.0872665))
        obj= {
          type:"line"
          origin: [x1,y1]
          end: [x2,y2]
        } 
        coordinates.push obj
      circle1={
        type: "circle",
        origin: [350,350],
        radius: 350
      }
      coordinates.push circle1
      options = {
        strokeWidth: 8
      }
      basePath = "https://s3-eu-west-1.amazonaws.com/noise-design-storage/"
      svg = maker.exporter.toSVG(coordinates,options)
      fs.writeFile './tmp/storage/designs/'+soundName+'.svg', svg, (err, status)->
        convert.convert ['./tmp/storage/designs/'+soundName+'.svg','-transparent', 'white', './tmp/storage/designs/'+soundName+'.png'], (err, out)->
          fs.readFile './tmp/storage/designs/'+soundName+'.png', (err,data)->
            s3 = new AWS.S3()
            base64data = new Buffer data, 'binary'
            s3.upload {
              Bucket: 'noise-design-storage',
              Key: soundName+'.png',
              Body: base64data,
              ACL: 'public-read'
            },(resp)->
              designEntry.designPath = basePath + soundName+'.png'
              designEntry.soundPath = basePath + soundName
              DesignEntry.create designEntry, (err, design)->
                console.log design
                console.log err
                cb null, design
          fs.readFile './tmp/storage/designs/'+soundName, (err,data)->
            s3 = new AWS.S3()
            base64data = new Buffer data, 'binary'
            s3.upload {
              Bucket: 'noise-design-storage',
              Key: soundName,
              Body: base64data,
              ACL: 'public-read'
            },(resp)->
              console.log arguments
              console.log 'Successfully uploaded package.'


  Design.remoteMethod 'generateDesign',
    accepts:
      arg: 'soundName'
      type: 'string'
    returns:[
      {
        arg: 'design'
        type: 'DesignEntry'
        root: true
      }
    ]
    http:
      path: '/generateDesign/:soundName'
      verb: 'get'

  Design.sendEmail = (id, email, cb)->
    Design.app.models.DesignEntry.findById id, (err, designEntry)->
      renderer = loopback.template(path.resolve(__dirname, './../../server/views/mail.ejs'))
      html = renderer({
        id: id
        img:designEntry.designPath
      })
      Design.app.models.Email.send {
          to: email
          from: "info@noisejewelry.com"
          subject: 'Check out you design'
          html: html
        }, (err) ->
          if err
            console.log err
            console.log '> sending booking confirmation Email to:', email
          cb null, designEntry
  
  Design.remoteMethod 'sendEmail',
    accepts:[
      {
        arg: 'id'
        type: 'string'
      },
      {
        arg: 'email'
        type: 'string'
      }
    ]
    returns:[
      {
        arg: 'design'
        type: 'DesignEntry'
        root: true
      }
    ]
    http:
      path: '/sendEmail/:id/:email'
      verb: 'get'