-- ------------------------------------------------------------------------- --
-- aiko_configuration.lua
-- ~~~~~~~~~~~~~~~~~~~~~~
-- Please do not remove the following notices.
-- Copyright (c) 2009-2010 by Geekscape Pty. Ltd.
-- Documentation:  http://groups.google.com/group/aiko-platform
-- License: GPLv3. http://geekscape.org/static/arduino_license.html
-- Version: 0.3

--------------------------------------------------------------------------
-- Aiko-Gateway: Name of this system (also used by Smart Energy Groups) --
--------------------------------------------------------------------------
  aiko_gateway_name = "unknown"

-------------------------------------------------------------------------
-- Smart Energy Groups: Your unique identifier for the web service API --
-------------------------------------------------------------------------
  site_token = "site_unknown"

-- Aiko-Node: Serial connection sample time
  serial_timeout_period = 15.0  -- seconds

-- Aiko-Gateway: Heartbeat rate
 heartbeat_rate = 60 / serial_timeout_period -- Every 60 seconds

----------------------------------------------------
-- Aiko-Node: "Serial to Network" host IP address --
----------------------------------------------------
  if (is_production()) then                  -- Running on Aiko-Gateway router
    aiko_gateway_address = "127.0.0.1"       -- Safer to avoid hostname lookup
    debug = false
  else                                       -- Running on Desktop / Laptop
    aiko_gateway_address = "127.0.0.1"
    debug = true
  end

-----------------------------------------
-- Twitter search and display messages --
-----------------------------------------
  twitter_flag = false

  if (twitter_flag) then
    twitter_throttle = 6           -- How often to invoke API (1 = every time)
    twitter_rpp      = 2           -- If more than 10, will be multiple pages
    twitter_search   = "aiko"
    twitter_since_id = 5097565461  -- TODO: Start this at "0"

    led_sign_flag = false          -- Send message to ZigBee LED sign
  end
