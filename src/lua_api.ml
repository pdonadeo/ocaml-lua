(*******************************************************************)
(** {1 The Lua API library binding in OCaml {b (read this first)}} *)
(*******************************************************************)

(*********************)
(** {2 Introduction} *)
(*********************)

(** This is the OCaml complete binding of the Lua Application Program Interface
  as described in the {{:http://www.lua.org/manual/5.1/manual.html#3}official
  documentation}. The version of the library is the 5.1.5, the source code is
  available {{:http://www.lua.org/versions.html#5.1}here} but, since it's a bug
  fix release, any version 5.1.x should be fine. On the other side, previous
  releases and the new Lua 5.2 is not supported.

  The Lua API library is composed by two parts: the
  {{:http://www.lua.org/manual/5.1/manual.html#3}low level API}, providing all
  the functions you need to interact with the Lua runtime, and the
  {{:http://www.lua.org/manual/5.1/manual.html#4}auxiliary library}, described
  in the original documentation as follow:

  {i The auxiliary library provides several convenient functions to interface
  C with Lua. While the basic API provides the primitive functions for all
  interactions between C and Lua, the auxiliary library provides higher-level
  functions for some common tasks. ... All functions in the auxiliary
  library are built on top of the basic API, and so they provide nothing that
  cannot be done with this API. }

  I included all the functions in the two libraries, with the exception of the
  {{:http://www.lua.org/manual/5.1/manual.html#3.8} debug interface}, which is
  not planned because it's out of the intended scope of the OCaml binding. It
  could be added if anyone really needs it.

  The signatures of the OCaml counterparts of the Lua functions where kept as
  close as possible to the original ones, to reduce at the minimum the mismatch
  between the two. This guideline lead to a very "imperative" OCaml library, but
  I think this is a minor issue.

  Two "low level" modules are provided, {!Lua_api_lib} and {!Lua_aux_lib}.
  Ideally you should start your program opening [Lua_api], and then call
  functions like this:

      {[
open Lua_api;;

let push_hello () =
  let ls = LuaL.newstate () in
  Lua.pushstring ls "hello";
  ls
;;
    ]}
  which is very close to what you would do in C:
      {[
#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>

lua_State* push_hello () {
    lua_State *L = luaL_newstate();
    lua_pushstring(L, "hello");
    return L;
}
    ]}

    Many functions, expecially in the [LuaL] module, are not real bindings,
    because sometimes it was faster to rewrite the function in OCaml than
    creating the binding. Every time this happens, it's clearly stated in the
    documentation. Other functions have different signatures or special notes,
    but all these differences are documented. At the top of the pages
    documenting the {! Lua_api_lib} and {! Lua_aux_lib} modules there is a list
    of important differences.
*)


(******************************)
(** {3 Note on thread safety} *)
(******************************)

(**
    This binding is to be considered "thread safe". This means that you can use
    the library in a threaded setup, but keep in mind that you {b cannot} share
    a Lua state [Lua_api_lib.state] between threads, because Lua itself doesn't
    allow this. *)


(**************************)
(** {2 Low level modules} *)
(**************************)

module Lua = Lua_api_lib
(** For reference see {! Lua_api_lib} *)

module LuaL = Lua_aux_lib
(** For reference see {! Lua_aux_lib} *)
