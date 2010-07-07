(**************************)
(** {2 Types definitions} *)
(**************************)

type state
(** See {{:http://www.lua.org/manual/5.1/manual.html#lua_State}lua_State}
    documentation. *)

type oCamlFunction = state -> int
(** See {{:http://www.lua.org/manual/5.1/manual.html#lua_CFunction}lua_CFunction}
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

(************************)
(** {2 Constant values} *)
(************************)

val lua_multret : int
(** Option for multiple returns in `Lua.pcall' and `Lua.call'.
    See {{:http://www.lua.org/manual/5.1/manual.html#lua_call}lua_call}
    documentation. *)

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

val default_panic_function : state -> int
(** This panic function does nothing but returning 0. *)

val atpanic : state -> oCamlFunction -> oCamlFunction
(** The first time you call [atpanic] returns [default_panic_function]. *)

val call : state -> int -> int -> unit
(** See {{:http://www.lua.org/manual/5.1/manual.html#lua_call}lua_call}
    documentation. *)

val checkstack : state -> int -> bool
(** See {{:http://www.lua.org/manual/5.1/manual.html#lua_checkstack}lua_checkstack}
    documentation. *)

(** {10 {b lua_close}} *)
(** TODO BLA BLA BLA *)

(****************************)
(** {1 TODO TODO TODO TODO} *)
(****************************)

(**************************************************************************)
(**************************************************************************)
(**************************************************************************)
(**************************************************************************)
(**************************************************************************)
(**************************************************************************)
external lua_open : unit -> state = "lua_open__stub"
external lua_pcall__wrapper : state -> int -> int -> int -> int
  = "lua_pcall__stub"
val pcall : state -> int -> int -> int -> unit
external lua_tolstring__wrapper : state -> int -> string
  = "lua_tolstring__stub"
val tolstring : state -> int -> string
val tostring : state -> int -> string
external pop : state -> int -> unit = "lua_pop__stub"
external error : state -> 'a = "lua_error__stub"
module Exceptionless :
  sig
    val pcall : state -> int -> int -> int -> thread_status
    val tolstring :
      state -> int -> [> `Ok of string | `Type_error of string ]
    val tostring : state -> int -> [> `Ok of string | `Type_error of string ]
  end
