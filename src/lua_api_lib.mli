(**************************)
(** {2 Types definitions} *)
(**************************)

type state
(** See {{:http://www.lua.org/manual/5.1/manual.html#lua_State}lua_State}
    documentation. *)

type oCamlFunction = state -> int
(** This type corresponds to lua_CFunction. See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_CFunction}lua_CFunction}
    documentation. *)

type thread_status =
  | LUA_OK          (** 0 *)
  | LUA_YIELD       (** 1 *)
  | LUA_ERRRUN      (** 2 *)
  | LUA_ERRSYNTAX   (** 3 *)
  | LUA_ERRMEM      (** 4 *)
  | LUA_ERRERR      (** 5 *)
(** See {{:http://www.lua.org/manual/5.1/manual.html#pdf-LUA_YIELD}lua_status}
    documentation. *)

type alloc
(** This type corresponds to
    {{:http://www.lua.org/manual/5.1/manual.html#lua_Alloc}lua_Alloc} and is here
    only as a placeholder, but it's not used in this binding because it makes
    very little sense to write a low level allocator in Objective Caml. *)

type gc_command =
  | GCSTOP
  | GCRESTART
  | GCCOLLECT
  | GCCOUNT
  | GCCOUNTB
  | GCSTEP
  | GCSETPAUSE
  | GCSETSTEPMUL
(** This type is not present in the official API and is used by the function
    [gc] *)

(************************)
(** {2 Constant values} *)
(************************)

val multret : int
(** Option for multiple returns in `Lua.pcall' and `Lua.call'.
    See {{:http://www.lua.org/manual/5.1/manual.html#lua_call}lua_call}
    documentation. *)

val registryindex : int
(** Pseudo-index to access the registry.
    See {{:http://www.lua.org/manual/5.1/manual.html#3.5}Registry} documentation. *)

val environindex : int
(** Pseudo-index to access the environment of the running C function.
    See {{:http://www.lua.org/manual/5.1/manual.html#3.3}Registry} documentation. *)

val globalsindex : int
(** Pseudo-index to access the thread environment (where global variables live).
    See {{:http://www.lua.org/manual/5.1/manual.html#3.3}Registry} documentation. *)


(*******************)
(** {2 Exceptions} *)
(*******************)

exception Error of thread_status
exception Type_error of string

(*********************************************)
(** {2 Functions non present in the Lua API} *)
(*********************************************)

val thread_status_of_int : int -> thread_status
(** Convert an integer into a [thread_status]. Raises [failure] on
    invalid parameter. *)

val int_of_thread_status : thread_status -> int
(** Convert a [thread_status] into an integer. *)

(**************************)
(** {2 Lua API functions} *)
(**************************)

external atpanic : state -> oCamlFunction -> oCamlFunction = "lua_atpanic__stub"
(** See {{:http://www.lua.org/manual/5.1/manual.html#lua_atpanic}lua_atpanic}
    documentation. *)

external call : state -> int -> int -> unit = "lua_call__stub"
(** See {{:http://www.lua.org/manual/5.1/manual.html#lua_call}lua_call}
    documentation. *)

external checkstack : state -> int -> bool = "lua_checkstack__stub"
(** See {{:http://www.lua.org/manual/5.1/manual.html#lua_checkstack}lua_checkstack}
    documentation. *)

(** The function
    {{:http://www.lua.org/manual/5.1/manual.html#lua_close}lua_close} is not
    present because all the data structures of a Lua state are managed by the
    OCaml garbage collector. *)

external concat : state -> int -> unit = "lua_concat__stub"
(** See {{:http://www.lua.org/manual/5.1/manual.html#lua_concat}lua_concat}
    documentation. *)

(* TODO lua_cpcall
   http://www.lua.org/manual/5.1/manual.html#lua_cpcall *)

external createtable : state -> int -> int -> unit = "lua_createtable__stub"
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_createtable}lua_createtable}
    documentation. *)

(* TODO lua_dump
   http://www.lua.org/manual/5.1/manual.html#lua_dump *)

external equal : state -> int -> int -> bool = "lua_equal__stub"
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_equal}lua_equal}
    documentation. *)

external error : state -> 'a = "lua_error__stub"
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_error}lua_error}
    documentation. *)

val gc : state -> gc_command -> int -> int
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_gc}lua_gc}
    documentation. *)

(** {{:http://www.lua.org/manual/5.1/manual.html#lua_getallocf}lua_getallocf}
    not implemented in this binding *)

external getfenv : state -> int -> unit = "lua_getfenv__stub"
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_getfenv}lua_getfenv}
    documentation. *)

external getfield : state -> int -> string -> unit = "lua_getfield__stub"
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_getfield}lua_getfield}
    documentation. *)

val getglobal : state -> string -> unit
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_getglobal}lua_getglobal}
    documentation. Like in the original Lua source code this function is
    implemented in OCaml using [getfield]. *)

external getmetatable : state -> int -> int = "lua_getmetatable__stub"
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_getmetatable}lua_getmetatable}
    documentation. *)

external gettable : state -> int -> unit = "lua_gettable__stub"
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_gettable}lua_gettable}
    documentation. *)

external gettop : state -> int = "lua_gettop__stub"
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_gettop}lua_gettop}
    documentation. *)

external insert : state -> int -> unit = "lua_insert__stub"
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_insert}lua_insert}
    documentation. *)

external isboolean : state -> int -> bool = "lua_isboolean__stub"
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_isboolean}lua_isboolean}
    documentation. *)

external iscfunction : state -> int -> bool = "lua_iscfunction__stub"
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_iscfunction}lua_iscfunction}
    documentation. *)

external isfunction : state -> int -> bool = "lua_isfunction__stub"
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_isfunction}lua_isfunction}
    documentation. *)

external islightuserdata : state -> int -> bool = "lua_islightuserdata__stub"
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_islightuserdata}lua_islightuserdata}
    documentation. *)

external isnil : state -> int -> bool = "lua_isnil__stub"
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_isnil}lua_isnil}
    documentation. *)

external isnone : state -> int -> bool = "lua_isnone__stub"
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_isnone}lua_isnone}
    documentation. *)

external isnoneornil : state -> int -> bool = "lua_isnoneornil__stub"
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_isnoneornil}lua_isnoneornil}
    documentation. *)

external isnumber : state -> int -> bool = "lua_isnumber__stub"
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_isnumber}lua_isnumber}
    documentation. *)

external isstring : state -> int -> bool = "lua_isstring__stub"
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_isstring}lua_isstring}
    documentation. *)

external istable : state -> int -> bool = "lua_istable__stub"
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_istable}lua_istable}
    documentation. *)

external isthread : state -> int -> bool = "lua_isthread__stub"
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_isthread}lua_isthread}
    documentation. *)

external isuserdata : state -> int -> bool = "lua_isuserdata__stub"
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_isuserdata}lua_isuserdata}
    documentation. *)

external lessthan : state -> int -> int -> bool = "lua_lessthan__stub"
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_lessthan}lua_lessthan}
    documentation. *)

(* TODO lua_load
   http://www.lua.org/manual/5.1/manual.html#lua_load *)

(** The function
    {{:http://www.lua.org/manual/5.1/manual.html#lua_newstate}lua_newstate} is
    not present because it makes very little sense to specify a custom allocator
    written in OCaml. To create a new Lua state, use the function
    {!Lua_aux_lib.newstate}. *)

external newtable: state -> int -> int -> bool = "lua_newtable__stub"
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_newtable}lua_newtable}
    documentation. *)

(* TODO lua_newthread
   http://www.lua.org/manual/5.1/manual.html#lua_newthread *)

(* TODO lua_newuserdata
   http://www.lua.org/manual/5.1/manual.html#lua_newuserdata *)

external next : state -> int -> int = "lua_next__stub"
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_next}lua_next}
    documentation. *)

external objlen : state -> int -> int = "lua_objlen__stub"
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_objlen}lua_objlen}
    documentation. *)

val pcall : state -> int -> int -> int -> thread_status
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_pcall}lua_pcall}
    documentation. *)

external pop : state -> int -> unit = "lua_pop__stub"
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_pop}lua_pop}
    documentation. *)

external pushboolean : state -> bool -> unit = "lua_pushboolean__stub"
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_pushboolean}lua_pushboolean}
    documentation. *)

(** The function
    {{:http://www.lua.org/manual/5.1/manual.html#lua_pushcclosure}lua_pushcclosure}
    is not present because it makes very little sense to specify a "closure"
    written in OCaml, using the Lua
    {{:http://www.lua.org/pil/27.3.3.html}upvalues} machinery. Use instead
    {!Lua_api_lib.pushcfunction} *)

external pushcfunction : state -> oCamlFunction -> unit = "lua_pushcfunction__stub"
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_pushcfunction}lua_pushcfunction}
    documentation. *)

val pushocamlfunction : state -> oCamlFunction -> unit
(** Alias of {!Lua_api_lib.pushcfunction} *)

val pushfstring : state -> ('a, unit, string, string) format4 -> 'a
(** Pushes onto the stack a formatted string and returns the string itself.
    It is similar to the standard library function sprintf.

    Warning: this function has a different behavior with respect to the original
    {{:http://www.lua.org/manual/5.1/manual.html#lua_pushfstring}lua_pushfstring}
    because the conversion specifiers are not restricted as specified in the Lua
    documentation, but you can use all the conversions of the
    {{:http://caml.inria.fr/pub/docs/manual-ocaml/libref/Printf.html}Printf module}. *)

external pushinteger : state -> int -> unit = "lua_pushinteger__stub"
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_pushinteger}lua_pushinteger}
    documentation. *)

(* TODO lua_pushlightuserdata
   http://www.lua.org/manual/5.1/manual.html#lua_pushlightuserdata *)

external pushliteral : state -> string -> unit = "lua_pushlstring__stub"
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_pushliteral}lua_pushliteral}
    documentation. *)

external pushlstring : state -> string -> unit = "lua_pushlstring__stub"
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_pushlstring}lua_pushlstring}
    documentation. *)

external pushnil : state -> unit = "lua_pushnil__stub"
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_pushnil}lua_pushnil}
    documentation. *)

external pushnumber : state -> float -> unit = "lua_pushnumber__stub"
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_pushnumber}lua_pushnumber}
    documentation. *)

val pushstring : state -> string -> unit
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_pushstring}lua_pushstring}
    documentation. *)

(* TODO lua_pushthread
   http://www.lua.org/manual/5.1/manual.html#lua_pushthread *)

external pushvalue : state -> int -> unit = "lua_pushvalue__stub"
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_pushvalue}lua_pushvalue}
    documentation. *)

val pushvfstring : state -> ('a, unit, string, string) format4 -> 'a
(** Alias of {!Lua_api_lib.pushfstring} *)

external rawequal : state -> int -> int -> bool = "lua_rawequal__stub"
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_rawequal}lua_rawequal}
    documentation. *)

external rawget : state -> int -> unit = "lua_rawget__stub"
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_rawget}lua_rawget}
    documentation. *)

external rawgeti : state -> int -> int -> unit = "lua_rawgeti__stub"
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_rawgeti}lua_rawgeti}
    documentation. *)

external rawset : state -> int -> unit = "lua_rawset__stub"
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_rawset}lua_rawset}
    documentation. *)

external rawseti : state -> int -> int -> unit = "lua_rawseti__stub"
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_rawseti}lua_rawseti}
    documentation. *)

val register : state -> string -> oCamlFunction -> unit
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_register}lua_register}
    documentation. The function is implemented in OCaml using pushcfunction
    and setglobal. *)

external remove : state -> int -> unit = "lua_remove__stub"
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_remove}lua_remove}
    documentation. *)

external replace : state -> int -> unit = "lua_replace__stub"
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_replace}lua_replace}
    documentation. *)

(* TODO lua_resume
   http://www.lua.org/manual/5.1/manual.html#lua_resume *)

(** {{:http://www.lua.org/manual/5.1/manual.html#lua_setallocf}lua_setallocf}
    not implemented in this binding *)

external setfenv : state -> int -> bool = "lua_setfenv__stub"
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_setfenv}lua_setfenv}
    documentation. *)

external setfield : state -> int -> string -> unit = "lua_setfield__stub"
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_setfield}lua_setfield}
    documentation. *)

external setglobal : state -> string -> unit = "lua_setglobal__stub"
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_setglobal}lua_setglobal}
    documentation. *)

external setmetatable : state -> int -> int = "lua_setmetatable__stub"
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_setmetatable}lua_setmetatable}
    documentation. *)

external settable : state -> int -> int = "lua_settable__stub"
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_settable}lua_settable}
    documentation. *)

external settop : state -> int -> int = "lua_settop__stub"
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_settop}lua_settop}
    documentation. *)

val status : state -> thread_status
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_status}lua_status}
    documentation. *)

external toboolean : state -> int -> bool = "lua_toboolean__stub"
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_toboolean}lua_toboolean}
    documentation. *)

val tocfunction : state -> int -> oCamlFunction option
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_tocfunction}lua_tocfunction}
    documentation. *)

(****************************)
(** {1 TODO TODO TODO TODO} *)
(****************************)

(**************************************************************************)
(**************************************************************************)
(**************************************************************************)
(**************************************************************************)
(**************************************************************************)
(**************************************************************************)
external tolstring : state -> int -> string = "lua_tolstring__stub"
val tostring : state -> int -> string


