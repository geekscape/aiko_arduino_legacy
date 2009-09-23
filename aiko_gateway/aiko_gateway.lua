#!/usr/bin/lua
-- --------------------------------------------------------------- --
-- See Google Docs: "Project: Aiko: Stream protocol specification" --
-- --------------------------------------------------------------- --

-- ToDo: Aiko Gateway
-- ~~~~~~~~~~~~~~~~~~
-- - Start using XPlanner !
-- * Unit test S-Expressions using "curl" !
-- * Transmit dummy test S-Expressions to http://watchmything.com.
--   * Heart-beat: (site SiteId (node NodeName TimeStamp))
--   * Stream: (site SiteId (node NodeName TimeStamp (StreamName Value Unit)))
-- * Wrap messages with "(site SITE_TOKEN ...)".
-- - Create aiko_gateway.sh, setting environment variables and background run.
-- - Put all configuration parameters into a table.
-- - Change "message" from being global, to being passed as a parameter.
-- - Command line options: Host/Port, Help and Version.
-- - Handle multiple connected AikoNodes, e.g. Ethernet and ZigBee.
-- - Lua / Lua-Socket co-routines for non-blocking I/O.
-- - Parse S-Expression messages, match open-close brackets (as per Aiko in C).
-- - Maintain last message timestamp for idempotent message check.
-- - Transmit dummy test S-Expressions to http://geekscape.org (Play!, JAX-RS).
-- - LuCI web server integration, e.g. monitor, control, configure, statistics.
-- - SSL connection to https://watchmything.com.
-- - Create Google Doc: Project: Aiko Gateway (AG): Sub-system design.
-- - Error responses from WatchMyThing.com should be machine parsable.
-- - Convert S-Expressions into JSON and vice-versa.
-- - Implement JSON-RPC client (for WatchMyThing.com) and server (for AikoJ).
-- - Investigate using XMPP.
-- - Handle some messages from Aiko, e.g. errors, provide date/time.

-- ToDo: Aiko Node
-- ~~~~~~~~~~~~~~~
-- - Start using XPlanner !
-- * New S-Expression message format.
--   - Idempotent: Using TimeStamp or ?unique_number (boot count in EEPROM ?).
-- - Ignore OpenWRT boot messages and wait for Ser2Net start message.
-- - Implement "(http on)" and "(http off)" to enable HTTP headers.
-- - Implement "(error on)" and "(error off)" to enable error messages.
-- - Configuration in EEPROM, e.g nodeName, devices, networking, site token.
-- - Profile negotiation, i.e like Telnet negotiation.
-- - Message optimatization, including "transducer identifier" (integer).
-- - Messages ...
--   - (temperature xx.x C)
--   - (light xxx lux)
--   - (button1 on ?)  (button2 on ?)  (button3 on ?)
--   - (relay1 on  ?)  (relay2  on ?)
--   - (sound NOTE ?)
--   - (alert MESSAGE TIME-TO-LIVE) --> LCD screen.
--   - (clock= YYYY-MM-DDThh:mm:ss) --> EEPROM.
--   - (node_name= NODE-NAME) --> LCD screen.
--   - (profile= PROFILE-NAME)
--   - (schedule= SCHEDULE) --> EEPROM.
--   - (serial_number= SERIAL_NUMBER) --> EEPROM.
-- - Nintendo TouchPanel for ASUS-WL500G.
-- - Create Google Doc: Project: Aiko: Sub-system design.

-- ToDo: Miscellaneous
-- ~~~~~~~~~~~~~~~~~~~
-- - Desktop / laptop version: Provide WxLua GUI.

-- ------------------------------------------------------------------------- --
-- TableSerialization
-- http://lua-users.org/wiki/TableSerialization

-- Network support for the Lua language
-- http://www.tecgraf.puc-rio.br/~diego/professional/luasocket
-- http://www.tecgraf.puc-rio.br/~diego/professional/luasocket/http.html
-- HTTP/1.1 standard, RFC 2616
--   http://tools.ietf.org/html/rfc2616
-- HTTP Basic Authentication Scheme, RFC 2617
--   http://tools.ietf.org/html/rfc2617
-- URLs must conform to RFC 1738
--   http://tools.ietf.org/html/rfc1738
--   [http://][<user>[:<password>]@]<host>[:<port>][/<path>]

-- Using the socket library to read a web page (GOOD)
-- http://www.wellho.net/resources/ex.php4?item=u116/webclient

-- LUA SocketLib and the Coroutines
-- http://www.ozone3d.net/tutorials/lua_socket_lib.php

-- LuaSec – TLS/SSL Support for Lua
-- http://www.inf.puc-rio.br/~brunoos/luasec

-- HowTo: Using the JSON-RPC API
-- http://luci.freifunk-halle.net/Documentation/JsonRpcHowTo
-- ------------------------------------------------------------------------- --

-- TODO: Move functions into a library file -- dofile(FILENAME) or require() ?

function currentdir()
  return(os.getenv("PWD"))
end

-- ------------------------------------------------------------------------- --

function isProduction()
-- TODO: Use an environment variable to specify deployment type.

  return(os.getenv("USER") == "root") -- Assume logged in as "root" on OpenWRT
end

-- ------------------------------------------------------------------------- --

function tableToString(table)
  local result = ''

  if (type(table) == 'table') then
    result = '{ '

    for index = 1, #table do
      result = result .. tableToString(table[index])
      if (index ~= #table) then
        result = result .. ', '
      end
    end

    result = result .. ' }'
  else
    result = tostring(table)
  end

  return(result)
end

-- ------------------------------------------------------------------------- --

function use_production_server()
--local web_host_name = "api.smartenergygroups.com"
  local web_host_name = "api.watchmything.com"

  url = "http://" .. web_host_name .. "/api_sites/stream"

  file_name = currentdir() .. "/data/aiko_test1.data"

  method       = "PUT"
  content_type = "application/x-www-form-urlencoded"
end

-- ------------------------------------------------------------------------- --

function use_development_server()
--local web_host_name = "192.168.0.109:8080"  -- "stormac:8080"
  local web_host_name = "tuxu"

  url = "http://" .. web_host_name .. "/meemplex/rest/device/"

  file_name = currentdir() .. "/data/aiko_test2.data"

  method       = "POST"
  content_type = "application/xml"
end

-- ------------------------------------------------------------------------- --

function use_php_debug_server()
  use_production()

  url = "http://localhost/~andyg/php/examine_request.php"
end

-- ------------------------------------------------------------------------- --

function send_message()
  local http = require("socket.http")

  if (debug) then print("-- send_message(): start") end

--local body, code, headers, status = http.request(url, "keyword=value")

  local body, code, headers, status = http.request {
    url = url,
    method = method,
    headers = {
      ["content-length"] = string.len(message),
      ["content-type"]   = content_type
    },
--  source = ltn12.source.file(io.open(file_name, "r")),
    source = ltn12.source.string(message),
--  sink = ltn12.sink.file(io.stdout)
  }

-- TODO: This code doesn't run if http.request(sink=) specified ?

  if (body == nil) then
    print("Error: ", code)
  else
    if (debug) then
-- TODO: Check status code for success or failure
--    print("Response: ", body)  -- Will equal "1", if generic method is used
--    print("Code:     ", code)
--    print("Headers:  ", tableToString(headers))
--    print("Status:   ", status)
    end
  end

  if (debug) then print("-- send_message(): end") end
end

-- ------------------------------------------------------------------------- --

function send_event_boot(node_name)
  if (debug) then print("-- send_event_boot(): " .. node_name) end

  message = "(boot_event 0 number)"
  wrap_message(node_name)
  send_message()
end

-- ------------------------------------------------------------------------- --

function send_event_heartbeat(node_name)
  if (debug) then print("-- send_event_heartbeat(): " .. node_name) end

  message = "(cpu_usage 5 %) (node_count 1 number)"
  wrap_message(node_name)
  send_message()
end

-- ------------------------------------------------------------------------- --

function send_file(node_name, file_name)
  if (debug) then print("-- send_file(" .. file_name .. "):") end

  file = io.input(file_name)
  message = io.read("*all")
  wrap_message(node_name)
  send_message()
end

-- ------------------------------------------------------------------------- --

function wrap_message(node_name)
-- TODO: Global variable "message" should be a parameter.

  local timestamp = "?"

  message =
    "data_post=" ..
    "(site " .. site_token ..
    "  (node " .. node_name .. " " .. timestamp ..
    "    " .. message .. "))"
end

-- ------------------------------------------------------------------------- --

function serial_handler()
  local client = socket.connect(aiko_gateway_address, 2000)
  client:settimeout(5.0)  -- settimeout(0) --> non-blocking read

--client:send("")

  local stream, status, partial

  while (status ~= "closed") do
    stream, status, partial = client:receive(16768)  -- (1024)

    if (debug) then print ("Aiko status:  ", status) end
--[[
    print ("Aiko stream:  ", stream)  -- TODO: if not "nil" then catenate
    print ("Aiko partial: ", partial) -- TODO: if not "nil" then got everything
]]
    if (partial ~= nil and string.len(partial) > 0) then
      read_message(partial)
    end

    if (status == "timeout") then
      coroutine.yield()
    end
  end

  client:close()
end

-- ------------------------------------------------------------------------- --

-- TODO: Move parser into a library file.

NULL  = '0x00'  -- Null character
STX   = '0x02'  -- Start of TeXt
ETX   = '0x03'  -- End of TeXt
HT    = '0x09'  -- Horizontal Tab
LF    = '0x10'  -- Line Feed
CR    = '0x13'  -- Carriage Return
SPACE = '0x20'  -- Space bar
LBRAC = '0x28'  -- Left bracket '('
RBRAC = '0x29'  -- Right bracket ')'

-- TODO: Need to assume that we won't get a complete, well-formed message !
-- TODO: Implement incomplete message timeout

function read_message(buffer)
  if (debug) then print("-- read_message(): start") end

-- TODO: Check for partial messages and catenat them, if necessary

  local position = 1

  if (string.sub(buffer, position, 6) == "(node ") then
    start, finish = string.find(buffer, ')', 7, 1)

    if (start ~= nil) then
      aiko_node_name = string.sub(buffer, 7, start - 1)

      if (debug) then
        print("-- read_message(): node_name: " .. aiko_node_name)
      end

      position = finish + 2
    end
  end

  if (position < string.len(buffer)) then
    message = string.sub(buffer, position, string.len(buffer) - 1)

    if (string.len(message) < 100) then  -- TODO: Remove nasty hack !!
      if (aiko_node_name == "unregistered") then
        print("-- read_message(): ERROR: aiko_node_name is 'unregistered'")
      else
        if (debug) then print("-- read_message(): message: " .. message) end
        wrap_message(aiko_node_name)
        send_message()
      end
    end
  end

  if (debug) then print("-- read_message(): end") end
end

-- ------------------------------------------------------------------------- --

function initialize()
-- TODO: "site_token" shouldn't be hard-coded.
  site_token = "site_26d5b48f00d1a0d9978f7958615ba40c12cbd763"
  aiko_node_name = "unregistered"
  aiko_gateway_name = "otage" -- "bifi"

  if (isProduction()) then
    aiko_gateway_address = "localhost"
    debug = true
  else
--  aiko_gateway_address = "192.168.0.92"     -- otage @ ekoLiving network
    aiko_gateway_address = "192.168.192.152"  -- otage @ geekscape network
    debug = true
  end

--use_development_server()  -- "tuxu" on ekoLiving network
  use_production_server()   -- Watch My Thing
--use_php_debug_server()    -- Reflects HTTP request details in the response
end

-- ------------------------------------------------------------------------- --

require("socket")
require("io")
require("ltn12")
--require("ssl")

initialize()

--send_file("pebble_1", file_name)  -- Primarily for testing

-- TODO: Keep retrying boot message until success (OpenWRT book sequence issue)
send_event_boot(aiko_gateway_name)

-- TODO: Create co-routine to periodically send heartbeat.
send_event_heartbeat(aiko_gateway_name)

-- TODO: Handle incorrect serial host_name, e.g. not localhost -> fail !
coroutine_serial = coroutine.create(serial_handler)

while (coroutine.status(coroutine_serial)) ~= "dead" do
  if (debug) then print("-- coroutine.resume(coroutine_serial):") end
  coroutine.resume(coroutine_serial)
end
