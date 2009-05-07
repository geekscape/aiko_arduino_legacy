
Goals
-----

- Easily human readable and writable
- Easy machine parsing
    - Minimal memory overhead
    - Lazy parsing
- Implementation on many platforms
    - Good tests to facilitate this
- Simple translation to/from JSON
- Simple mapping to/from XML





Design guidelines
-----------------

Should be able to pull in just the individual parts of the framework you need

Should generally optimise for memory usage (flash and SRAM) over computation time





Code style
----------

Try to match Arduino style for the most part

Namespace everything inside Aiko. Try not to clutter though; should be able to do "using namespace Aiko" with impunity.

2-space tabs

CamelCase names. Uppercase for types, lowercase for variables, methods, functions. Don't abbreviate.

Use underscores on the end of instance variable names. (Lets you have a getter with the non-underscored name.)

Only use pass-by-ref for complex data structures, not basic types. Assume everything is pass by ref when coding.


Memory Management
-----------------

If you need a buffer, malloc it up. Make sure it gets freed when your object goes away. Allow a static buffer to be passed in.
