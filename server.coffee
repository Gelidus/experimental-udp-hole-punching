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

  if data.request is "register"
    if connections[data.name]?
      return send publicInfo, {
        request: "register"
        status: 409
      }

    connections[data.name] = {
      public: publicInfo
      private: data.private
    }

    # send registration successful
    console.log "New connection registered \"#{data.name}\""
    return send publicInfo, {
      request: "register"
      status: 200
    }

  if data.request is "connect"
    if not connections[data.name]?
      send publicInfo, {
        request: "connect"
        status: 404
      }
    else
      send publicInfo, {
        status: 200
        request: "connect"
        hosts: [{
          private: connections[data.name].private
          public: publicInfo
        }]
      }

      send connections[data.name].private, {
        status: 200
        request: "connect"
        hosts: [{
          private: data.private
          public: connections[data.name].public
        }]
      }

send = (connection, message, callback) ->
  data = new Buffer(JSON.stringify(message))

  listener.send data, 0, data.length, connection.port, connection.address, (err, bytes) ->
    if err?
      socket.close()
    else
      callback() if callback?

listener.bind(port, "127.0.0.1")