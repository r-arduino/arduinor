# remotes::install_github("rstudio/websocket")
library(websocket)

ws <- WebSocket$new("ws://192.168.49.140:81", autoConnect = F)
# ws <- WebSocket$new("ws://192.168.1.18:81", autoConnect = F)

ws$onOpen(function(event) {
  cat("Connection opened\n")
})
ws$onMessage(function(event) {
  cat(event$data, "\n")
})

ws$readyState()

# ws$onClose(function(event) {
#   cat("Client disconnected with code ", event$code,
#       " and reason ", event$reason, "\n", sep = "")
# })
# ws$onError(function(event) {
#   cat("Client failed to connect: ", event$message, "\n")
# })

ws$connect()
ws$close()



# Wait up to 5 seconds for websocket connection to be open.
poll_until_connected <- function(ws, timeout = 5) {
  connected <- FALSE
  end <- Sys.time() + timeout
  while (!connected && Sys.time() < end) {
    # Need to run the event loop for websocket to complete connection.
    later::run_now(0.1)
    
    ready_state <- ws$readyState()
    if (ready_state == 0L) {
      # 0 means we're still trying to connect.
      # For debugging, indicate how many times we've done this.
      cat(".")         
    } else if (ready_state == 1L) {
      connected <- TRUE
    } else {
      break
    }
  }
  
  if (!connected) {
    stop("Unable to establish websocket connection.")
  }
}

ws2 <- websocket::WebSocket$new("ws://192.168.49.140:81", autoConnect = FALSE) 
ws2$onMessage(function(event) {cat(event$data, "\n")})
ws2$connect()
poll_until_connected(ws2)
ws2$send("hello")
ws2$close()

devtools::install_github("ropenscilabs/webrockets")

con <- ws_connect("ws://192.168.49.140:81")

ws_receive(con, 0)


ws <- websocket::WebSocket$new("ws://0.0.0.0:8080",
                               onMessage = function(msg) {
                                 cat("Client got msg: ", msg, "\n")
                               },
                               onDisconnected = function() {
                                 cat("Client disconnected\n")
                               }
)

# A little example server that Winston made for testing.

library(httpuv)
cat("Starting server on port 8080...\n")
startServer("0.0.0.0", 8080,
            list(
              onHeaders = function(req) {
                # Print connection headers
                cat(capture.output(str(as.list(req))), sep = "\n")
              },
              onWSOpen = function(ws) {
                cat("Connection opened.\n")
                
                ws$onMessage(function(binary, message) {
                  cat("Server received message:", message, "\n")
                  ws$send(message)
                })
                ws$onClose(function() {
                  cat("Connection closed.\n")
                })
                
              }
            )
)
#stopAllServers()
