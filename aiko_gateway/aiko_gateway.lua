#!/usr/bin/lua
-- ------------------------------------------------------------------------- --
-- aiko_gateway.lua
-- ~~~~~~~~~~~~~~~~
-- Please do not remove the following notices.
-- Copyright (c) 2009 by Geekscape Pty. Ltd.
-- Documentation:  http://groups.google.com/group/aiko-platform
-- License: GPLv3. http://geekscape.org/static/arduino_license.html
-- Version: 0.3
-- ------------------------------------------------------------------------- --
-- See Google Docs: "Project: Aiko: Stream protocol specification"
-- Currently requires an Aiko Gateway (indirect mode only).
-- ------------------------------------------------------------------------- --
--
-- Custom configuration: See "aiko_configuration.lua".
--
-- ToDo: Aiko Gateway
-- ~~~~~~~~~~~~~~~~~~
-- - Put protocol version into boot message to Aiko-Node and web service.
-- - Verify protocol version in the Aiko-Node boot message.
--   - Send tweet to owner, if newer software versions are available.

-- - Re-open serial network port 2000, if it closes.
-- - Listen on socket for commands to Aiko-Gateway.
-- - Migrate Twitter LED sign support to Aiko-Node.
-- - Support Aiko-Gateway router and Arduino as a "single" node.
--   - "eek_1" consists of "eek_1.gateway" and "eek_1.node".
-- - Deliver commands from web server to specific Aiko-Nodes.
-- - Aiko-Gateway I/O commands for display, alert, view, menu, etc.

-- - Does "http" variable need to be local, or can it be global ?
-- - Start using XPlanner !
-- * Unit test S-Expressions using "curl" !
-- * Transmit dummy test S-Expressions to http://watchmything.com.
--   * Heart-beat: (site SiteId (node NodeName TimeStamp))
--   * Stream: (site SiteId (node NodeName TimeStamp (StreamName Value Unit)))
-- * Wrap messages with "(site SITE_TOKEN ...)".
-- - Create aiko_gateway.sh, setting environment variables and background run.
-- - Put all configuration parameters into a table.
-- - Command line options: Host/Port, Help and Version.
-- - Handle multiple connected AikoNodes, e.g. Ethernet and ZigBee.
-- - Lua / Lua-Socket co-routines for non-blocking I/O.
-- - Parse S-Expression messages, match open-close brackets (as per Aiko in C).
--   - Use LPeg (Parsing Expression Grammars For Lua) ?
--     See http://www.inf.puc-rio.br/~roberto/lpeg
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
-- - Handle "debug messages" from Aiko-Node, e.g. "; Lisp comment :)"

-- (status okay)
-- (status error "message")
-- (node pebble_1 2009-09-23T16:00:00 (relay true nil))
-- (node pebble_2 2009-09-23T16:00:00 (relay false nil))
-- (node pebble_2 2009-09-23T16:00:00 (display "Message string"))

-- ToDo: Aiko Node
-- ~~~~~~~~~~~~~~~
-- - Start using XPlanner !
-- * New S-Expression message format.
--   - Idempotent: Using TimeStamp or ?unique_number (boot count in EEPROM ?).
-- - Send "debug messages" as "; Lisp comments :)"
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

-- LPeg (Parsing Expression Grammars For Lua)
-- http://www.inf.puc-rio.br/~roberto/lpeg
-- ------------------------------------------------------------------------- --

-- TODO: Move functions into a library file -- dofile(FILENAME) or require() ?

function current_directory()
  return(os.getenv("PWD"))
end

-- ------------------------------------------------------------------------- --

function is_production()
-- TODO: Use an environment variable to specify deployment type.

  return(os.getenv("USER") == "root") -- Assume logged in as "root" on OpenWRT
end

-- ------------------------------------------------------------------------- --

function table_to_string(table)
  local result = ''

  if (type(table) == 'table') then
    result = '{ '

    for index = 1, #table do
      result = result .. table_to_string(table[index])
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

function url_encode(value)
  if (value) then
    value = value:gsub("\n", "\r\n")
    value = value:gsub("([^%w ])",
      function (c) return string.format ("%%%02X", string.byte(c)) end)
    value = value:gsub(" ", "+")
  end

  return(value)
end

-- ------------------------------------------------------------------------- --

function use_production_server()
  local web_host_name = "api.smartenergygroups.com"
--local web_host_name = "api.watchmything.com"

  url = "http://" .. web_host_name .. "/api_sites/stream"

  file_name = current_directory() .. "/data/aiko_test1.data"

  method       = "PUT"
  content_type = "application/x-www-form-urlencoded"
end

-- ------------------------------------------------------------------------- --

function use_development_server()
--local web_host_name = "192.168.0.109:8080"  -- "stormac:8080"
  local web_host_name = "tuxu"

  url = "http://" .. web_host_name .. "/meemplex/rest/device/"

  file_name = current_directory() .. "/data/aiko_test2.data"

  method       = "POST"
  content_type = "application/xml"
end

-- ------------------------------------------------------------------------- --

function use_php_debug_server()
  use_production()

  url = "http://localhost/~andyg/php/examine_request.php"
end

-- ------------------------------------------------------------------------- --

function custom_sink()
  return function(chunk, error)
    if (not chunk) then
      return(1)
    else
      return(print(chunk))
    end
  end
end

-- ------------------------------------------------------------------------- --

send_message_disabled = false

function send_message(message)
  local http = require("socket.http")
  local response = {}

  if (send_message_disabled) then return end

  if (debug) then print("-- send_message(): start") end

--local body, code, headers, status = http.request(url, "keyword=value")

  local body, code, headers, status = http.request {
    url = url,
    method = method,
    headers = {
      ["content-length"] = message:len(),
      ["content-type"]   = content_type
    },
--  source = ltn12.source.file(io.open(file_name, "r")),
    source = ltn12.source.string(message),
--  sink = ltn12.sink.file(io.stdout)
    sink = ltn12.sink.table(response)
--  sink = custom_sink()
  }

  if (body == nil) then
    print("Error: ", code)
  else
    if (debug) then
-- TODO: Check status code for success or failure
      print("Body:     ", body)  -- Will equal "1", if generic method is used
      print("Code:     ", code)
      print("Headers:  ", table_to_string(headers))
      print("Status:   ", status)
      print("Response: ", table_to_string(response))
    end
  end

  if (response == nil) then
    print("Error: No HTTP response body")
  else
    response = table.concat(response)

    if (response:sub(1, 6) == "(node ") then
      if (debug) then print("-- send_message(): command received") end

      local start, finish = response:find("\n", 1, PLAIN)
      local message = response:sub(1, start - 1)
      response = response:sub(finish + 1)
      local command = nil

-- message = "(display \"Hello, world !\" nil)" -- Test display command
-- message = "(relay true nil)"                 -- Test relay command

      start, finish = message:find("(display ", 1, PLAIN)
      if (start ~= nil) then
        start, finish = message:find("\"", start, PLAIN)
        finish = message:find("\"", start + 1, PLAIN)
        local buffer = message:sub(start + 1, finish - 1)
        command = "(display \"" .. buffer .. "\")"
      end

      start, finish = message:find("(relay ", 1, PLAIN)
      if (start ~= nil) then
        local state = "off"
        if (message:find("true", start, PLAIN)) then state = "on" end
        command = "(relay " .. state .. ")"
      end

      if (command) then
        if (debug) then print("-- send message(): command: ", command) end
        serial_client:send(command .. ";\n")
      end
    end

-- Check response wrapped by site command, e..g (site= new_site_token)
    if (response:sub(1, 7) == "(site= ") then
      local start, finish = response:find("\n", 1, PLAIN)
      local message = response:sub(1, start - 1)
      response = response:sub(finish + 1)

-- Parse and save new site token
      save_site_token(message:sub(8, -2))
      if (debug) then
        print("-- parse_message(): new site token: " .. site_token)
      end
    end

    if (response == "(status okay)") then
      if (debug) then print("-- send_message(): status: okay") end
    elseif (response:sub(1, 14) == "(status error ") then
      local error = response:sub(15, -2)

      if (error == "no_site_token") then
        site_discovery_timeout()
      else
        print("Status: Error: ", error)
      end
    else
      print("Error: HTTP response: ", response)
    end
  end

  if (debug) then print("-- send_message(): end") end
end

-- ------------------------------------------------------------------------- --

function send_event_boot(node_name)
  if (debug) then print("-- send_event_boot(): " .. node_name) end

  message = "(status boot 0.3)"
  send_message(wrap_message(message, node_name))
end

-- ------------------------------------------------------------------------- --

function send_event_heartbeat(node_name)
  if (debug) then print("-- send_event_heartbeat(): " .. node_name) end

--message = "(cpu_usage 0 %) (node_count 1 number)"
  message = "(status heartbeat)"
  send_message(wrap_message(message, node_name))
end

-- ------------------------------------------------------------------------- --

function save_site_token(new_site_token)
  if (new_site_token ~= site_token) then
    site_token = new_site_token

    local output = assert(io.open("aiko_configuration.lua", "a"))
    output:write("  site_token = \"" .. site_token .. "\"\n")
    assert(output:close())

    if (debug) then print("-- save_site_token(): saved " .. site_token) end
  end
end

-- ------------------------------------------------------------------------- --

site_discovery_timer = 0

function site_discovery_timeout()
  if (debug) then print("-- site_discovery_timeout():") end

  if (site_discovery_timer == 0) then
    site_discovery_timer = os.time() + site_discovery_gracetime
  else
    if (os.time() > site_discovery_timer) then
      send_message_disabled = true
      if (debug) then print("-- site_discovery_timeout(): expired") end
    end
  end
end

-- ------------------------------------------------------------------------- --

function heartbeat_handler()
  local throttle_counter = 1 -- Always start with a heartbeat

  while (true) do
    throttle_counter = throttle_counter - 1

    if (throttle_counter <= 0) then
      throttle_counter = heartbeat_rate

      send_event_heartbeat(aiko_gateway_name)
    end

    coroutine.yield()
  end
end

-- ------------------------------------------------------------------------- --

function send_file(node_name, file_name)
  if (debug) then print("-- send_file(" .. file_name .. "):") end

  file = io.input(file_name)
  message = io.read("*all")
  send_message(wrap_message(message, node_name))
end

-- ------------------------------------------------------------------------- --

function wrap_message(message, node_name)
  local timestamp = "?"

  return(
    "data_post=" ..
    "(site " .. site_token ..
    "  (node " .. node_name .. " " .. timestamp ..
    "    " .. message .. "))"
  )
end

-- ------------------------------------------------------------------------- --

function serial_handler()
  serial_client = socket.connect(aiko_gateway_address, 2000)
  serial_client:settimeout(serial_timeout_period)  -- 0 --> non-blocking read

--serial_client:send("")

  local stream, status, partial

  while (status ~= "closed") do
    stream, status, partial = serial_client:receive(16768)  -- (1024)

    if (debug) then
      if (status == "timeout") then
        print("Aiko status: bytes received: ", partial:len())
      else
        print("Aiko status: ", status)
      end
    end
--[[
    print ("Aiko stream:  ", stream)  -- TODO: if not "nil" then catenate
    print ("Aiko partial: ", partial) -- TODO: if not "nil" then got everything
]]
    if (partial ~= nil and partial:len() > 0) then
      parse_message(partial)
    end

    if (status == "timeout") then
      coroutine.yield()
    end
  end

  serial_client:close()
end

-- ------------------------------------------------------------------------- --

-- TODO: Move parser into a library file.

-- TODO: Need to assume that we won't get a complete, well-formed message !
-- TODO: Check for partial messages and catenat them, if necessary
-- TODO: Any left-over data (no trailing CR) should be kept for next time !
-- TODO: Implement incomplete message timeout

function parse_message(buffer)
  if (debug) then print("-- parse_message(): start") end

-- Parse individual Aiko-Node messages, delimited by "carriage return"
  for message in buffer:gmatch("[^\r\n]+") do

-- Check message properly framed, e.g. (message)
    if (message:sub(1, 1) ~= "("  or  message:sub(-1) ~= ")") then
      print("-- parse_message(): ERROR: Message not delimited by ()")
      if (debug) then print("-- message: ", message) end
    else

-- Check message wrapped by node name, e..g (node name ...)
      if (message:sub(1, 6) ~= "(node ") then
        print("-- parse_message(): ERROR: Message doesn't start with 'node'")
        if (debug) then print("-- message: ", message) end
      else

-- Parse node name
        local node_name = nil
        local start, finish = message:find('?', 7, PLAIN)

        if (start ~= nil) then
          node_name = message:sub(7, start - 2)
          if (debug) then print("-- parse_message(): node: " .. node_name) end
        end

        if (node_name == nil) then
          print("-- parse_message(): ERROR: Couldn't parse node name")
        else

          local token = message:sub(finish + 1, finish + 2)
          if (token == " )") then
-- Node heart-beat message, ignore for the moment
          else
            if (token == " (") then
-- Node message containing state update
              message = message:sub(finish + 2, -2)
              if (debug) then print("-- parse_message(): event: ", message) end

              send_message(wrap_message(message, node_name))
            else
              print("-- parse_message(): ERROR: Problem after the node name")
            end
          end
        end
      end
    end
  end

  if (debug) then print("-- parse_message(): end") end
end

-- ------------------------------------------------------------------------- --

-- TODO: Move into a library file.

-- Control Amplus LED signs
-- See http://freezerpants.com/toledo

-- if (arg[1]) then text = arg[1] end

floor = math.floor

function bxor(a,b)
  local r = 0
  for i = 0, 31 do
    local x = a / 2 + b / 2
    if x ~= floor (x) then
      r = r + 2^i
    end
    a = floor (a / 2)
    b = floor (b / 2)
  end

  return(r)
end

function led_sign_display(text)
  local output = true

  local id     = "00" -- Sign id: Default 00
  local line   = "1"  -- Line to program: Default 1
  local page   = "A"  -- Page to program: A - Z
  local intro  = "<FE>"

--  1: FA: immediate
--  2: FB: xopen
--  3: FC: curtain up
--  4: FD: curtain down
--  5: FE: scroll left
--  6: FF: scroll right
--  7: FG: vopen
--  8: FH: vclose
--  9: FI: scroll up
-- 10: FJ: scroll down
-- 11: FK: hold
-- 12: FL: snow
-- 13: FM: twinkle
-- 14: FN: block move
-- 15: FP: random
-- 16: FR: cursive welcome
  local speed    = "<MA>" -- 1:Mq, 2:Ma, 3:MQ, 4:MA (slowest to fastest)
  local exit     = "<FE>"
-- As per "intro", but only 1:FA through to 11:FK
  local bell     = "" -- 0: no bell, 1:BA 0.5s, 2:BB 1.0s, 3:BC 1.5s, 4:BD 2.0s
  local colour   = "" -- 0: no colour
-- red:     CA
-- orange:  CH
-- green:   CD
-- iorange: CN
-- igreen:  CM
-- ired:    CL
-- rog:     CP
-- gor:     CQ
-- ryg:     CR
-- rainbow: CS
  local dFlag    = "" -- 0: no date, 1: KD (date)
  local tFlag    = "" -- 0: no time, 1: KT (time)
  local fontFlag = "<AC>"  -- 1=AC, 2=AA, 3=AB, 4=AF, 5=AD

  local message = string.format("<L%s><P%s>%s%s<WC>%s%s%s%s%s%s%s",
    line, page, intro, speed, exit, bell, colour, dFlag, tFlag, fontFlag, text)

  local checksum = 0
  for index = 1, message:len() do
    checksum = bxor(checksum, message:byte(index))
  end

  message = string.format("<ID%s>%s%02X<E>", id, message, checksum)

  if (output) then
    if (debug) then print(message) end
--  local serial_client = socket.connect("localhost", 2000)
    serial_client:send(message .. "\n")
--  serial_client:close()
  end
end

-- link()
-- message = string.format("<TA>00010100009912302359%s", "ABCD")
-- message = strong.format("<ID%s>%s%s<E>", id, message, checksum)

-- ------------------------------------------------------------------------- --

-- TODO: Move into a library file.

-- http://apiwiki.twitter.com/Twitter-Search-API-Method%3A-search
--
-- http://it-box.blogturk.net/2009/01/08/how-to-hack-twitter-with-a-few-lines-of-lua-code

function twitter_query()
  require("json")

  local http = require("socket.http")
  local request = "http://search.twitter.com/search.json?q=%s&since_id=%s&rpp=10"
  local throttle_counter = 1     -- Always start with a Twitter query

  while (true) do
    print("-- twitter_query(): TIMER")
    throttle_counter = throttle_counter - 1

    if (throttle_counter <= 0) then
      throttle_counter = twitter_throttle

      local relay_state = false  -- TODO: Cache this, reduce messages
      command = "(relay off)"    -- TODO: Don't need to send this every time !
      if (debug) then print("-- send message(): command: ", command) end
--    serial_client:send(command .. ";\n")

      print("-- twitter_query(): QUERY: ", twitter_search)
      local response = http.request(string.format(request, url_encode(twitter_search), twitter_since_id))

      print("-- twitter_query(): RESPONSE")

-- TODO: Remove "\r\n" from "response"

      local latest_from_user  = nil
      local latest_created_at = nil
      local latest_text       = nil

      for index, value in pairs(json.decode(response)) do
--      print("index: ", index)
--      print("value: ", value)

        if (index == "max_id") then
          twitter_since_id = value
          print("-- twitter_query(): new_since_id: ", twitter_since_id)
        end

        if (type(value) == 'table') then
          for index2 = 1, #value do
            relay_state = true

            print("- - - - - - - - - - - - - - - - - - - -")
            local new_since_id = value[index2].id 

            if (new_since_id > twitter_since_id) then
              twitter_since_id = new_since_id
              print("-- twitter_query(): new_since_id: ", twitter_since_id)
            end

            local from_user  = value[index2].from_user 
            local created_at = value[index2].created_at
            local text       = value[index2].text

            if (latest_from_user == nil) then
              latest_from_user = from_user
              latest_created_at = created_at
              latest_text      = text
            end

            print("Twitter: From user: ", from_user)
            print("Twitter: Date/Time: ", created_at)
            print("Twitter: Message:   ", text)

--          for index3, value3 in pairs(value[index2]) do
--            print("  index3: ", index3)
--            print("  value3: ", value3)
--          end
          end
        end
      end

      if (relay_state) then
        command = "(relay on)"
        if (debug) then print("-- send message(): command: ", command) end
--      serial_client:send(command .. ";\n")
      end

      if (led_sign_flag) then
        if (latest_from_user ~= nil) then
          led_sign_display(" ")
          led_sign_display("[" .. latest_from_user .. "] " .. latest_text)
--        led_sign_display(latest_from_user .. ": " .. latest_text:sub(1, 16))
        end
      end
    end

    coroutine.yield()
  end
end

-- ------------------------------------------------------------------------- --

function initialize()
  PLAIN = 1  -- string.find() pattern matching off

  use_production_server()   -- Smart Energy Groups web service
--use_development_server()  -- Watch My Thing on ekoLiving network (aka "tuxu")
--use_php_debug_server()    -- Reflects HTTP request details in the response
end

-- ------------------------------------------------------------------------- --

print("[Aiko-Gateway V0.3 2010-09-23]")

if (not is_production()) then require("luarocks.require") end
require("socket")
require("io")
require("ltn12")
--require("ssl")

require("aiko_configuration")  -- Aiko-Gateway configuration file

initialize()

-- send_file("pebble_1", file_name)  -- Primarily for testing

-- TODO: Keep retrying boot message until success (OpenWRT boot sequence issue)
  send_event_boot(aiko_gateway_name)

coroutine_heartbeat = coroutine.create(heartbeat_handler)

-- TODO: Handle incorrect serial host_name, e.g. not localhost -> fail !
coroutine_serial = coroutine.create(serial_handler)

if (twitter_flag) then coroutine_twitter = coroutine.create(twitter_query) end

while (coroutine.status(coroutine_serial)) ~= "dead" do
  if (debug) then print("-- coroutine.resume(coroutine_heartbeat):") end
  coroutine.resume(coroutine_heartbeat)

  if (debug) then print("-- coroutine.resume(coroutine_serial):") end
  coroutine.resume(coroutine_serial)

  if (twitter_flag) then
    if (debug) then print("-- coroutine.resume(coroutine_twitter):") end
    coroutine.resume(coroutine_twitter)
  end
end
