(**************************************************)
(** {1 The Lua Auxiliary Library (OCaml binding)} *)
(**************************************************)

open Lua_api_lib

(***********************************************************)
(** {2 Difference with the original Lua Auxiliary Library} *)
(***********************************************************)

(** Here is a list of functions of which you should read documentation:
- {b Missing functions}: [luaL_addsize], [luaL_prepbuffer]
- {b Notably different functions}: {!error}, {!newstate}
- {b Special remarks}: {!checklstring}

*)

(**************************)
(** {2 Types definitions} *)
(**************************)

type buffer
(** See {{:http://www.lua.org/manual/5.1/manual.html#luaL_Buffer}luaL_Buffer}
    documentation. *)

type reg = string * oCamlFunction
(** See {{:http://www.lua.org/manual/5.1/manual.html#luaL_reg}luaL_reg}
    documentation. *)


(************************)
(** {2 Constant values} *)
(************************)

val refnil : int
(** Value returned by `luaL_ref` and `luaL_unref`.
    See {{:http://www.lua.org/manual/5.1/manual.html#luaL_ref}luaL_ref}
    and {{:http://www.lua.org/manual/5.1/manual.html#luaL_unref}luaL_unref}
    documentation. *)

val noref : int
(** Value returned by `luaL_ref` and `luaL_unref`.
    See {{:http://www.lua.org/manual/5.1/manual.html#luaL_ref}luaL_ref}
    and {{:http://www.lua.org/manual/5.1/manual.html#luaL_unref}luaL_unref}
    documentation. *)

(****************************************)
(** {2 The Auxiliary Library functions} *)
(****************************************)

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

(** The function
    {{:http://www.lua.org/manual/5.1/manual.html#luaL_addsize}luaL_addsize} is not
    present because the type {!Lua_aux_lib.buffer} and related functions have been
    reimplemented in OCaml, and luaL_addsize is not needed. *)

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

external argerror : state -> int -> string -> 'a = "luaL_argerror__stub"
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

    {b NOTE}: this function is {b not} a binding of the original luaL_checklstring,
    it's rather an OCaml function with the same semantics. *)

val checkstring : state -> int -> string
(** See {{:http://www.lua.org/manual/5.1/manual.html#luaL_checkstring}luaL_checkstring}
    documentation.

    {b NOTE}: this function is an alias of {!Lua_aux_lib.checklstring} *)

val checknumber : state -> int -> float
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#luaL_checknumber}luaL_checknumber}
    documentation.

    {b NOTE}: this function is {b not} a binding of the original luaL_checknumber,
    it's rather an OCaml function with the same semantics. *)

val checkoption : state -> int -> string option -> string list -> int
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#luaL_checkoption}luaL_checkoption}
    documentation.

    {b NOTE}: this function is {b not} a binding of the original luaL_checkoption,
    it's rather an OCaml function with the same semantics. *)

val checkstack : state -> int -> string -> unit
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#luaL_checkstack}luaL_checkstack}
    documentation.

    {b NOTE}: this function is {b not} a binding of the original luaL_checkstack,
    it's rather an OCaml function with the same semantics. *)

val checktype : state -> int -> lua_type -> unit
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#luaL_checktype}luaL_checktype}
    documentation.

    {b NOTE}: this function is {b not} a binding of the original luaL_checktype,
    it's rather an OCaml function with the same semantics. *)

val checkudata : state -> int -> string -> [> `Userdata of 'a | `Light_userdata of 'a ] option
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#luaL_checkudata}luaL_checkudata}
    documentation.

    {b NOTE}: this function is {b not} a binding of the original luaL_checkudata,
    it's rather an OCaml function with the same semantics. *)

val dofile : state -> string -> bool
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#luaL_dofile}luaL_dofile}
    documentation.

    {b NOTE}: this function is {b not} a binding of the original luaL_dofile,
    it's rather an OCaml function with the same semantics. *)

val dostring : state -> string -> bool
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#luaL_dostring}luaL_dostring}
    documentation.

    {b NOTE}: this function is {b not} a binding of the original luaL_dostring,
    it's rather an OCaml function with the same semantics. *)

val error : state -> ('a, unit, string, 'b) format4 -> 'a
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#luaL_error}luaL_error}
    documentation.

    {b NOTE}: this function is {b not} a binding of the original luaL_error,
    it's rather an OCaml function with the same semantics.

    Warning: this function has a different behavior with respect to the original
    {{:http://www.lua.org/manual/5.1/manual.html#luaL_error}luaL_error}
    because the conversion specifiers are not restricted as specified in the Lua
    documentation, but you can use all the conversions of the
    {{:http://caml.inria.fr/pub/docs/manual-ocaml/libref/Printf.html}Printf module}. *)

external getmetafield : state -> int -> string -> bool = "luaL_getmetafield__stub"
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#luaL_getmetafield}luaL_getmetafield}
    documentation. *)

external getmetatable : state -> string -> unit = "luaL_getmetatable__stub"
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#luaL_getmetatable}luaL_getmetatable}
    documentation. *)

external gsub : state -> string -> string -> string -> string = "luaL_gsub__stub"
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#luaL_gsub}luaL_gsub}
    documentation. *)

val loadbuffer : Lua_api_lib.state -> string -> string -> thread_status
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#luaL_loadbuffer}luaL_loadbuffer}
    documentation. *)

val loadfile : state -> string -> thread_status
(** See {{:http://www.lua.org/manual/5.1/manual.html#luaL_loadfile}luaL_loadfile}
    documentation. *)

val loadstring : state -> string -> thread_status
(** See {{:http://www.lua.org/manual/5.1/manual.html#luaL_loadstring}luaL_loadstring}
    documentation. *)

external newmetatable : state -> string -> bool = "luaL_newmetatable__stub"
(** See {{:http://www.lua.org/manual/5.1/manual.html#luaL_newmetatable}luaL_newmetatable}
    documentation. *)

val newstate : ?max_memory_size:int -> unit -> state
(** See {{:http://www.lua.org/manual/5.1/manual.html#luaL_newstate}luaL_newstate}
    documentation.

    {b NOTE}: this function is {b not} a binding of the original luaL_newstate,
    it's rather an OCaml function with the same semantics.

    An optional parameter, not available in the original luaL_newstate, provide
    the user the chance to specify the maximum memory (in byte) that Lua is allowed to
    allocate for this state.

    {b Warning}: when the library is built with LuaJIT [max_memory_size] is
    ignored! *)

external openlibs : Lua_api_lib.state -> unit = "luaL_openlibs__stub"
(** See {{:http://www.lua.org/manual/5.1/manual.html#luaL_openlibs}luaL_openlibs}
    documentation. *)

val optint : state -> int -> int -> int
(** See {{:http://www.lua.org/manual/5.1/manual.html#luaL_optint}luaL_optint}
    documentation.

    {b NOTE}: this function is an alias of {!Lua_aux_lib.optinteger} *)

external optinteger : state -> int -> int -> int = "luaL_optinteger__stub"
(** See {{:http://www.lua.org/manual/5.1/manual.html#luaL_optinteger}luaL_optinteger}
    documentation. *)

external optlong : state -> int -> int -> int = "luaL_optlong__stub"
(** See {{:http://www.lua.org/manual/5.1/manual.html#luaL_optlong}luaL_optlong}
    documentation. *)

val optlstring : state -> int -> string -> string
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#luaL_optlstring}luaL_optlstring}
    documentation.

    {b NOTE}: this function is {b not} a binding of the original luaL_optlstring,
    it's rather an OCaml function with the same semantics. *)

val optnumber : state -> int -> float -> float
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#luaL_optnumber}luaL_optnumber}
    documentation.

    {b NOTE}: this function is {b not} a binding of the original luaL_optnumber,
    it's rather an OCaml function with the same semantics. *)

val optstring : state -> int -> string -> string
(** See {{:http://www.lua.org/manual/5.1/manual.html#luaL_optstring}luaL_optstring}
    documentation.

    {b NOTE}: this function is an alias of {!Lua_aux_lib.optlstring} *)

(** The function
    {{:http://www.lua.org/manual/5.1/manual.html#luaL_prepbuffer}luaL_prepbuffer} is not
    present because the type {!Lua_aux_lib.buffer} and related functions have been
    reimplemented in OCaml, and luaL_prepbuffer is not needed. *)

val pushresult : buffer -> unit
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#luaL_pushresult}luaL_pushresult}
    documentation.

    {b NOTE}: this function is {b not} a binding of the original luaL_pushresult,
    it's rather an OCaml function with the same semantics. *)

external ref_ : state -> int -> int = "luaL_ref__stub"
(** See {{:http://www.lua.org/manual/5.1/manual.html#luaL_ref}luaL_ref}
    documentation. *)

val register : state -> string option -> reg list -> unit
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#luaL_register}luaL_register}
    documentation.

    {b NOTE}: this function is {b not} a binding of the original luaL_register,
    it's rather an OCaml function with the same semantics. *)

val typename : state -> int -> string
(** See
    {{:http://www.lua.org/manual/5.1/manual.html#luaL_typename}luaL_typename}
    documentation.

    {b NOTE}: this function is {b not} a binding of the original luaL_typename,
    it's rather an OCaml function with the same semantics. *)

external typerror : state -> int -> string -> 'a = "luaL_typerror__stub"
(** See {{:http://www.lua.org/manual/5.1/manual.html#luaL_typerror}luaL_typerror}
    documentation. *)

external unref : state -> int -> int -> unit = "luaL_unref__stub"
(** See {{:http://www.lua.org/manual/5.1/manual.html#luaL_unref}luaL_unref}
    documentation. *)

external where : state -> int -> unit = "luaL_where__stub"
(** See {{:http://www.lua.org/manual/5.1/manual.html#luaL_where}luaL_where}
    documentation. *)
