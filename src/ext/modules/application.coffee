applicationContext = require("./application-context")
proxy = require('./proxy')
qioFrame = require('../../qio/qio-frame')

exports.init = (_) ->
  applicationContext.init _
  proxy.init _
  qioFrame.init _

