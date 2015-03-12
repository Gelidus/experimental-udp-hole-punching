udp = require("dgram")
tcp = require("net")

clientName = Math.floor((Math.random() * 5555)) + 1
connectionInfo = {
  address: "127.0.0.1"
  port: 8888
}

serviceName = "myService"

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
    console.log "Obtained address of this service #{ip}:#{socket.address().port}"
    send(connectionInfo, {
      request: "register"
      status: 200
      name: serviceName
      private: {
        port: socket.address().port
        address: ip
      }
    })

socket.on "message", (data, publicInfo) ->
  try
    data = JSON.parse(data)
  catch e
    return console.log("Cannot parse given data #{e}: #{data}")

  if data.status isnt 200
    if data.request is "register" and data.status is 409 # not successful register, we want to connect to existing node
      getNetworkIP (err, ip) ->
        return send connectionInfo, {
          request: "connect"
          status: 200
          name: serviceName
          private: {
            port: socket.address().port
            address: ip
          }
        }

    return console.log "Received error on request[#{data.request}] status[#{data.status}]"

  if data.request is "register"
    console.log "Registration successful"

  if data.request is "connect"
    for host in data.hosts
      console.log "Connecting to #{host.private.address}:#{host.private.port}"

      send host.private, {
        request: "ack"
        status: 200
      }

  if data.request is "ack"
    console.log "Got ack from #{publicInfo.address}:#{publicInfo.port}"

socket.bind()