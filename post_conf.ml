#!/usr/bin/env ocaml

#use "topfind";;
#require "unix";;

let (|>) x f = f x;;

module SMap = Map.Make(String);;

let slurp_channel channel =
  let buffer_size = 4096 in
  let buffer = Buffer.create buffer_size in
  let string = String.create buffer_size in
  let chars_read = ref 1 in
  while !chars_read <> 0 do
    chars_read := input channel string 0 buffer_size;
    Buffer.add_substring buffer string 0 !chars_read
  done;
  Buffer.contents buffer
;;

let slurp_file filename =
  let channel = open_in_bin filename in
  let result =
    try slurp_channel channel
    with e -> close_in channel; raise e in
  close_in channel;
  result
;;

let length = String.length;;

exception Stop of int;;

let find_from str pos sub =
  let len = length str in
  let sublen = length sub in
  if pos < 0 || pos > len then raise (Invalid_argument "String.find_from");
  if sublen = 0 then pos else
    try
      for i = pos to len - sublen do
        let j = ref 0 in
        while String.get str (i + !j) = String.get sub !j do
          incr j;
          if !j = sublen then raise (Stop i)
        done;
      done;
      raise Not_found
    with Stop i -> i
;;

let find str sub = find_from str 0 sub;;

let split str ~by:sep =
  let p = find str sep in
  let len = length sep in
  let slen = length str in
  String.sub str 0 p, String.sub str (p + len) (slen - p - len)
;;

let rfind_from str suf sub = 
  let sublen = length sub 
  and len    = length str in
    if sublen = 0 then len
    else
      if len = 0 then raise Not_found else
        if 0 > suf || suf >= len then raise (Invalid_argument "index out of bounds")
        else
        try
          for i = suf - sublen + 1 downto 0 do
            let j = ref 0 in
              while String.get str ( i + !j ) = String.get sub !j do
                incr j;
                if !j = sublen then raise (Stop i)
              done;
          done;
          raise Not_found
        with Stop i -> i
;;

let nsplit str ~by:sep =
  if str = "" then []
  else if sep = "" then invalid_arg "nsplit: empty sep not allowed"
  else
    (* str is non empty *)
    let seplen = String.length sep in
    let rec aux acc ofs =
      if ofs >= 0 then (
        match
          try Some (rfind_from str ofs sep)
          with Not_found -> None
        with
        | Some idx -> (* sep found *)
          let end_of_sep = idx + seplen - 1 in
          if end_of_sep = ofs (* sep at end of str *)
          then aux (""::acc) (idx - 1)
          else
            let token = String.sub str (end_of_sep + 1) (ofs - end_of_sep) in
            aux (token::acc) (idx - 1)
        | None -> (* sep NOT found *)
          (String.sub str 0 (ofs + 1))::acc
      )
      else
        (* Negative ofs: the last sep started at the beginning of str *)
        ""::acc
    in
    aux [] (length str - 1 )
;;

let is_space = function
  | ' ' | '\012' | '\n' | '\r' | '\t' -> true
  | _ -> false
;;

let trim s =
  let open String in
  let len = length s in
  let i = ref 0 in
  while !i < len && is_space (unsafe_get s !i) do
    incr i
  done;
  let j = ref (len - 1) in
  while !j >= !i && is_space (unsafe_get s !j) do
    decr j
  done;
  if !i = 0 && !j = len - 1 then
    s
  else if !j >= !i then
    sub s !i (!j - !i + 1)
  else
    ""
;;

let read_setup_data filename =
  let content = slurp_file filename in
  let lines = nsplit content "\n" |>
                List.map trim |> 
                  List.filter ((<>) "") in
  List.fold_left
    (fun map l ->
      let key, value = split l ~by:"=" in
      let key = trim key in
      let value = trim value in
      let value = String.sub value 1 ((String.length value) - 2) in
      let value = trim value in
      SMap.add key value map)
    SMap.empty
    lines
;;

let write_setup_data filename map =
  let oc = open_out filename in
  SMap.iter (fun k v -> Printf.fprintf oc "%s=\"%s\"\n" k v) map;
  close_out oc;
;;

let rec restart_on_EINTR f x =
  try f x with Unix.Unix_error (Unix.EINTR, _, _) -> restart_on_EINTR f x
;;

let buf_len = 8192;;

let input_all fd =
  let rec loop acc total buf ofs =
    let n = Unix.read fd buf ofs (buf_len - ofs) in
    if n = 0 then
      let res = String.create total in
      let pos = total - ofs in
      let _ = String.blit buf 0 res pos ofs in
      let coll pos buf =
        let new_pos = pos - buf_len in
        String.blit buf 0 res new_pos buf_len;
        new_pos in
      let _ = List.fold_left coll pos acc in
      res
    else
      let new_ofs = ofs + n in
      let new_total = total + n in
      if new_ofs = buf_len then
        loop (buf :: acc) new_total (String.create buf_len) 0
      else
        loop acc new_total buf new_ofs in
  loop [] 0 (String.create buf_len) 0
;;

let spawn args =
  let open Unix in
  let in_descr, out_descr = pipe () in
  try
    match fork () with
    | 0 -> begin    (* child *)
        close in_descr;
        dup2 out_descr stdout;
        dup2 out_descr stderr;
        close out_descr;
        try execvp args.(0) args with _ -> exit 137
      end
    | pid -> begin  (* parent *)
        close out_descr;
        let all = input_all in_descr in
        close in_descr;
        let _, status = (restart_on_EINTR (waitpid []) pid) in
        let ret =
          match status with
          | WEXITED ret_code -> Some ret_code
          | WSIGNALED _ -> None
          | WSTOPPED _ -> None in
        ret, all
      end
  with e -> begin
    close in_descr;
    close out_descr;
    None, ""
  end
;;

let compiler ?(cc_name = "gcc") ?(temp_dir = "/tmp") ?(prefix = "test") ?(options = [| "-Wall" |]) source =
  let pwd = Sys.getcwd () in
  Sys.chdir temp_dir;
  let name, out_ch = Filename.open_temp_file ~temp_dir prefix ".c" in
  output_string out_ch source;
  close_out out_ch;
  let args = Array.append [| cc_name; name |] options in
  let ret, output = spawn args in
  Sys.chdir pwd;
  let cmd = String.concat " " (Array.to_list args) in
  match ret with
  | None ->
      `Err (-1, (Printf.sprintf "COMMAND \"%s\" WAS TERMINATED BY SIGNAL\n" cmd))
  | Some code -> begin
      if code = 0 then begin
        Unix.unlink name;
        `Ok code
      end else begin
        `Err (code, (Printf.sprintf "================================================================================\n\
                                     COMMAND \"%s\" FAILED WITH STATUS %d. OUTPUT WAS:\n-------------------\n\
                                     %s\n\
                                     ================================================================================\n"
                                    cmd code (trim output)));
      end
    end
;;

let test_program = "\
#include <stdio.h>
#include \"lua.h\"
#include \"lauxlib.h\"
#include \"lualib.h\"

int main (void) {
  char buff[256];
  int error;
  lua_State *L = luaL_newstate();
  luaL_openlibs(L);

  while (fgets(buff, sizeof(buff), stdin) != NULL) {
    error = luaL_loadbuffer(L, buff, strlen(buff), \"line\") ||
            lua_pcall(L, 0, 0, 0);
    if (error) {
      fprintf(stderr, \"%s\", lua_tostring(L, -1));
      lua_pop(L, 1);
    }
  }

  lua_close(L);
  return 0;
}";;

exception Cant_compile of string
exception Cant_link of string

let search_options cc ccopt_to_try cclib_to_try base_options prefix setup_data_map =
  let cc_idx, compile, message =
    Array.fold_left
      (fun (idx, compile, _) options ->
        let options = Array.append base_options options in
        let options = Array.append options [| "-c" |] in
        if compile
        then (idx, true, "")
        else begin
          let res = compiler ~cc_name:cc ~prefix ~options test_program in
          match res with
          | `Ok _ -> (idx, true, "")
          | `Err (ret_code, message) -> (idx + 1, false, message)
        end)
      (0, false, "")
      ccopt_to_try in

  if compile then begin
    let lib_idx, link, message =
      Array.fold_left
        (fun (idx, link, _) options ->
          let options = Array.append base_options options in
          let options = Array.append options ccopt_to_try.(cc_idx) in
          if link
          then (idx, true, "")
          else begin
            let res = compiler ~cc_name:cc ~prefix ~options test_program in
            match res with
            | `Ok _ -> (idx, true, "")
            | `Err (ret_code, message) -> (idx + 1, false, message)
          end)
        (0, false, "")
        cclib_to_try in

    if link then begin
      let setup_data_map = SMap.add
        "my_ccopt"
        (String.concat " " (Array.to_list ccopt_to_try.(cc_idx)))
        setup_data_map in
      let setup_data_map = SMap.add
        "my_cclib"
        (String.concat " " (Array.to_list cclib_to_try.(lib_idx)))
        setup_data_map in
      setup_data_map
    end else raise (Cant_link message)
  end else raise (Cant_compile message)
;;

let search_options_for_lua cc base_options prefix setup_data_map =
  let ccopt_to_try, cclib_to_try =
    if SMap.find "system" setup_data_map = "macosx"
    then begin
      (* OSX *)
      let ret, output = spawn [| "brew"; "--prefix"|] in
      match ret with
      | None
      | Some 137 -> [||], [||]
      | Some _ -> begin
          let homebrew_prefix = trim output in
          let include_dir = homebrew_prefix ^ "/" ^ "include" in
          let lib_dir = homebrew_prefix ^ "/" ^ "lib" in
          let ccopt_to_try = [|
              [| "-O3"; "-Wall"; "-Isrc/"; "-I" ^ include_dir |];
            |] in
          let cclib_to_try = [|
              [| "-L" ^ lib_dir; "-llua"; "-lm"|]
            |] in
          ccopt_to_try, cclib_to_try
        end
    end else begin
      (* Linux *)
      let ccopt_to_try = [|
          [| "-O3"; "-Wall"; "-Isrc/"; "-I/usr/include/lua5.1" |];
          [| "-O3"; "-Wall"; "-Isrc/" |]
        |] in
      let cclib_to_try = [|
          [| "-llua5.1" |];
          [| "-llua"; "-lm"|]
        |] in
        ccopt_to_try, cclib_to_try
    end in
  search_options cc ccopt_to_try cclib_to_try base_options prefix setup_data_map
;;

let search_options_for_luajit cc base_options prefix setup_data_map =
  let ccopt_to_try, cclib_to_try =
    if SMap.find "system" setup_data_map = "macosx"
    then begin
      (* OSX *)
      let ret, output = spawn [| "brew"; "--prefix"|] in
      match ret with
      | None
      | Some 137 -> [||], [||]
      | Some _ -> begin
          let homebrew_prefix = trim output in
          let include_dir = homebrew_prefix ^ "/" ^ "include/luajit-2.0" in
          let lib_dir = homebrew_prefix ^ "/" ^ "lib" in
          let ccopt_to_try = [|
              [| "-O3"; "-Wall"; "-Isrc/"; "-I" ^ include_dir; "-DENABLE_LUAJIT" |];
            |] in
          let cclib_to_try = [|
              [| "-L" ^ lib_dir; "-lluajit-5.1"; "-lm"|]
            |] in
          ccopt_to_try, cclib_to_try
        end
    end else begin
      (* Linux *)
      let ccopt_to_try = [|
          [| "-O3"; "-Wall"; "-Isrc/"; "-I/usr/include/luajit-2.0"; "-DENABLE_LUAJIT"; |];
        |] in
      let cclib_to_try = [|
          [| "-lluajit-5.1"; "-lm" |];
        |] in
        ccopt_to_try, cclib_to_try
    end in
  search_options cc ccopt_to_try cclib_to_try base_options prefix setup_data_map
;;

let main () =
  (* We need the "native_c_compiler" from setup.data *)
  let setup_data = "setup.data" in
  let setup_data_map = read_setup_data setup_data in
  let cc_command = SMap.find "native_c_compiler" setup_data_map in
  let string_tokens = nsplit cc_command ~by:" " |> List.map trim |> List.filter ((<>) "") in
  let cc = string_tokens |> List.hd in
  let base_options = string_tokens |> List.tl |> Array.of_list in
  let system = SMap.find "system" setup_data_map in

  try
    let setup_data_map =
      if bool_of_string (SMap.find "luajit" setup_data_map)
      then search_options_for_luajit cc base_options "ocaml-lua_build_" setup_data_map
      else search_options_for_lua cc base_options "ocaml-lua_build_" setup_data_map in
    let setup_data_map = SMap.add "osx_cclib" "" setup_data_map in
    let setup_data_map =
      if system = "macosx"
      then SMap.add "osx_cclib" "-pagezero_size 10000 -image_base 100000000" setup_data_map
      else SMap.add "osx_cclib" "-Wall" setup_data_map in
    write_setup_data setup_data setup_data_map;
  with
  | Cant_compile message -> begin
      Printf.eprintf "FAILED TO COMPILE TEST PROGRAM. MESSAGE IS:\n%s%!" message;
      exit 1;
    end
  | Cant_link message -> begin
      Printf.eprintf "FAILED TO LINK TEST PROGRAM. MESSAGE IS:\n%s%!" message;
      exit 1;
    end
;;

main ();;
