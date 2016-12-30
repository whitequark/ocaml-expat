(***********************************************************************)
(* The OcamlExpat library                                              *)
(*                                                                     *)
(* Copyright 2002, 2003 Maas-Maarten Zeeman. All rights reserved. See  *)
(* LICENCE for details.                                                *)
(***********************************************************************)

open Expat
open OUnit

(* All errors except XML_ERROR_NONE *)
let xml_errors =
  [NO_MEMORY; SYNTAX; NO_ELEMENTS; INVALID_TOKEN; UNCLOSED_TOKEN;
   PARTIAL_CHAR; TAG_MISMATCH; DUPLICATE_ATTRIBUTE;
   JUNK_AFTER_DOC_ELEMENT; PARAM_ENTITY_REF; UNDEFINED_ENTITY;
   RECURSIVE_ENTITY_REF; ASYNC_ENTITY; BAD_CHAR_REF;
   BINARY_ENTITY_REF; ATTRIBUTE_EXTERNAL_ENTITY_REF; MISPLACED_XML_PI;
   UNKNOWN_ENCODING; INCORRECT_ENCODING; UNCLOSED_CDATA_SECTION;
   EXTERNAL_ENTITY_HANDLING; NOT_STANDALONE; UNEXPECTED_STATE;
   ENTITY_DECLARED_IN_PE; FEATURE_REQUIRES_XML_DTD;
   CANT_CHANGE_FEATURE_ONCE_PARSING;] ;;

let (@=?) = assert_equal ~printer:string_of_int

let rec loop f = function
    0 -> ()
  | n ->
      ignore(f ());
      loop f (n - 1)

let get_some = function
    None -> "None";
  | Some s -> "Some " ^ s

let suite = "expat" >:::
  ["expat_version" >::
     (fun () ->
	"Unable to get expat_version" @? (expat_version () <> "")
     );

   "xml_error_to_string" >::
     (fun _ ->
	assert_equal "" (xml_error_to_string NONE)
	  ~printer:(fun x-> "\"" ^ x ^ "\"");

	List.iter (fun e ->
		     "did not get an error string"  @?
		       ((xml_error_to_string e) <> ""))
	  xml_errors;
     );

   "get_current_byte_index" >::
     (fun _ ->
	let p = parser_create None in
	let byte_index = fun _ -> get_current_byte_index p in
	  (-1) @=? (byte_index ());
	  parse p "<tag>";
	  5 @=? (byte_index ());
	  parse p "    ";
	  9 @=? (byte_index ());
	  parse p "<a><b><c>blah</c></b></a>";
	  34 @=? (byte_index ());
     );

   (* This does not work on expat 1.95.5, but it will work with 1.95.6 *)
   "get_current_column_number" >::
     (fun _ ->
	(* (Should) return the current column number *)
	(* Note: expat_1.95.5 returns wrong answers here *)
	let p = parser_create None in
	let column_number = fun _ -> get_current_column_number p in
	  0 @=? (column_number ());
	  parse p "<tag>";
	  5 @=? (column_number ());
	  parse p " ";
	  6 @=? (column_number ());
	  parse p "    ";
	  10 @=? (column_number ());
	  parse p "<blah>";
	  16 @=? (column_number ());
	  parse p "\n";
	  0 @=? (column_number ());
	  parse p "<spam>";
	  6 @=? (column_number ());
     );

   "get_current_line_number" >::
     (fun _ ->
	(* (Should) return the current line number *)
	(* expat_1.95.5 returns wrong answers here. Fixed expat_1.95.6 *)
	let p = parser_create None in
	let line_number = fun _ -> get_current_line_number p in
	  1 @=? (line_number ());
	  parse p "<tag>\n\n\n</tag>";
	  4 @=? (line_number ());
     );

   "get_current_line_number_from_handler" >::
     (fun _ ->
	(* Check the current line number from within the handler *)
	let p = parser_create None in
	let line_number = fun _ -> get_current_line_number p in
	let expected_line = ref 0 in
	let start_element_handler tag attrs =
	  assert_equal !expected_line (line_number ())
	    ~msg:("start tag: " ^ tag) ~printer:string_of_int;
	in
	let end_element_handler tag =
	  assert_equal !expected_line (line_number ())
	    ~msg:("end tag: " ^ tag) ~printer:string_of_int
	in
	  set_start_element_handler p start_element_handler;
	  set_end_element_handler p end_element_handler;
	  expected_line := 1;
	  parse p "<a>\n";
	  expected_line := 2;
	  parse p "<b><c>";
	  expected_line := 4;
	  parse p "\n\n</c></b>";
	  expected_line := 7;
	  parse p "\n\n\n<d>";
	  !expected_line  @=? (line_number ())
     );

   "get_current_byte_count" >::
     (fun _ ->
	(* Returns the number of bytes in the current event.
           I'm not sure what it should return *)
	let p = parser_create None in
	let byte_count = fun _ -> get_current_byte_count p in
	  0 @=? (byte_count ());
	  parse p "<tag>";
	  0 @=? (byte_count ());
	  parse p "bla bla bla";
	  0 @=? (byte_count ());
	  parse p "<another-tag ";
	  0 @=? (byte_count ());
     );

   "start & end element handlers" >::
     (fun _ ->
	(* test the start element handler *)
	let p = parser_create None in
	let expected_start_tag = ref "" in
	let expected_end_tag = ref "" in
	let start_handler tag attrs =
	  assert_equal !expected_start_tag tag
	    ~msg:("start tag: " ^ tag) ~printer:(fun x -> x)
	in
	let end_handler tag =
	  assert_equal !expected_end_tag tag
	    ~msg:("end tag: " ^ tag) ~printer:(fun x -> x)
	in

	  set_start_element_handler p start_handler;
	  set_end_element_handler p end_handler;

	  expected_start_tag := "a";
	  parse p "<a>blah blah bla\n";

	  expected_start_tag := "b";
	  expected_end_tag := "b";
	  parse p "  <b>\n</b>";

	  expected_start_tag := "c";
	  parse p "  <c>\n";

	  expected_end_tag := "c";
	  parse p "  </c>";

	  expected_end_tag := "a";
	  parse p "</a>";

	  final p;
     );

   "start element handler" >::
     (fun _ ->
	let p = parser_create None in
	let buf = Buffer.create 10 in
	let start_handler tag attrs =
	  Buffer.add_string buf "/";
	  Buffer.add_string buf tag;
	in
	  set_start_element_handler p start_handler;

	  parse p ("<a>\n" ^
		     "  <b>\n" ^
		     "    <c/>\n" ^
		     "  </b>\n" ^
		     "  <d>blah blah\n" ^
		     "    <e/>" ^
		     "  </d>\n" ^
		     "</a>\n");
	  final p;
	  assert_equal "/a/b/c/d/e" (Buffer.contents buf) ~printer:(fun x->x));

   "end element handler" >::
     (fun _ ->
	let p = parser_create None in
	let buf = Buffer.create 10 in
	let end_handler tag =
	  Buffer.add_string buf "/";
	  Buffer.add_string buf tag;
	in
	  set_end_element_handler p end_handler;
	  parse p ("<a>\n" ^
		     "  <b>\n" ^
		     "    <c/>\n" ^
		     "  </b>\n" ^
		     "  <d>blah blah\n" ^
		     "    <e/>\n" ^
		     "  </d>\n" ^
		     "</a>\n");
	  final p;
	  assert_equal "/c/b/e/d/a" (Buffer.contents buf) );

   "character data handler" >::
     (fun _ ->
	let p = parser_create None in
	let buf = Buffer.create 10 in
	let character_data_handler data =
	  Buffer.add_string buf data
	in
	  set_character_data_handler p character_data_handler;
	  parse p ("<a>\n" ^
		     "..<b>\n" ^
		     "....<c/>\n" ^
		     "..</b>\n" ^
		     "..<d>blah blah\n" ^
		     "....<e/>\n" ^
		     "..</d>\n" ^
		     "</a>\n");
	  final p;
	  assert_equal "\n..\n....\n..\n..blah blah\n....\n..\n"
	    (Buffer.contents buf)
	    ~printer:String.escaped);

   "processing instruction handler" >::
     (fun _ ->
	let p = parser_create None in
	let buf = Buffer.create 10 in
	let checked = ref false in
	let pi_handler target data =
	  assert_equal "target" target ~printer:String.escaped;
	  assert_equal "data" data ~printer:String.escaped;
	  checked := true
	in
	  set_processing_instruction_handler p pi_handler;
	  parse p ("<a>\n" ^
		     "  <b>\n" ^
		     "    <c/>\n" ^
		     "  </b>\n" ^
		     "  <d>blah blah\n" ^
		     "  <?target data?>\n" ^
		     "    <e/>\n" ^
		     "  </d>\n" ^
		     "</a>\n");
	  final p;
	  "Did not receive a processing instruction." @? !checked);

   "start cdata handler" >::
     (fun _ ->
	let p = parser_create None in
	let got_start_cdata = ref false in
	let start_cdata_handler _ =
	  got_start_cdata := true
	in
	  set_start_cdata_handler p start_cdata_handler;
	  parse p ("<a>\n" ^
		     "  <b>\n" ^
		     "    <c/>\n" ^
		     "  </b>\n" ^
		     "  <d>\n" ^
		     "  <![CDATA[  foo <<< blah  ]]>" ^
		     "    <e/>\n" ^
		     "  </d>\n" ^
		     "</a>\n");
	  final p;
	  "Did not get a start cdata." @? !got_start_cdata);

   "end cdata handler" >::
     (fun _ ->
	let p = parser_create None in
	let got_end_cdata = ref false in
	let end_cdata_handler x =
	  got_end_cdata := true
	in
	  set_end_cdata_handler p end_cdata_handler;
	  parse p ("<a>\n" ^
		     "  <b>\n" ^
		     "    <c/>\n" ^
		     "  </b>\n" ^
		     "  <d>blah blah\n" ^
		     "  <![CDATA[foo \n\n<<<>>> blah]]>" ^
		     "    <e/>\n" ^
		     "  </d>\n" ^
		     "</a>\n");
	  final p;
	  "Did not get an end cdata." @? !got_end_cdata
     );

   "default handler" >::
     (fun _ ->
	let p = parser_create None in
	let print_data str =
	  (* print_string str; *)
	  (* print_newline (); *)
	  ()
	in
	  set_default_handler p print_data;
	  parse p ("<a>\n" ^
		     "  <b>\n" ^
		     "    <c/>\n" ^
		     "  </b>\n" ^
		     "  <d>blah blah\n" ^
		     "  <![CDATA[foo \n\n<<<>>> blah]]>" ^
		     "    <e/>\n" ^
		     "  </d>\n" ^
		     "</a>\n");
	  final p;
     );

   "external entity ref handler" >::
     (fun _ ->
	let p = parser_create None in
	let print_data tag str =
	  print_string tag;
	  print_string str;
	  print_newline ()
	in
	let buf = Buffer.create 10 in
	let add_string = Buffer.add_string in
	let external_entity_handler context base system_id public_id =
	  let p_e = external_entity_parser_create p context None in
	    parse p_e ("<!ELEMENT doc (#PCDATA)*>\n" ^
			 "<!ENTITY entity \"entity\">");
	    final p_e;
	    add_string buf "#";
	    add_string buf (get_some context);
	    add_string buf "#";
	    add_string buf (get_some base);
	    add_string buf "#";
	    add_string buf system_id;
	    add_string buf "#";
	    add_string buf (get_some public_id);
	    add_string buf "#";
	in
	  ignore (set_param_entity_parsing p ALWAYS);
	  set_external_entity_ref_handler p external_entity_handler;
	  parse p ("<?xml version='1.0' encoding='us-ascii'?>\n" ^
		     "<!DOCTYPE doc PUBLIC 'frizzle' 'fry'>\n" ^
		     "<doc>&gt; &entity;</doc>");
	  final p;
	  assert_equal "#None#None#fry#Some frizzle#" (Buffer.contents buf)
	    ~printer:(fun x -> x));

   "external entity ref handler 2" >::
     (fun _ ->
	let p = parser_create None in
	let buf = Buffer.create 10 in
	let add_string = Buffer.add_string in
	let external_entity_handler context base system_id public_id =
	  add_string buf "#";
	  add_string buf (get_some context);
	  add_string buf "#";
	  add_string buf (get_some base);
	  add_string buf "#";
	  add_string buf system_id;
	  add_string buf "#";
	  add_string buf (get_some public_id);
	  add_string buf "#";
	in
	  ignore (set_param_entity_parsing p ALWAYS);
	  set_external_entity_ref_handler p external_entity_handler;
	  parse p ("<?xml version='1.0'?>\n" ^
		     "<!DOCTYPE doc SYSTEM 'http://xml.libexpat.org/doc.dtd' [\n" ^
		     "  <!ENTITY en SYSTEM 'http://xml.libexpat.org/entity.ent'>\n" ^
		     "]>\n" ^
		     "<doc xmlns='http://xml.libexpat.org/ns1'>\n" ^
		     "&en;\n" ^
		     "</doc>");
	  final p;
	  assert_equal ("#None#None#http://xml.libexpat.org/doc.dtd#None#" ^
			  "#Some en#None#http://xml.libexpat.org/entity.ent#None#")
	    (Buffer.contents buf)
	    ~printer:(fun x -> x)
     );

   "parse_sub" >::
     (fun _ ->
	let p = parser_create None in
	let buf = Buffer.create 10 in
	let store_data str =
	  Buffer.add_string buf "#";
	  Buffer.add_string buf str;
	  Buffer.add_string buf "#";
	in
	  set_default_handler p store_data;
	  let str = "<a><b><c/></b><d>blah blah<e/></d></a>" in
	    parse_sub p str 0 10;
	    parse_sub p str 10 10;
	    parse_sub p str 20 10;
	    parse_sub p str 30 8;
	    final p;
	    assert_equal
	      "#<a>##<b>##<c/>##</b>##<d>##bla##h blah##<e/>##</d>##</a>#"
	      (Buffer.contents buf) ~printer:(fun x->x)
     );

   "parse_sub wrong input" >::
     (fun _ ->
	let p = parser_create None in
	let check_raises_Invalid_arg f =
	  try
	    f();
	    assert_string("No invalid_arg raised")
	  with Invalid_argument(s) ->
	    ()
	in
	  check_raises_Invalid_arg (fun _ -> parse_sub p "" (-1) 0);
	  check_raises_Invalid_arg (fun _ -> parse_sub p "" 0 (-1));
	  check_raises_Invalid_arg (fun _ -> parse_sub p "" 0 1));

   "set/get base" >::
     (fun _ -> let p = parser_create None in
	assert_equal None (get_base p);
	set_base p (Some "This is the base");
	assert_equal (Some "This is the base") (get_base p);
	set_base p None;
	assert_equal None (get_base p)
     );

   "simple garbage collection test" >::
     (fun _ ->
	let rec create_and_collect_garbage = function
	    0 -> Gc.full_major ()
	  | n ->
              let a = Array.init n (fun x -> String.create ((x + 2) * 200)) in
              let out = open_out "/dev/null" in
		Array.iter (fun str -> output_string out str) a;
		close_out out;
		create_and_collect_garbage (n - 1)
	in

     let do_stuff _ =
       let p1 = parser_create None in
       let p2 = parser_create None in
       let dummy_handler _ s =
	 create_and_collect_garbage 13
       in
       let external_entity_handler a b c d =
	 create_and_collect_garbage 14
       in
	 set_start_element_handler p1 dummy_handler;
	 set_start_element_handler p2 dummy_handler;

	 set_end_element_handler p1 (dummy_handler ());
	 set_end_element_handler p2 (dummy_handler ());

	 set_character_data_handler p1 (dummy_handler ());
	 set_character_data_handler p2 (dummy_handler ());

	 set_default_handler p1 (dummy_handler ());
	 set_default_handler p2 (dummy_handler ());

	 ignore (set_param_entity_parsing p1 ALWAYS);
	 ignore (set_param_entity_parsing p2 ALWAYS);
	 set_external_entity_ref_handler p1 external_entity_handler;
	 set_external_entity_ref_handler p2 external_entity_handler;

	 List.iter (fun str ->
		      parse p1 str;
		      create_and_collect_garbage 23;
		      parse p2 str;
		      create_and_collect_garbage 31)
	   ["<?xml version='1.0' ?>\n";
            "<!DOCTYPE a PUBLIC 'frizzle' 'fry'>\n";
	    "<a>"; "<b>"; "</b>";
	    "This is a bit of data";
	    "and an &entity;";
	    "<a tag='with attributes' more='attributes'/>";
	    "<stop-in-the-middle";
	    "of-a-tag a='b'";
	    " b='c' c='d'";
	    " x='y'/>";
	    "</a>"];
	 create_and_collect_garbage 13;
	 final p1;
	 create_and_collect_garbage 17;
	 final p2;
     in
       (* This is not fool-proof, but I do not know another way to test
          if the memory management is implemented correctly. The
          strategy is to deliberately force some garbage collections
          here, if everything keeps running, then there is at least not
          something obviously wrong. *)
       loop do_stuff 10
     );

   "another garbage collection test" >::
     (fun _ ->
	let parse _ =
	  let stack = Stack.create () in
	  let start_handler str attrs =
	    Stack.push str stack;
	    List.iter (fun (x, y) -> Stack.push x stack; Stack.push y stack) attrs
	  in
	  let character_data_handler str =
	    Stack.push str stack
	  in
	  let p1 =
	    parser_create None
	  in
	    set_start_element_handler p1 start_handler;
	    set_character_data_handler p1 character_data_handler;
	    let buflen = 1024 in
	    let buf = String.create buflen in
	    let xml_spec =
	      open_in "REC-xml-19980210.xml"
	    in
	    let rec parse _ =
	      let n = input xml_spec buf 0 buflen in
		if (n > 0) then
		  (Expat.parse_sub p1 buf 0 n;
		   parse ())
	    in
	      parse ();
	      Expat.final p1;
	      close_in xml_spec
	in
	  loop parse 10
     );
  ];;

let _ =
  run_test_tt_main suite
