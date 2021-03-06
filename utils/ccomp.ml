(***********************************************************************)
(*                                                                     *)
(*                           Objective Caml                            *)
(*                                                                     *)
(*            Xavier Leroy, projet Cristal, INRIA Rocquencourt         *)
(*                                                                     *)
(*  Copyright 1996 Institut National de Recherche en Informatique et   *)
(*  en Automatique.  All rights reserved.  This file is distributed    *)
(*  under the terms of the Q Public License version 1.0.               *)
(*                                                                     *)
(***********************************************************************)

(* $Id: ccomp.ml,v 1.28.4.2 2008/10/16 15:57:00 doligez Exp $ *)

(* Compiling C files and building C libraries *)

let command cmdline =
  if !Clflags.verbose then begin
    prerr_string "+ ";
    prerr_string cmdline;
    prerr_newline()
  end;
  Sys.command cmdline

let run_command cmdline = ignore(command cmdline)

(* Build @responsefile to work around Windows limitations on 
   command-line length *)
let build_diversion lst =
  let (responsefile, oc) = Filename.open_temp_file "camlresp" "" in
  List.iter (fun f -> Printf.fprintf oc "%s\n" f) lst;
  close_out oc;
  at_exit (fun () -> Misc.remove_file responsefile);
  "@" ^ responsefile

let quote_files lst =
  let lst = List.filter (fun f -> f <> "") lst in
  let quoted = List.map Filename.quote lst in
  let s = String.concat " " quoted in
  if String.length s >= 4096 && Sys.os_type = "Win32"
  then build_diversion quoted
  else s

let quote_prefixed pr lst =
  let lst = List.filter (fun f -> f <> "") lst in
  let lst = List.map (fun f -> pr ^ f) lst in
  quote_files lst

let quote_optfile = function
  | None -> ""
  | Some f -> Filename.quote f

let compile_file name =
  command
    (Printf.sprintf
       "%s -c %s %s %s %s"
       (match !Clflags.c_compiler with
        | Some cc -> cc
        | None ->
            if !Clflags.native_code
            then Config.native_c_compiler
            else Config.bytecomp_c_compiler)
       (String.concat " " (List.rev !Clflags.ccopts))
       (quote_prefixed "-I" (List.rev !Clflags.include_dirs))
       (Clflags.std_include_flag "-I")
       (Filename.quote name))

let create_archive archive file_list =
  Misc.remove_file archive;
  let quoted_archive = Filename.quote archive in
  match Config.ccomp_type with
    "msvc" ->
      command(Printf.sprintf "link /lib /nologo /out:%s %s"
                             quoted_archive (quote_files file_list))
  | _ ->
      let r1 =
        command(Printf.sprintf "ar rc %s %s"
                quoted_archive (quote_files file_list)) in
      if r1 <> 0 || String.length Config.ranlib = 0
      then r1
      else command(Config.ranlib ^ " " ^ quoted_archive)

let expand_libname name =
  if String.length name < 2 || String.sub name 0 2 <> "-l"
  then name
  else begin
    let libname =
      "lib" ^ String.sub name 2 (String.length name - 2) ^ Config.ext_lib in
    try
      Misc.find_in_path !Config.load_path libname
    with Not_found ->
      libname
  end

type link_mode =
  | Exe
  | Dll
  | MainDll
  | Partial

let call_linker target mode output_name files extra =
  let files = quote_files files in
  let cmd =
    if mode = Partial then
      Printf.sprintf "%s%s %s %s"
        Config.native_pack_linker
        (Filename.quote output_name)
        files
        extra
    else
      Printf.sprintf "%s -o %s %s %s %s %s %s %s"
        (match !Clflags.c_compiler, mode, target with
        | Some cc, _, _ -> cc
        | None, Exe, false -> Config.mkexe
        | None, Dll, false -> Config.mkdll
        | None, MainDll, false -> Config.mkmaindll
        | None, Exe, true -> Config.target_mkexe
        | None, Dll, true -> Config.target_mkdll
        | None, MainDll, true -> Config.target_mkmaindll
        | None, Partial, _ -> assert false
        )
        (Filename.quote output_name)
        (if !Clflags.gprofile then Config.cc_profile else "")
        ""  (*(Clflags.std_include_flag "-I")*)
        (quote_prefixed "-L" !Config.load_path)
        files
        extra
        (String.concat " " (List.rev !Clflags.ccopts))
  in
  command cmd = 0
