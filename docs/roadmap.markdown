Aiko Roadmap
=============

*   [Tasks](#tasks)
*   [Devices](#devices)
*   [To Do](#todo)

<h2 id="tasks">Tasks</h2>

*   Timer improvements

*   Error handling

    Use function return code or call error handler ?

*   Communications
    *   USB bi-directional (USB, VirtualWire, ZigBee, Bluetooth)
    *   Ethernet ...
       *   Bi-directional
       *   Socket Client or Server
       *   HTTP: Client only
       *   DHCP client ?

*   Command handler / Parser
    *   Design principles ...
       *   Per Arduino unique identifier
       *   Discovery
       *   URL for MeemPlex configuration description
    *   Commands for Ethernet static configuration

*   LCD ...
    *   6-pin version
    *   3-pin version
    *   Clock / Timer display
    *   Display mode (switch via control button
    *   Command button (single or multiple ?)
    *   Command mode

*   Home Energy Monitor integration

<h2 id="devices">Devices</h2>

*   Temperature sensor ...
    *   Dallas Semiconductor 18B20
    *   Analogue
*   Potentiometer
*   Light sensor
*   Accelerometer
*   Pressure sensor
*   Storage (for telemetry)
*   Servo motors
*   Battery monitor

<h2 id="todo">To Do</h2>

*   Documentation ...
    *   Improve README.markdown
    *   docs/* files
*   Examples
*   Testing
*   Tutorials
*   Put copyright / license notices in each file
*   Lilypad / Accelerometer => Apple remote control hack


Development Guidelines
======================

Design guidelines
-----------------

Should be able to pull in just the individual parts of the framework you need

Should generally optimise for memory usage (flash and SRAM) over computation
time


Code style
----------

Try to match Arduino style for the most part

Namespace everything inside Aiko. Try not to clutter though; should be able to
do "using namespace Aiko" with impunity.

2-space tabs

CamelCase names. Uppercase for types, lowercase for variables, methods,
functions. Don't abbreviate.

Use underscores on the end of instance variable names. (Lets you have a getter
with the non-underscored name.)

Only use pass-by-ref for complex data structures, not basic types. Assume
everything is pass by ref when coding.


Memory Management
-----------------

If you need a buffer, malloc it up. Make sure it gets freed when your object
goes away. Allow a static buffer to be passed in.

