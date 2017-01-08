## What is ocaml-lua

OCaml-lua provides bindings to the Lua programming language. Lua is a scripting language particularly useful when you need to embed a language in your application.

This project provides the bindings required to embed Lua.

[More information about Lua](http://www.lua.org/)

<p align="center">
  <img alt="Lua logo" title="Lua logo" src="https://pdonadeo.github.io/ocaml-lua/img/lua-logo.gif">
</p>

## Introduction

Lua is a powerful, light-weight programming language designed for extending applications. It provides a good general purpose programming language to replace DSL that don't really need to be specific.

This library provides bindings to Lua API which allows the application to exchange data with Lua programs and also to extend Lua with OCaml functions.

This is the OCaml complete binding of the Lua Application Program Interface as described in the official documentation.

In this moment only the version 5.1.x is supported, while 5.2.x is on my TODO list. In general my plan is to support newest versions, but not the oldest ones.

[LuaJIT](http://luajit.org/luajit.html) 2.0.0 for Lua 5.1 is also supported.

## Intended audience

This library is intended to be useful to OCaml developers needing a dynamic language to be included in their projects, for configuration or customization purposes. Instead of reinventing yet another DSL, one should consider using an existing programming language and Lua is in my opinion the perfect companion of a statically typed language like OCaml.

In a few lines of code you can create a Lua interpreter and run a Lua program inside it. You can provide the Lua state with library functions written in OCaml and available to the Lua program.

More informations about Lua can be found on the [documentation page](http://www.lua.org/docs.html).

My advice is to read the book ["Programming in Lua"](http://www.lua.org/pil/), written by the author of the language, Roberto Ierusalimschy.

## Where to find everything

The homepage of the project is hosted on [GitHub](https://pdonadeo.github.io/ocaml-lua/).

The complete library reference (ocamldoc generated) is [here](https://pdonadeo.github.io/ocaml-lua/ocamldoc/).

The official GIT repository is [here](https://github.com/pdonadeo/ocaml-lua).

Bug reports and feature requests are on my page on [GitHub](https://github.com/pdonadeo/ocaml-lua/issues).

See the file COPYING.txt for copying conditions. See the file AUTHORS.txt for credits.

## Building and installing the library

To build the library the following requirements are mandatory:

* lua 5.1.x
* ocaml (>= 3.12.1)
* findlib

The library can optionally be compiled and linked with LuaJIT. In this case an additional requirement is:

* LuaJIT 2.0.0 for Lua 5.1

To compile use the usual spell:

1. ./configure
   check the options of the configure script with --help, and pay particular attention to --docdir which defaults to /usr/local/share/doc/ocaml-lua
2. make
3. make doc
4. make install
