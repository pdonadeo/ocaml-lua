open Lua_api;;

let (|>) x f = f x;;

let getopt o =
  match o with
  | Some v -> v
  | None -> raise Not_found
;;

module LuaBookDir =
struct
  let readdir l =
    let open Unix in
    let handle : dir_handle =
      let w = Lua.touserdata l 1 in
      match w with
      | Some `Userdata h -> h
      | _ -> failwith "Dir handle expected!" in
    try Lua.pushstring l (readdir handle); 1
    with End_of_file -> 0

  let dir_gc l =
    let open Unix in
    let handle : dir_handle =
      let w = Lua.touserdata l 1 in
      match w with
      | Some `Userdata h -> h
      | _ -> failwith "Dir handle expected!" in
    closedir handle;
    0

  let is_symlink l =
    let open Unix in
    let path = LuaL.checkstring l 1 in
    try
      let stat = lstat path in
      match stat.st_kind with
      | S_LNK -> (Lua.pushboolean l true; 1)
      | _ -> (Lua.pushboolean l false; 1)
    with Unix_error (err, _, _) -> 0

  let opendir l =
    let open Unix in
    let path = LuaL.checkstring l 1 in
    try
      let handle = opendir path in
      Lua.newuserdata l handle;
      LuaL.getmetatable l "LuaBook.dir";
      Lua.setmetatable l (-2) |> ignore;
      1
    with Unix_error (err, _, _) -> 0

  let luaopen_dir l =
    (* metatable for "dir" *)
    LuaL.newmetatable l "LuaBook.dir" |> ignore;
    Lua.pushstring l "__gc";
    Lua.pushocamlfunction l (Lua.make_gc_function dir_gc);
    Lua.settable l (-3) |> ignore;
    
    Lua.pushocamlfunction l opendir;
    Lua.setglobal l "opendir";

    Lua.pushocamlfunction l readdir;
    Lua.setglobal l "readdir";

    Lua.pushocamlfunction l is_symlink;
    Lua.setglobal l "is_symlink";
end;;

let main () =
  let l = LuaL.newstate () in
  LuaL.openlibs l;
  LuaBookDir.luaopen_dir l;
  let () =
    try
      LuaL.loadfile l Sys.argv.(1) |> ignore
    with Invalid_argument _ -> begin
      Printf.eprintf "Usage: %s examples/lua_book/dir.lua\n%!" Sys.argv.(0);
      exit 1 |> ignore
    end in
  match Lua.pcall l 0 0 0 with
  | Lua.LUA_OK -> ()
  | err -> begin
      let err_msg = (Lua.tostring l (-1) |> getopt) in
      Lua.pop l 1;
      failwith err_msg
    end
;;

main ();;
