udp = require("dgram")

port = 8888
listener = udp.createSocket("udp4")

connections = { }

listener.on "listening", () ->
  console.log("Server is now listening on #{listener.address().address}:#{listener.address().port}")

listener.on "message", (data, publicInfo) ->
  try
    data = JSON.parse(data)
  catch e
    return console.log("Cannot parse given data #{e}: #{data}")

  if data.type is "register"
    connections[data.name] = {
      public: publicInfo
      private: data.privateInfo
    }
    console.log "New connection registered \"#{data.name}\""

  if data.type is "connect"
    if not connections[data.name]?
      send publicInfo, {
        type: "error"
        request: "connect"
        status: 404
      }

send = (connection, message, callback) ->
  data = new Buffer(JSON.stringify(message))

  listener.send data, 0, data.length, connection.port, connection.address, (err, bytes) ->
    if err?
      socket.close()
    else
      callback() if callback?

listener.bind(port, "127.0.0.1")