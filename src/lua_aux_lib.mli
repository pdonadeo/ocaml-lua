open Lua_api_lib

(**************************)
(** {2 Types definitions} *)
(**************************)

type buffer
(** See {{:http://www.lua.org/manual/5.1/manual.html#luaL_Buffer}luaL_Buffer}
    documentation. *)

val addchar : buffer -> char -> unit
(** See {{:http://www.lua.org/manual/5.1/manual.html#luaL_addchar}luaL_addchar}
    documentation.

    {b NOTE}: this function is {b not} a binding of the original luaL_addchar,
    it's rather an OCaml function with the same semantics. *)

val addlstring : buffer -> string -> unit
(** See {{:http://www.lua.org/manual/5.1/manual.html#luaL_addlstring}luaL_addlstring}
    documentation.

    {b NOTE}: this function is {b not} a binding of the original luaL_addlstring,
    it's rather an OCaml function with the same semantics. *)

(* TODO: decide if luaL_addsize should be included in this binding
         void luaL_addsize (luaL_Buffer *B, size_t n);
 *)

val addstring : buffer -> string -> unit
(** See {{:http://www.lua.org/manual/5.1/manual.html#luaL_addstring}luaL_addstring}
    documentation.

    {b NOTE}: this function is an alias of {!Lua_aux_lib.addlstring} *)

val addvalue : buffer -> unit
(** See {{:http://www.lua.org/manual/5.1/manual.html#luaL_addvalue}luaL_addvalue}
    documentation.

    {b NOTE}: this function is {b not} a binding of the original luaL_addvalue,
    it's rather an OCaml function with the same semantics. *)

external argcheck : state -> bool -> int -> string -> unit = "luaL_argcheck__stub"
(** See {{:http://www.lua.org/manual/5.1/manual.html#luaL_argcheck}luaL_argcheck}
    documentation. *)

external argerror : state -> int -> string -> unit = "luaL_argerror__stub"
(** See {{:http://www.lua.org/manual/5.1/manual.html#luaL_argerror}luaL_argerror}
    documentation. *)

val buffinit : state -> buffer
(** See {{:http://www.lua.org/manual/5.1/manual.html#luaL_buffinit}luaL_buffinit}
    documentation. *)

external callmeta : state -> int -> string -> bool = "luaL_callmeta__stub"
(** See {{:http://www.lua.org/manual/5.1/manual.html#luaL_callmeta}luaL_callmeta}
    documentation. *)

external checkany : state -> int -> unit = "luaL_checkany__stub"
(** See {{:http://www.lua.org/manual/5.1/manual.html#luaL_checkany}luaL_checkany}
    documentation. *)

external checkint : state -> int -> int = "luaL_checkint__stub"
(** See {{:http://www.lua.org/manual/5.1/manual.html#luaL_checkint}luaL_checkint}
    documentation. *)

val checkinteger : state -> int -> int
(** See {{:http://www.lua.org/manual/5.1/manual.html#luaL_checkinteger}luaL_checkinteger}
    documentation.

    {b NOTE}: this function is an alias of {!Lua_aux_lib.checkint} *)

external checklong : state -> int -> int = "luaL_checklong__stub"
(** See {{:http://www.lua.org/manual/5.1/manual.html#luaL_checklong}luaL_checklong}
    documentation. *)

val checklstring : state -> int -> string
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#luaL_checklstring}luaL_checklstring}
    documentation.

    {b NOTE}:The original [len] argument is missing because, unlike in C, there
    is no impedance mismatch between OCaml and Lua strings.

    {b NOTE}: this function is {b not} a binding of the original luaL_addvalue,
    it's rather an OCaml function with the same semantics. *)

external typerror : state -> int -> string -> 'a = "luaL_typerror__stub"
(** See {{:http://www.lua.org/manual/5.1/manual.html#luaL_typerror}luaL_typerror}
    documentation. *)

(**/**)

(******************************************************************************)
(******************************************************************************)
(*****                          TO BE COMPLETED                           *****)
(******************************************************************************)
(******************************************************************************)
external newstate : unit -> state = "luaL_newstate__stub"

external openlibs : Lua_api_lib.state -> unit = "luaL_openlibs__stub"

val loadbuffer : Lua_api_lib.state -> string -> string -> Lua_api_lib.thread_status

val loadfile : Lua_api_lib.state -> string -> Lua_api_lib.thread_status

external newmetatable : state -> string -> bool = "luaL_newmetatable__stub"

external getmetatable : state -> string -> unit = "luaL_getmetatable__stub"

val checkudata : state -> int -> string -> [> `Userdata of 'a | `Light_userdata of 'a ] option

external typerror : state -> int -> string -> 'a = "luaL_typerror__stub"

external checkstring : state -> int -> string = "luaL_checkstring__stub" (* TODO RENDERE ALIAS DI checklstring *)

val error : state -> ('a, unit, string, 'b) format4 -> 'a                                                             

