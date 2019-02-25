type debug_level =
  | Debug_only
  | User_info
;;

let debug = Debug_only;;
(* let debug = User_info;; *)

let log =
  fun level ->
    let k m =
      match debug, level with
      | User_info, Debug_only -> ()
      | _, _ -> Printf.printf "%s\n%!" m in
    Printf.kprintf k
;;

let sleep_float n =
  let _ = Unix.select [] [] [] n in ()
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
    log Debug_only "Run time: %f sec" run_time;
    log Debug_only "Self:     %f sec" self;
    log Debug_only "     sys: %f sec" self_u;
    log Debug_only "    user: %f sec" self_s;
    log Debug_only "Children: %f sec" child;
    log Debug_only "     sys: %f sec" child_u;
    log Debug_only "    user: %f sec" child_s;
    log Debug_only "GC:     minor: %d"
      (end_space.Gc.minor_collections - start_space.Gc.minor_collections);
    log Debug_only "        major: %d"
      (end_space.Gc.major_collections - start_space.Gc.major_collections);
    log Debug_only "  compactions: %d"
      (end_space.Gc.compactions - start_space.Gc.compactions);
    log Debug_only "Allocated:  %.1f words"
      (end_space.Gc.minor_words +. end_space.Gc.major_words
       -. start_space.Gc.minor_words -. start_space.Gc.major_words
       -. end_space.Gc.promoted_words +. start_space.Gc.promoted_words);
    log Debug_only "Wall clock:  %.0f sec (%02d:%02d:%02d)"
      real_time real_time_hrs real_time_min real_time_sec;
    if real_time > 0. then
      log Debug_only "Load:  %.2f%%" (run_time *. 100.0 /. real_time)
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

let string_list_eq l1 l2 =
  List.fold_left2
    (fun eq x1 x2 ->
      if eq = false
      then false
      else if Bytes.compare x1 x2 = 0
           then true
           else false) true l1 l2
;;

let allocate ?(random=true) how_many str_len =
  let l = ref [] in
  for _i = 1 to how_many
  do
    let s = Bytes.create str_len in
    for j = 0 to (str_len - 1) do
      if random
      then Bytes.set s j (Char.chr (Random.int 256))
      else Bytes.set s j 'x'
    done;
    l := s::(!l);
  done;
  !l
;;

let allocate_a_lot () = allocate 47 9973;;

let allocate_many_small () = allocate 9973 47;;

