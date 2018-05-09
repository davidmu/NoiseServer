var path = require('path'),
fs = require("fs");
exports.privateKey = fs.readFileSync(path.join(__dirname, './design.noisejewelry.key')).toString();
exports.intermediatecert = fs.readFileSync(path.join(__dirname, './IntermediateCA.cer')).toString();
//exports.intermediatecert1 = fs.readFileSync(path.join(__dirname, './CACertificate-ROOT-2.cer')).toString();
exports.certificate = fs.readFileSync(path.join(__dirname, './ssl_certificate.cer')).toString();
