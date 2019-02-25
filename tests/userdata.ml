open Lua_api

let (|>) x f = f x;;

let allocate how_many str_len =
  let l = ref [] in
  for _i = 1 to how_many
  do
    let s = Bytes.create str_len in
    l := s::(!l);
  done;
  !l

let allocate_a_lot () = allocate 499 99991
let allocate_many_small () = allocate 99991 499

module LuaBookDir =
struct
  let readdir ls =
    let handle : Unix.dir_handle =
      let w = Lua.touserdata ls 1 in
      match w with
      | Some `Userdata h -> h
      | _ -> failwith "Dir handle expected!" in
    try Lua.pushstring ls (Unix.readdir handle); 1
    with End_of_file -> 0

  let dir_gc ls =
    let handle : Unix.dir_handle =
      let w = Lua.touserdata ls 1 in
      match w with
      | Some `Userdata h -> h
      | _ -> failwith "Dir handle expected!" in
    Unix.closedir handle;
    0

  let ocaml_handle_gc h =
    Unix.closedir h

  let opendir ls =
    let path = LuaL.checkstring ls 1 in
    let handle =
      try Unix.opendir path
      with Unix.Unix_error (err, _, _) ->
        LuaL.error ls "cannot open %s: %s" path (Unix.error_message err) in
    Lua.newuserdata ls handle;
    LuaL.getmetatable ls "LuaBook.dir";
    Lua.setmetatable ls (-2) |> ignore;
    1

  let allocate_ocaml_data ls =
    let data1 = allocate_many_small () in
    let data2 = allocate_a_lot () in
    Lua.newuserdata ls data1;
    Lua.newuserdata ls data2;
    1

  let gc_compact _ls =
    Printf.printf "Calling Gc.compact 2 times from Lua... %!";
    Gc.compact ();
    Gc.compact ();
    Printf.printf "done!\n%!";
    0

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

    Lua.pushocamlfunction ls gc_compact;
    Lua.setglobal ls "gc_compact";

    Lua.pushocamlfunction ls allocate_ocaml_data;
    Lua.setglobal ls "allocate_ocaml_data";
end;;

let closure () =
  let l1 = LuaL.newstate () in
  LuaL.openlibs l1;
  LuaBookDir.luaopen_dir l1;
  LuaL.loadbuffer l1 "handle = opendir(\"/\")
gc_compact()  -- triggers a heap compaction of the OCaml GC
d = readdir(handle)
ocaml_data = allocate_ocaml_data()
while d ~= nul do
-- print(\"dir is: \" .. d)
  d = readdir(handle)
end
" "test_program" |> ignore;
  match Lua.pcall l1 0 0 0 with
  | Lua.LUA_OK -> ()
  | _err -> begin
      Printf.printf "%s\n%!" (Lua.tostring l1 (-1) |> Option.value ~default:"");
      Lua.pop l1 1;
      failwith "FATAL ERROR"
    end
;;

let print_timings start_space start_wtime start_ptime =
  let end_ptime = Unix.times () in      (* process time *)
  let self_u = end_ptime.Unix.tms_utime -. start_ptime.Unix.tms_utime in
  let self_s = end_ptime.Unix.tms_stime -. start_ptime.Unix.tms_stime in
  let self = self_u +. self_s in
  let child_u = end_ptime.Unix.tms_cutime -. start_ptime.Unix.tms_cutime in
  let child_s = end_ptime.Unix.tms_cstime -. start_ptime.Unix.tms_cstime in
  let child = child_u +. child_s in
  let run_time = self +. child in
  let real_time = Unix.time () -. start_wtime in (* wall time *)
  let real_time_sec = int_of_float real_time in
  let real_time_min = real_time_sec / 60 in
  let real_time_sec = real_time_sec mod 60 in
  let real_time_hrs = real_time_min / 60 in
  let real_time_min = real_time_min mod 60 in
  (* we would need a compaction if we were reporting memory usage *)
  (* Gc.compact (); *)
  let end_space = Gc.quick_stat () in
    Printf.printf "Run time: %f sec\n%!" run_time;
    Printf.printf "Self:     %f sec\n%!" self;
    Printf.printf "     sys: %f sec\n%!" self_u;
    Printf.printf "    user: %f sec\n%!" self_s;
    Printf.printf "Children: %f sec\n%!" child;
    Printf.printf "     sys: %f sec\n%!" child_u;
    Printf.printf "    user: %f sec\n%!" child_s;
    Printf.printf "GC:     minor: %d\n%!"
      (end_space.Gc.minor_collections - start_space.Gc.minor_collections);
    Printf.printf "        major: %d\n%!"
      (end_space.Gc.major_collections - start_space.Gc.major_collections);
    Printf.printf "  compactions: %d\n%!"
      (end_space.Gc.compactions - start_space.Gc.compactions);
    Printf.printf "Allocated:  %.1f words\n%!"
      (end_space.Gc.minor_words +. end_space.Gc.major_words
       -. start_space.Gc.minor_words -. start_space.Gc.major_words
       -. end_space.Gc.promoted_words +. start_space.Gc.promoted_words);
    Printf.printf "Wall clock:  %.0f sec (%02d:%02d:%02d)\n%!"
      real_time real_time_hrs real_time_min real_time_sec;
    if real_time > 0. then
      Printf.printf "Load:  %.2f%%\n%!" (run_time *. 100.0 /. real_time)
;;

(* Run function, then report time and space usage *)
let run func args =
  Gc.compact (); (* so that prior execution does not skew the results *)
  let start_space = Gc.quick_stat () in
  let start_wtime = Unix.time () in     (* wall time *)
  let start_ptime = Unix.times () in    (* process time *)
  let ret =
    try func args
    with e -> print_timings start_space start_wtime start_ptime;
              raise e in
  print_timings start_space start_wtime start_ptime;
  ret
;;

let test_duration = 60.0 *. 10.0;;
let time_start = Unix.gettimeofday ();;

let main () =
  while Unix.gettimeofday () <  time_start +. test_duration do
    closure () |> ignore;
    Printf.printf "Calling Gc.compact from OCaml... %!";
    Gc.compact ();
    Printf.printf "done!\n%!";
  done;
  Gc.compact ();
;;

run main ()

