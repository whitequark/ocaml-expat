(***********************************************************************)
(* The OcamlExpat library                                              *)
(*                                                                     *)
(* Copyright 2002, 2003, 2004, 2005 Maas-Maarten Zeeman. All rights    *)
(* reserved. See  LICENCE for details.                                 *)
(***********************************************************************)

open Bytes

(** The Ocaml Expat library provides an interface to the Expat XML Parser.

    Expat is a library, written C, for parsing XML documents. It's the
    underlying for Mozilla, Perl's [XML::Parser], Python's
    [xml.parser.expat], and other open source XML parsers.

    To use this library, link with
      [ocamlc expat.cma]
    or
      [ocamlopt expat.cmxa]

    @author Maas-Maarten Zeeman
*)

(** The type of expat parsers *)
type expat_parser

(** {5 Parser Creation} *)

(** Create a new XML parser. If encoding is not empty, it specifies
    a character encoding to use for the document. This overrides the
    document encoding declaration. Expat has four built in encodings.
    [US-ASCII], [UTF-8], [UTF-16], [ISO-8859-1] *)
val parser_create : encoding:string option -> expat_parser

(** Create a new XML parser that has namespace processing in effect *)
val parser_create_ns : encoding:string option -> separator:char -> expat_parser

(** Create a new XML_Parser object for parsing an external general
    entity. Context is the context argument passed in a call to a
    external_entity_ref_handler. Other state information such as
    handlers, and namespace processing is inherited from the parser
    passed as the 1st argument. So you shouldn't need to call any of
    the behavior changing functions on this parser (unless you want
    it to act differently than the parent parser). *)
val external_entity_parser_create :
  expat_parser -> string option -> string option -> expat_parser


(** {5 Parsing} *)

(** Let the parser parse a chunk of an XML document.
    @raise Expat_error error *)
val parse : expat_parser -> string -> unit

(** Let the parser parse a chunk of an XML document.
    @raise Expat_error error *)
val parse_bytes : expat_parser -> bytes -> unit

(** Let the parser parse a chunk of an XML document in a substring
    @raise Expat_error error *)
val parse_sub : expat_parser -> string -> int -> int -> unit

(** Let the parser parse a chunk of an XML document in a substring
    @raise Expat_error error *)
val parse_sub_bytes : expat_parser -> bytes -> int -> int -> unit

(** Inform the parser that the entire document has been parsed.  *)
val final : expat_parser -> unit

(** {5 Handler Setting and Resetting}

 The strings that are passed to the handlers are always encoded in
 [UTF-8]. Your application is responsible for translation of these
 strings into other encodings.
 *)

(** {6 Start element setting and resetting} *)

val set_start_element_handler : expat_parser ->
  (string -> (string * string) list -> unit) -> unit
val reset_start_element_handler : expat_parser -> unit

(** {6 End element setting and resetting} *)

val set_end_element_handler : expat_parser -> (string -> unit) -> unit
val reset_end_element_handler : expat_parser -> unit

(** {6 Character data hander setting and resetting} *)

val set_character_data_handler : expat_parser -> (string -> unit) -> unit
val reset_character_data_handler : expat_parser -> unit

(** {6 Processing Instruction handler setting and resetting} *)

val set_processing_instruction_handler : expat_parser ->
  (string -> string -> unit) -> unit
val reset_processing_instruction_handler : expat_parser -> unit

(** {6 Comment handler setting and resetting} *)

val set_comment_handler : expat_parser -> (string -> unit) -> unit
val reset_comment_handler : expat_parser -> unit

(** {6 CData Section handler setting and resetting} *)

val set_start_cdata_handler : expat_parser -> (unit -> unit) -> unit
val reset_start_cdata_handler : expat_parser -> unit

val set_end_cdata_handler : expat_parser -> (unit -> unit) -> unit
val reset_end_cdata_handler : expat_parser -> unit

(** {6 Default Handler setting and resetting} *)

val set_default_handler : expat_parser -> (string -> unit) -> unit
val reset_default_handler : expat_parser -> unit

(** {6 External Entity Ref Handler setting and resetting} *)

val set_external_entity_ref_handler :
    expat_parser ->
      (string option -> string option -> string -> string option -> unit) ->
	unit
val reset_external_entity_ref_handler : expat_parser -> unit

(** {5 Parse Position Functions} *)

val get_current_byte_index : expat_parser -> int
val get_current_column_number : expat_parser -> int
val get_current_line_number : expat_parser -> int
val get_current_byte_count : expat_parser -> int

(** {5 Error Reporting} *)

type xml_error =
    NONE
  | NO_MEMORY
  | SYNTAX
  | NO_ELEMENTS
  | INVALID_TOKEN
  | UNCLOSED_TOKEN
  | PARTIAL_CHAR
  | TAG_MISMATCH
  | DUPLICATE_ATTRIBUTE
  | JUNK_AFTER_DOC_ELEMENT
  | PARAM_ENTITY_REF
  | UNDEFINED_ENTITY
  | RECURSIVE_ENTITY_REF
  | ASYNC_ENTITY
  | BAD_CHAR_REF
  | BINARY_ENTITY_REF
  | ATTRIBUTE_EXTERNAL_ENTITY_REF
  | MISPLACED_XML_PI
  | UNKNOWN_ENCODING
  | INCORRECT_ENCODING
  | UNCLOSED_CDATA_SECTION
  | EXTERNAL_ENTITY_HANDLING
  | NOT_STANDALONE
  | UNEXPECTED_STATE
  | ENTITY_DECLARED_IN_PE
  | FEATURE_REQUIRES_XML_DTD
  | CANT_CHANGE_FEATURE_ONCE_PARSING

(** Exception raised by parse function to report error conditions *)
exception Expat_error of xml_error

(** Converts a xml_error to a string *)
val xml_error_to_string : xml_error -> string

(** {5 Miscellaneous Functions} *)

(** Set the base to be used for resolving relative URIs in system
    identifiers. *)
val set_base : expat_parser -> string option -> unit

(** Get the base for resolving relative URIs. *)
val get_base : expat_parser -> string option

(** Parameter entity handling types *)
type xml_param_entity_parsing_choice =
    NEVER
  | UNLESS_STANDALONE
  | ALWAYS

(** Enable the parsing of parameter entities *)
val set_param_entity_parsing :
    expat_parser -> xml_param_entity_parsing_choice -> bool

(** Return the Expat library version as a string (e.g. "expat_1.95.1" *)
val expat_version : unit -> string


