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

(* TODO lua_cpcall *)

external createtable : state -> int -> int -> unit = "lua_createtable__stub"
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#lua_createtable}lua_createtable}
    documentation. *)

(* TODO lua_dump *)

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


(****************************)
(** {1 TODO TODO TODO TODO} *)
(****************************)

(**************************************************************************)
(**************************************************************************)
(**************************************************************************)
(**************************************************************************)
(**************************************************************************)
(**************************************************************************)
external lua_pcall__wrapper : state -> int -> int -> int -> int
  = "lua_pcall__stub"
val pcall : state -> int -> int -> int -> unit
external tolstring : state -> int -> string = "lua_tolstring__stub"
val tostring : state -> int -> string
external pushlstring : state -> string -> unit = "lua_pushlstring__stub"
val pushstring : state -> string -> unit

external pop : state -> int -> unit = "lua_pop__stub"
