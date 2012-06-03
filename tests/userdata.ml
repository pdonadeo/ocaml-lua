open Lua_api

let (|>) x f = f x;;

let allocate how_many str_len =
  let l = ref [] in
  for i = 1 to how_many
  do
    let s = String.create str_len in
    l := s::(!l);
  done;
  !l

let allocate_a_lot () = allocate 499 99991
let allocate_many_small () = allocate 99991 499

module LuaBookDir =
struct
  let readdir l =
    let handle : Unix.dir_handle =
      let w = Lua.touserdata l 1 in
      match w with
      | Some `Userdata h -> h
      | _ -> failwith "Dir handle expected!" in
    try Lua.pushstring l (Unix.readdir handle); 1
    with End_of_file -> 0

  let dir_gc l =
    let handle : Unix.dir_handle =
      let w = Lua.touserdata l 1 in
      match w with
      | Some `Userdata h -> h
      | _ -> failwith "Dir handle expected!" in
    Unix.closedir handle;
    0

  let ocaml_handle_gc h =
    Unix.closedir h

  let opendir l =
    let path = LuaL.checkstring l 1 in
    let handle =
      try Unix.opendir path
      with Unix.Unix_error (err, _, _) ->
        LuaL.error l "cannot open %s: %s" path (Unix.error_message err) in
    Lua.newuserdata l handle;
    LuaL.getmetatable l "LuaBook.dir";
    Lua.setmetatable l (-2) |> ignore;
    1

  let allocate_ocaml_data l =
    let data1 = allocate_many_small () in
    let data2 = allocate_a_lot () in
    Lua.newuserdata l data1;
    Lua.newuserdata l data2;
    1

  let gc_compact l =
    Printf.printf "Calling Gc.compact 2 times from Lua... %!";
    Gc.compact ();
    Gc.compact ();
    Printf.printf "done!\n%!";
    0

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

    Lua.pushocamlfunction l gc_compact;
    Lua.setglobal l "gc_compact";

    Lua.pushocamlfunction l allocate_ocaml_data;
    Lua.setglobal l "allocate_ocaml_data";
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
  | err -> begin
      Printf.printf "%s\n%!" (Lua.tostring l1 (-1));
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

