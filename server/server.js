'use strict';

var loopback = require('loopback');
var boot = require('loopback-boot');
require('coffee-script/register');
var app = module.exports = loopback();
var router = app.loopback.Router();
router.get('/', app.loopback.status());
process.env.NODE_TLS_REJECT_UNAUTHORIZED = "0";
var https = require('https')
app.start = function() {
  var sslConfig = require('./ssl/ssl-config.js');
  var options = {
    key: sslConfig.privateKey,
    cert: sslConfig.certificate,
    ca:[
      sslConfig.intermediatecert
    ]
  };
  var server = https.createServer(options, app);
  server.listen(app.get('port'), function() {
    var baseUrl = (true? 'http://' : 'https://') + app.get('host') + ':' + app.get('port');
    app.emit('started', baseUrl);
    console.log('LoopBack server listening @ %s%s', baseUrl, '/');
  });
};

// Bootstrap the application, configure models, datasources and middleware.
// Sub-apps like REST API are mounted via boot scripts.
boot(app, __dirname, function(err) {
  if (err) throw err;

  // start the server if `$ node server.js`
  if (require.main === module)
    app.start();
});
