udp = require("dgram")
tcp = require("net")

clientName = Math.floor((Math.random() * 5555)) + 1
connectionInfo = {
  address: "127.0.0.1"
  port: 8888
}

client = {
  ack: false
  connection: { }
}

socket = udp.createSocket("udp4")

getNetworkIP = (callback) ->
  tcpSock = tcp.createConnection(80, connectionInfo.address)
  tcpSock.on "connect", () ->
    callback(null, tcpSock.address().address) # return current addr

  tcpSock.on "error", (err) ->
    callback(err, "Error happened")

send = (connection, message, callback) ->
  data = new Buffer(JSON.stringify(message))

  socket.send data, 0, data.length, connection.port, connection.address, (err, bytes) ->
    if err?
      socket.close()
    else
      callback() if callback?

socket.on "listening", () ->
  getNetworkIP (err, ip) ->
    return console.log("Cannot obtain connection information #{err.message}") if err?
    send(connectionInfo, {
      type: "register"
      name: "client"
      privateInfo: {
        port: socket.address().port
        address: ip
      }
    })

socket.on "message", (data, publicInfo) ->
  try
    data = JSON.parse(data)
  catch e
    return console.log("Cannot parse given data #{e}: #{data}")

  if data.type is "error"
    console.log "Received error on request[#{data.request}] status[#{data.status}]"

socket.bind()