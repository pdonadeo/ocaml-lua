LUA C API BINDING
=================

Description
-----------

This is a simple binding of the Lua C API library to the Objective Caml
programming language.

It's only a poof of concept and includes a very minimal subset of the Lua API,
but what has been implemented is working as expected, in particular without
memory leak. I hope :-)


Dependencies
------------

To compile this project you need:
 + Objective Caml 3.11.1 (but I think any later version should work)
 + any recent version of Findlib
 + the Lua development library, version 5.1
 + GCC (I'm using 4.4.1, but every version should be OK)

Compiling
---------

Just type:

$ ocamlbuild -j 4 main.native lua_api.cma lua_api.cmxa
(omit -j 4 for non multicore CPUs)


Paolo

