open Lua_api_lib

let (|>) x f = f x

type buffer =
  { l : state;
    buffer : Buffer.t; }

let addchar b c =
  Buffer.add_char b.buffer c
;;

let addlstring b s =
  Buffer.add_string b.buffer s
;;

let addstring = addlstring;;

let addvalue b =
  match tolstring b.l (-1) with
  | Some s -> Buffer.add_string b.buffer s
  | None -> ()
;;

external argcheck : state -> bool -> int -> string -> unit = "luaL_argcheck__stub"

external argerror : state -> int -> string -> 'a = "luaL_argerror__stub"

let buffinit l =
  { l = l;
    buffer = Buffer.create 8192; }
;;

external callmeta : state -> int -> string -> bool = "luaL_callmeta__stub"

external checkany : state -> int -> unit = "luaL_checkany__stub"

external checkint : state -> int -> int = "luaL_checkint__stub"

let checkinteger = checkint;;

external checklong : state -> int -> int = "luaL_checklong__stub"

external typerror : state -> int -> string -> 'a = "luaL_typerror__stub"

let tag_error l narg tag =
  typerror l narg (typename l tag)
;;

let checklstring l narg =
  match tolstring l narg with
  | Some s -> s
  | None -> tag_error l narg LUA_TSTRING
;;

let checknumber l narg =
  let d = tonumber l narg in
  if d = 0.0 && not (isnumber l narg)
  then tag_error l narg LUA_TNUMBER
  else d
;;

let optlstring l narg d =
  if isnoneornil l narg then d
  else checklstring l narg
;;

let optstring = optlstring;;

let checkstring = checklstring;;

let checkoption l narg def lst =
  let name =
    match def with
    | Some s -> optstring l narg s
    | None -> checkstring l narg in

  let rec find ?(i=0) p xs =
    match xs with
    | [] -> argerror l narg (pushfstring l "invalid option '%s'" name)
    | hd::tl -> if p hd then i else find ~i:(i+1) p tl in

  find (fun s -> s = name) lst
;;

external error_aux : state -> string -> 'a = "luaL_error__stub"

let error state =
  let k s = error_aux state s in
    Printf.kprintf k
;;

let checkstack l space mes =
  if not (Lua_api_lib.checkstack l space)
  then error l "stack overflow (%s)" mes
  else ()
;;

let checktype l narg t =
  if (Lua_api_lib.type_ l narg <> t)
  then tag_error l narg t
  else ()
;;

let checkudata l ud tname =
  let te = lazy (typerror l ud tname) in
  let p = touserdata l ud in
  match p with
  | Some data -> begin
      if (Lua_api_lib.getmetatable l ud) then begin
        getfield l registryindex tname;
        if (rawequal l (-1) (-2))
        then (pop l 2; p)
        else Lazy.force te
      end else Lazy.force te
    end
  | None -> Lazy.force te
;;

external luaL_loadfile__wrapper : state -> string -> int = "luaL_loadfile__stub"

let loadfile l filename =
  luaL_loadfile__wrapper l filename |> thread_status_of_int
;;

let dofile l filename =
  match loadfile l filename with
  | LUA_OK -> begin
      match pcall l 0 multret 0 with
      | LUA_OK -> true
      | _ -> false
    end
  | _ -> false
;;

external luaL_loadbuffer__wrapper :
  state -> string -> int -> string -> int = "luaL_loadbuffer__stub"

let loadbuffer l buff name =
  luaL_loadbuffer__wrapper l buff (String.length buff) name |> thread_status_of_int
;;

let loadstring l s =
  loadbuffer l s s
;;

let dostring l str =
  match loadstring l str with
  | LUA_OK -> begin
      match pcall l 0 multret 0 with
      | LUA_OK -> true
      | _ -> false
    end
  | _ -> false
;;

external getmetafield : state -> int -> string -> bool = "luaL_getmetafield__stub"

external getmetatable : state -> string -> unit = "luaL_getmetatable__stub"

external gsub : state -> string -> string -> string -> string = "luaL_gsub__stub"

external newmetatable : state -> string -> bool = "luaL_newmetatable__stub"

external newstate : unit -> state = "luaL_newstate__stub"

external openlibs : state -> unit = "luaL_openlibs__stub"

external optinteger : state -> int -> int -> int = "luaL_optinteger__stub"

let optint = optinteger

external optlong : state -> int -> int -> int = "luaL_optlong__stub"

let optnumber l narg d =
  if Lua_api_lib.isnoneornil l narg
  then d
  else checknumber l narg
;;
