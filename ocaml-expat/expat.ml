(***********************************************************************)
(* The OcamlExpat library                                              *)
(*                                                                     *)
(* Copyright 2002, 2003, 2004, 2005 Maas-Maarten Zeeman. All rights    *)
(* reserved. See  LICENCE for details.                                 *)
(***********************************************************************)

type expat_parser

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

exception Expat_error of xml_error

external xml_error_to_string : xml_error -> string = "expat_XML_ErrorString"

(* exception is currently too minimalistic (needs line-no, etc), but it's *)
(* a start *)
let _ = Callback.register_exception "expat_error" (Expat_error NONE) 

(* param entity handling *)
type xml_param_entity_parsing_choice =
    NEVER
  | UNLESS_STANDALONE
  | ALWAYS

external set_param_entity_parsing : expat_parser -> 
  xml_param_entity_parsing_choice -> bool =
    "expat_XML_SetParamEntityParsing"

(* return the version number of the expat library *)
external expat_version : unit -> string = "expat_XML_ExpatVersion"

(* calls to create a parser *)
external parser_create : encoding:string option -> expat_parser = 
    "expat_XML_ParserCreate"
external parser_create_ns : encoding:string option -> separator:char 
  -> expat_parser = "expat_XML_ParserCreateNS"
external external_entity_parser_create : expat_parser -> string option 
  -> string option -> expat_parser = "expat_XML_ExternalEntityParserCreate"

(* calls needed to parse *)
external parse : expat_parser -> string -> unit =  "expat_XML_Parse"
external parse_sub : expat_parser -> string -> int -> int -> unit = 
    "expat_XML_ParseSub"
external final : expat_parser -> unit = "expat_XML_Final"

(* start element handler calls *)
external set_start_element_handler : expat_parser -> 
  (string -> (string * string) list -> unit) -> unit = 
    "expat_XML_SetStartElementHandler"
external reset_start_element_handler : expat_parser -> unit = 
    "expat_XML_ResetStartElementHandler"

(* end element handler calls *)
external set_end_element_handler : expat_parser -> (string -> unit) -> unit = 
    "expat_XML_SetEndElementHandler"
external reset_end_element_handler : expat_parser -> unit = 
    "expat_XML_ResetEndElementHandler"

(* character data handler calls *)
external set_character_data_handler : expat_parser -> (string -> unit) -> unit = 
    "expat_XML_SetCharacterDataHandler"
external reset_character_data_handler : expat_parser -> unit = 
    "expat_XML_ResetCharacterDataHandler"

(* processing instruction handler calls *)
external set_processing_instruction_handler : expat_parser -> 
  (string -> string -> unit) -> unit =
    "expat_XML_SetProcessingInstructionHandler"
external reset_processing_instruction_handler : expat_parser -> unit =
    "expat_XML_ResetProcessingInstructionHandler"

(* comment handler *)
external set_comment_handler : expat_parser -> (string -> unit) -> unit =
    "expat_XML_SetCommentHandler"
external reset_comment_handler : expat_parser -> unit =
    "expat_XML_ResetCommentHandler"

(* start cdata handler *)
external set_start_cdata_handler : expat_parser -> (unit -> unit) -> unit =
    "expat_XML_SetStartCDataHandler"
external reset_start_cdata_handler : expat_parser -> unit =
    "expat_XML_ResetStartCDataHandler"
    
(* end cdata handler *)
external set_end_cdata_handler : expat_parser -> (unit -> unit) -> unit =
  "expat_XML_SetEndCDataHandler"
external reset_end_cdata_handler : expat_parser -> unit =
  "expat_XML_ResetEndCDataHandler"

(* default handler *)
external set_default_handler : expat_parser -> (string -> unit) -> unit =
    "expat_XML_SetDefaultHandler"
external reset_default_handler : expat_parser -> unit =
    "expat_XML_ResetDefaultHandler"

(* external entity ref handler *)
external set_external_entity_ref_handler : expat_parser -> 
  (string option -> string option -> string -> string option -> unit) -> 
  unit = "expat_XML_SetExternalEntityRefHandler"
external reset_external_entity_ref_handler : expat_parser -> unit =
    "expat_XML_ResetDefaultHandler"

(* some general parser query calls *)
external get_current_byte_index : expat_parser -> int = 
    "expat_XML_GetCurrentByteIndex"
external get_current_column_number : expat_parser -> int = 
    "expat_XML_GetCurrentColumnNumber"
external get_current_line_number : expat_parser -> int = 
    "expat_XML_GetCurrentLineNumber"
external get_current_byte_count : expat_parser -> int = 
    "expat_XML_GetCurrentByteCount"

(* set/get base *)
external get_base : expat_parser -> string option =
    "expat_XML_GetBase"
external set_base : expat_parser -> string option -> unit =
    "expat_XML_SetBase"


