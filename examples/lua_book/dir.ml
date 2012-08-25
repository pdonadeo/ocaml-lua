open Lua_api;;

let (|>) x f = f x;;

let getopt o =
  match o with
  | Some v -> v
  | None -> raise Not_found
;;

module LuaBookDir =
struct
  let readdir ls =
    let open Unix in
    let handle : dir_handle =
      let w = Lua.touserdata ls 1 in
      match w with
      | Some `Userdata h -> h
      | _ -> failwith "Dir handle expected!" in
    try Lua.pushstring ls (readdir handle); 1
    with End_of_file -> 0

  let dir_gc ls =
    let open Unix in
    let handle : dir_handle =
      let w = Lua.touserdata ls 1 in
      match w with
      | Some `Userdata h -> h
      | _ -> failwith "Dir handle expected!" in
    closedir handle;
    0

  let is_symlink ls =
    let open Unix in
    let path = LuaL.checkstring ls 1 in
    try
      let stat = lstat path in
      match stat.st_kind with
      | S_LNK -> (Lua.pushboolean ls true; 1)
      | _ -> (Lua.pushboolean ls false; 1)
    with Unix_error (err, _, _) -> 0

  let opendir ls =
    let open Unix in
    let path = LuaL.checkstring ls 1 in
    try
      let handle = opendir path in
      Lua.newuserdata ls handle;
      LuaL.getmetatable ls "LuaBook.dir";
      Lua.setmetatable ls (-2) |> ignore;
      1
    with Unix_error (err, _, _) -> 0

  let luaopen_dir ls =
    (* metatable for "dir" *)
    LuaL.newmetatable ls "LuaBook.dir" |> ignore;
    Lua.pushstring ls "__gc";
    Lua.pushocamlfunction ls (Lua.make_gc_function dir_gc);
    Lua.settable ls (-3) |> ignore;
    
    Lua.pushocamlfunction ls opendir;
    Lua.setglobal ls "opendir";

    Lua.pushocamlfunction ls readdir;
    Lua.setglobal ls "readdir";

    Lua.pushocamlfunction ls is_symlink;
    Lua.setglobal ls "is_symlink";
end;;

let main () =
  let ls = LuaL.newstate () in
  LuaL.openlibs ls;
  LuaBookDir.luaopen_dir ls;
  let () =
    try
      LuaL.loadfile ls Sys.argv.(1) |> ignore
    with Invalid_argument _ -> begin
      Printf.eprintf "Usage: %s examples/lua_book/dir.lua\n%!" Sys.argv.(0);
      exit 1 |> ignore
    end in
  match Lua.pcall ls 0 0 0 with
  | Lua.LUA_OK -> ()
  | err -> begin
      let err_msg = (Lua.tostring ls (-1) |> getopt) in
      Lua.pop ls 1;
      failwith err_msg
    end
;;

main ();;
