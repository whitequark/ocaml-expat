/***********************************************************************/
/* The OcamlExpat library                                              */
/*                                                                     */
/* Copyright 2002, 2003 Maas-Maarten Zeeman. All rights reserved. See  */ 
/* LICENCE for details.                                                */
/***********************************************************************/

/* $Id: expat_stubs.c,v 1.20 2005/03/13 14:00:29 maas Exp $ */

/* Stub code to interface Ocaml with Expat */

#include <stdio.h>
#include <string.h>

#include <expat.h>

/* This is needed to support older versions of Expat 1.95.x */
#ifndef XML_STATUS_OK
#define XML_STATUS_OK    1
#define XML_STATUS_ERROR 0
#endif

#include <caml/mlvalues.h>
#include <caml/custom.h>
#include <caml/alloc.h>
#include <caml/memory.h>
#include <caml/callback.h>
#include <caml/fail.h>

#define XML_Parser_val(v) (*((XML_Parser *) Data_custom_val(v)))

/* 
 * Define the place where the handlers will be located inside the
 * handler tuple which is registered as global root. Handlers for
 * new functions should go here.
 */
enum expat_handler {
    EXPAT_START_ELEMENT_HANDLER,
    EXPAT_END_ELEMENT_HANDLER,
    EXPAT_CHARACTER_DATA_HANDLER,
    EXPAT_PROCESSING_INSTRUCTION_HANDLER,
    EXPAT_COMMENT_HANDLER,
    EXPAT_START_CDATA_HANDLER,
    EXPAT_END_CDATA_HANDLER,
    EXPAT_DEFAULT_HANDLER,
    EXPAT_EXTERNAL_ENTITY_REF_HANDLER,

    NUM_HANDLERS /* keep this at the end */
};

/* 
 * Return None if a null string is passed as a parameter, and Some str
 * if a string is used.  
 */
static value
Val_option_string(const char *str) 
{
    CAMLparam0();
    CAMLlocal2(some, some_str);

    if(str == NULL) {
	CAMLreturn (Val_int(0));
    } else {
	some = alloc(1, 0);
	some_str = copy_string(str);
	Store_field(some, 0, some_str);
	CAMLreturn (some);
    }
}

/*
 * Return NULL if we have None, Some str otherwise.
 */
static char *
String_option_val(value string_option) 
{
    if (Is_block(string_option)) 
	return String_val(Field(string_option, 0));
    return NULL;
}

static void 
xml_parser_finalize(value parser) 
{ 
    XML_Parser xml_parser = XML_Parser_val(parser);
    value *handlers = XML_GetUserData(xml_parser);

    /* The handlers are no longer needed */
    *handlers = Val_unit;
    remove_global_root(handlers);
    
    /* Free the memory occupied by the parser */
    XML_ParserFree(xml_parser);
    caml_stat_free(handlers);
}

static int 
xml_parser_compare(value v1, value v2) 
{ 
    XML_Parser p1 = XML_Parser_val(v1);
    XML_Parser p2 = XML_Parser_val(v2);
    if(p1 == p2) return 0;
    if(p1 < p2) return -1; 
    return 1;
}

static long 
xml_parser_hash(value v) 
{ 
    return (long) XML_Parser_val(v);
}

static struct custom_operations xml_parser_ops = {
    "Expat_XML_Parser",
    xml_parser_finalize,
    xml_parser_compare,
    xml_parser_hash,
    custom_serialize_default,
    custom_deserialize_default    
};

static value
create_ocaml_expat_parser(XML_Parser xml_parser)
{
    CAMLparam0();

    CAMLlocal1(parser);
    int i;
    value *handlers;

    /* 
     * I don't know how to find out how much memory the parser consumes,
     * so I've set some figures here, which seems to do well.  
     */
    parser = alloc_custom(&xml_parser_ops, sizeof(XML_Parser), 1, 5000);
    XML_Parser_val(parser) = xml_parser;
    
    /* 
     * Malloc a value for a tuple which will contain the callback
     * handlers and register it as global root.  
     */
    handlers = caml_stat_alloc(sizeof *handlers);
    *handlers = Val_unit; 
    register_global_root(handlers);

    /*
     * Create a tuple which will hold the handlers.
     */
    *handlers = alloc_tuple(NUM_HANDLERS);
    for(i = 0; i < NUM_HANDLERS; i++) {
	Field(*handlers, i) = Val_unit;
    }

    /* 
     * Associate it as user data with the parser. This is possible because 
     * a global root will not be relocated. 
     */
    XML_SetUserData(xml_parser, handlers);
    
    CAMLreturn (parser);
}

/* 
 * parser_create : encoding:string option -> expat_parser = 
 *   "expat_XML_ParserCreate" 
 */
CAMLprim value 
expat_XML_ParserCreate(value encoding)
{
    
    return create_ocaml_expat_parser(XML_ParserCreate(String_option_val(encoding)));
}

/*
 * parser_create_ns : encoding:string option -> separator:char -> expat_parser = 
 *   "expat_XML_ParserCreateNS"
 */
CAMLprim value
expat_XML_ParserCreateNS(value encoding, value sep)
{ 
    return create_ocaml_expat_parser(XML_ParserCreateNS(String_option_val(encoding),
							(char) Long_val(sep)));
}

/*
 * external_entity_parser_create : expat_parser -> context:string option 
 *               -> encoding:string option -> expat_parser = 
 *   "expat_XML_ExternalEntityParserCreate"
 */
CAMLprim value
expat_XML_ExternalEntityParserCreate(value p, value context, value encoding) {
    CAMLparam3(p, context, encoding);
    CAMLlocal1(parser);
    int i;
    value *handlers, *parent_handlers;

    XML_Parser xml_parser = \
	XML_ExternalEntityParserCreate(XML_Parser_val(p), 
				       String_option_val(context), 
				       String_option_val(encoding));
    parser = alloc_custom(&xml_parser_ops, sizeof(XML_Parser), 1, 5000);
    XML_Parser_val(parser) = xml_parser;
    
    /* 
     * Malloc a value for a tuple which will contain the callback
     * handlers and register it as global root.  
     */
    handlers = caml_stat_alloc(sizeof *handlers);
    *handlers = Val_unit; 
    register_global_root(handlers);

    /*
     * Create a tuple which will hold the handlers, and inherit the
     * handlers installed in the parent parser.
     */
    parent_handlers = XML_GetUserData(xml_parser);
    *handlers = alloc_tuple(NUM_HANDLERS);
    for(i = 0; i < NUM_HANDLERS; i++) {
	Field(*handlers, i) = Field(*parent_handlers, i);
    }

    /* 
     * Associate inherited handlers it as user data with the
     * parser. This is possible because a global root will not be
     * relocated.
     */
    XML_SetUserData(xml_parser, handlers);
    
    CAMLreturn (parser);
}


/*
 * get_base : expat_parser -> string option
 */
CAMLprim value
expat_XML_GetBase(value parser) 
{
    CAMLparam1(parser);
    CAMLlocal1(option);
    const char *base = NULL;

    base = XML_GetBase(XML_Parser_val(parser));
    option = Val_option_string(base);
    
    CAMLreturn (option);    
}

/*
 * val set_base : expat_parser -> string option -> unit
 */
CAMLprim value
expat_XML_SetBase(value parser, value string) 
{
    CAMLparam2(parser, string);
    
    XML_SetBase(XML_Parser_val(parser), String_option_val(string));
    
    CAMLreturn (Val_unit);
}

/* 
 * external get_current_byte_index : expat_parser -> int = 
 *   "expat_XML_GetCurrentByteIndex"
 */
CAMLprim value
expat_XML_GetCurrentByteIndex(value parser)
{
    return Val_long(XML_GetCurrentByteIndex(XML_Parser_val(parser))); 
}

/* 
 * external get_current_byte_count : expat_parser -> int = 
 *   "expat_XML_GetCurrentByteCount"
 */
CAMLprim value
expat_XML_GetCurrentByteCount(value parser)
{
    return Val_long(XML_GetCurrentByteCount(XML_Parser_val(parser))); 
}

/* 
 * external get_current_column_number : expat_parser -> int = 
 *   "expat_XML_GetCurrentColumnNumber"
 */
CAMLprim value
expat_XML_GetCurrentColumnNumber(value parser)
{
    return Val_long(XML_GetCurrentColumnNumber(XML_Parser_val(parser)));
}

/*
 * external get_current_line_number : expat_parser -> int = 
 *   "expat_XML_GetCurrentLineNumber"
 */
CAMLprim value
expat_XML_GetCurrentLineNumber(value parser)
{
    return Val_long(XML_GetCurrentLineNumber(XML_Parser_val(parser)));
}

/*
 * external expat_version : unit -> string = "expat_XML_ExpatVersion"
 */
CAMLprim value
expat_XML_ExpatVersion(value unit)
{
    return copy_string(XML_ExpatVersion());
}

/* 
 * external set_param_entity_parsing : expat_parser -> 
 *   xml_param_entity_parsing_choice -> bool =
 *     "expat_XML_SetParamEntityParsing"
 */
CAMLprim value
expat_XML_SetParamEntityParsing(value parser, value choice) {
    CAMLparam2(parser, choice);
    CAMLreturn (Val_bool(XML_SetParamEntityParsing(XML_Parser_val(parser), 
						   Int_val(choice))));
}

/*
 * external xml_error_to_string : xml_error -> string = "expat_XML_ErrorString"
 */
CAMLprim value
expat_XML_ErrorString(value error_code)
{
    CAMLparam1(error_code);
    const char *error_string = XML_ErrorString(Int_val(error_code));

    /* XML_ErrorString(XML_ERROR_NONE) returns NULL, this check
     * will return an empty string whenever this happens. Note:
     * it checks for NULL, because that is the safest way.
     */
    if (error_string == NULL) 
	CAMLreturn (alloc_string(0));
    CAMLreturn (copy_string(error_string));
}

/* 
 * Raise an expat_error exception
 */
static void
expat_error(int error_code)
{
    static value * expat_error_exn = NULL;
    
    if(expat_error_exn == NULL) {
	expat_error_exn = caml_named_value("expat_error");
	if(expat_error_exn == NULL) {
	    invalid_argument("Exception Expat_error not initialized");
	}
    }

    raise_with_arg(*expat_error_exn, Val_long(error_code));
}

/*
 * external parse : expat_parser -> string -> unit =  "expat_XML_Parse"
 */
CAMLprim value
expat_XML_Parse(value parser, value string)
{
    CAMLparam2(parser, string);
    XML_Parser xml_parser =  XML_Parser_val(parser);

    if(!XML_Parse(xml_parser, String_val(string), string_length(string), 0)) {
	expat_error(XML_GetErrorCode(xml_parser));
    }
  
    CAMLreturn (Val_unit);
}

/*
 * external parse_sub : expat_parser -> string -> int -> int -> unit = 
 *   "expat_XML_ParseSub"
 */
CAMLprim value
expat_XML_ParseSub(value vparser, value vstring, value voffset, value vlen)
{
    CAMLparam2(vparser, vstring);
    XML_Parser parser =  XML_Parser_val(vparser);
    int len = Int_val(vlen);
    int offset = Int_val(voffset);
    int string_len = string_length(vstring);
    char *string = String_val(vstring);

    /* sanity check on the parameters */
    if((offset < 0) || (len < 0) || (offset > (string_len - len))) {
	invalid_argument("Expat.parse_sub");
    }

    if(!XML_Parse(parser, string + offset, len, 0)) {
	expat_error(XML_GetErrorCode(parser));
    }
  
    CAMLreturn (Val_unit);
}

/*
 * external final : expat_parser -> unit = "expat_XML_Final"
 */
CAMLprim value
expat_XML_Final(value parser)
{
    CAMLparam1(parser); 
    XML_Parser xml_parser =  XML_Parser_val(parser);

    if(!XML_Parse(xml_parser, NULL, 0, 1)) {
	expat_error(XML_GetErrorCode(xml_parser));
    }
  
    CAMLreturn (Val_unit);
}

/*
 * Start element handling, setting and resetting.
 */
static void 
start_element_handler(void *user_data, const char *name, const char **attr)
{
    CAMLparam0();
    CAMLlocal5(list, cons, prev, att, tag);
    value *handlers = user_data;
    int i;

    list = Val_unit;
    prev = Val_unit;

    /* Create an assoc list with the attributes */
    for(i = 0; attr[i]; i += 2) {
	/* Create a tuple */
	att = alloc_tuple(2);
	Store_field(att, 0, copy_string(attr[i]));
	Store_field(att, 1, copy_string(attr[i + 1]));
    
	/* Create a cons */
	cons = alloc_tuple(2);
	Store_field(cons, 0, att);
	Store_field(cons, 1, Val_unit);
	if(prev != Val_unit) {
	    Store_field(prev, 1, cons);      
	} 
	prev = cons;
	if(list == Val_unit) {
	    list = cons;
	}
    }
    tag = copy_string(name);
    callback2(Field(*handlers, EXPAT_START_ELEMENT_HANDLER), tag, list);
  
    CAMLreturn0;
}

static value set_start_handler(value parser,
			       XML_StartElementHandler c_handler,
			       value ocaml_handler)
{
    CAMLparam2(parser, ocaml_handler);
    XML_Parser xml_parser = XML_Parser_val(parser);
    value *handlers = XML_GetUserData(xml_parser);

    Store_field(*handlers, EXPAT_START_ELEMENT_HANDLER, ocaml_handler);
    XML_SetStartElementHandler(xml_parser, c_handler); 

    CAMLreturn (Val_unit);
}

/* 
 * external set_start_element_handler : expat_parser -> 
 *  (string -> (string * string) list -> unit) -> unit = 
 *   "expat_XML_SetStartElementHandler"
 */
CAMLprim value
expat_XML_SetStartElementHandler(value parser, value handler)
{
    CAMLparam2(parser, handler);
    CAMLreturn (set_start_handler(parser, start_element_handler, handler));
}

/* 
 * external reset_start_element_handler : expat_parser -> unit = 
 *   "expat_XML_ResetStartElementHandler"
 */
CAMLprim value
expat_XML_ResetStartElementHandler(value parser)
{
    CAMLparam1(parser);
    CAMLreturn (set_start_handler(parser, NULL, Val_unit));
}

static void
end_element_handler(void *user_data, const char *name)
{
    value tag;
    value *handlers = user_data;
    
    tag = copy_string(name);
    callback(Field(*handlers, EXPAT_END_ELEMENT_HANDLER), tag);
}

static value 
set_end_handler(value parser, XML_EndElementHandler c_handler, 
		value ocaml_handler)
{
    CAMLparam2(parser, ocaml_handler);
    XML_Parser xml_parser = XML_Parser_val(parser);
    value *handlers = XML_GetUserData(xml_parser);

    Store_field(*handlers, EXPAT_END_ELEMENT_HANDLER, ocaml_handler);
    XML_SetEndElementHandler(xml_parser, c_handler); 

    CAMLreturn (Val_unit);
}

/* 
 * external set_end_element_handler : expat_parser -> (string -> unit) -> unit = 
 *   "expat_XML_SetEndElementHandler"
 */
CAMLprim value
expat_XML_SetEndElementHandler(value parser, value handler)
{
    CAMLparam2(parser, handler);
    CAMLreturn (set_end_handler(parser, end_element_handler, handler));
}

/* 
 * external reset_end_element_handler : expat_parser -> unit = 
 *   "expat_XML_ResetEndElementHandler"
 */
CAMLprim value
expat_XML_ResetEndElementHandler(value parser)
{
    CAMLparam1(parser);
    CAMLreturn (set_end_handler(parser, NULL, Val_unit));
}

/*
 * Character data handling, setting, and resetting
 */
static void
character_data_handler(void *user_data, const char *data, int len)
{
    CAMLparam0();
    CAMLlocal1(str);
    value *handlers = user_data;

    str = alloc_string(len);
    memcpy(String_val(str), data, len);
    callback(Field(*handlers, EXPAT_CHARACTER_DATA_HANDLER), str);

    CAMLreturn0;
}

static value set_character_data_handler(value parser,
					XML_CharacterDataHandler c_handler,
					value ocaml_handler)
{
    CAMLparam2(parser, ocaml_handler);
    XML_Parser xml_parser = XML_Parser_val(parser);
    value *handlers = XML_GetUserData(xml_parser);

    Store_field(*handlers, EXPAT_CHARACTER_DATA_HANDLER, ocaml_handler);
    XML_SetCharacterDataHandler(xml_parser, c_handler);

    CAMLreturn (Val_unit);
}


/*
 * external set_character_data_handler : expat_parser -> (string -> unit) -> unit = 
 *   "expat_XML_SetCharacterDataHandler"
 */
CAMLprim value
expat_XML_SetCharacterDataHandler(value parser, value handler)
{
    CAMLparam2(parser, handler);
    CAMLreturn (set_character_data_handler(parser, character_data_handler, 
					   handler));
}

/* 
 * external reset_end_element_handler : expat_parser -> unit = 
 *   "expat_XML_ResetEndElementHandler"
 */
CAMLprim value
expat_XML_ResetCharacterDataHandler(value parser)
{
    CAMLparam1(parser);
    CAMLreturn (set_character_data_handler(parser, NULL, Val_unit));
}

/*
 * Process instruction, setting and resetting
 */
static void
processing_instruction_handler(void *user_data,  const char *target,  
			       const char *data)
{
    CAMLparam0();
    CAMLlocal2(t, d);
    value *handlers = user_data;

    t = copy_string(target);
    d = copy_string(data);
    callback2(Field(*handlers, EXPAT_PROCESSING_INSTRUCTION_HANDLER), t, d);

    CAMLreturn0;
}

static value 
set_processing_instruction_handler(value parser,
				   XML_ProcessingInstructionHandler c_handler,
				   value ocaml_handler)
{
    CAMLparam2(parser, ocaml_handler);
    XML_Parser xml_parser = XML_Parser_val(parser);
    value *handlers = XML_GetUserData(xml_parser);

    Store_field(*handlers, 
		EXPAT_PROCESSING_INSTRUCTION_HANDLER, ocaml_handler);
    XML_SetProcessingInstructionHandler(xml_parser, c_handler);

    CAMLreturn (Val_unit);
}

/* 
 * external set_processing_instruction_handler : expat_parser -> 
 *   (string -> string -> unit) -> unit =
 *      "expat_XML_SetProcessingInstructionHandler"
 */
CAMLprim value
expat_XML_SetProcessingInstructionHandler(value parser, value handler)
{
    CAMLparam2(parser, handler);
    CAMLreturn (set_processing_instruction_handler(parser, 
						   processing_instruction_handler, 
						   handler));
}

/*
 * external reset_processing_instruction_handler : expat_parser -> unit =
 *   "expat_XML_ResetProcessingInstructionHandler"
 */
CAMLprim value
expat_XML_ResetProcessingInstructionHandler(value parser)
{
    CAMLparam1(parser);
    CAMLreturn (set_processing_instruction_handler(parser, NULL, Val_unit));
}

/*
 * Comment handler, setting and resetting
 */
static void
comment_handler(void *user_data, const char *data)
{
    CAMLparam0();
    CAMLlocal1(d);

    value *handlers = user_data;
    d = copy_string(data);
    callback(Field(*handlers, EXPAT_COMMENT_HANDLER), d);

    CAMLreturn0;
}

static value 
set_comment_handler(value parser, 
		    XML_CommentHandler c_handler, value ocaml_handler)
{
    CAMLparam2(parser, ocaml_handler);
    XML_Parser xml_parser = XML_Parser_val(parser);
    value *handlers = XML_GetUserData(xml_parser);
  
    Store_field(*handlers, EXPAT_COMMENT_HANDLER, ocaml_handler);
    XML_SetCommentHandler(xml_parser, c_handler);

    CAMLreturn (Val_unit);
}

/* 
 * external set_comment_handler : expat_parser -> (string -> unit) -> unit =
 *   "expat_XML_SetCommentHandler"
 */
CAMLprim value
expat_XML_SetCommentHandler(value parser, value handler)
{
    CAMLparam2(parser, handler);
    CAMLreturn (set_comment_handler(parser, comment_handler, handler));
}

/* 
 * external reset_comment_handler : expat_parser -> unit =
 *   "expat_XML_ResetCommentHandler"
 */
CAMLprim value
expat_XML_ResetCommentHandler(value parser)
{
    CAMLparam1(parser);
    CAMLreturn (set_comment_handler(parser, NULL, Val_unit));
}

/*
 * Start CData handler, setting and resetting
 */
static void
start_cdata_handler(void *user_data) 
{
    CAMLparam0();
    value *handlers = user_data;
  
    callback(Field(*handlers, EXPAT_START_CDATA_HANDLER), Val_unit);

    CAMLreturn0;
}

static value
set_start_cdata_handler(value parser,
			XML_StartCdataSectionHandler c_handler, 
			value ocaml_handler)
{
    CAMLparam2(parser, ocaml_handler);
    XML_Parser xml_parser = XML_Parser_val(parser);
    value *handlers = XML_GetUserData(xml_parser);
  
    Store_field(*handlers, EXPAT_START_CDATA_HANDLER, ocaml_handler);
    XML_SetStartCdataSectionHandler(xml_parser, c_handler);
  
    CAMLreturn (Val_unit);
}

/*
 * external set_start_cdata_handler : expat_parser -> (unit -> unit) -> unit =
 *   "expat_XML_SetStartCDataHandler"
 */
CAMLprim value
expat_XML_SetStartCDataHandler(value parser, value handler)
{
    CAMLparam2(parser, handler);
    CAMLreturn (set_start_cdata_handler(parser, start_cdata_handler, handler));
}

/*
 * external reset_start_cdata_handler : expat_parser -> unit =
 *   "expat_XML_ResetStartCDataHandler"
 */
CAMLprim value
expat_XML_ResetStartCDataHandler(value parser)
{
    CAMLparam1(parser);
    CAMLreturn (set_start_cdata_handler(parser, NULL, Val_unit));
}

/*
 * End CData handler, setting and resetting
 */
static void
end_cdata_handler(void *user_data) 
{
    CAMLparam0();
    value *handlers = user_data;

    callback(Field(*handlers, EXPAT_END_CDATA_HANDLER), Val_unit);

    CAMLreturn0;
}

static value
set_end_cdata_handler(value parser,
		      XML_EndCdataSectionHandler c_handler, 
		      value ocaml_handler)
{
    CAMLparam2(parser, ocaml_handler);
    XML_Parser xml_parser = XML_Parser_val(parser);
    value *handlers = XML_GetUserData(xml_parser);

    Store_field(*handlers, EXPAT_END_CDATA_HANDLER, ocaml_handler);
    XML_SetEndCdataSectionHandler(xml_parser, c_handler);
  
    CAMLreturn (Val_unit);
}

/*
 * external set_end_cdata_handler : expat_parser -> (unit -> unit) -> unit =
 *   "expat_XML_SetEndCDataHandler"
 */
CAMLprim value
expat_XML_SetEndCDataHandler(value parser, value handler)
{
    CAMLparam2(parser, handler);
    CAMLreturn (set_end_cdata_handler(parser, end_cdata_handler, handler));
}

/*
 * external reset_end_cdata_handler : expat_parser -> unit =
 *   "expat_XML_ResetEndCDataHandler"
 */
CAMLprim value
expat_XML_ResetEndCDataHandler(value parser)
{
    CAMLparam1(parser);
    CAMLreturn (set_end_cdata_handler(parser, NULL, Val_unit));
}


/*
 * Default handler, setting and resetting
 */
static void
default_handler(void *user_data, const char *data, int len) 
{
    CAMLparam0();
    CAMLlocal1(d);
    value *handlers = user_data;

    d = alloc_string(len);
    memmove(String_val(d), data, len);
    callback(Field(*handlers, EXPAT_DEFAULT_HANDLER), d);

    CAMLreturn0;
}

static value
set_default_handler(value parser,
		    XML_DefaultHandler c_handler, 
		    value ocaml_handler)
{
    CAMLparam2(parser, ocaml_handler);
    XML_Parser xml_parser = XML_Parser_val(parser);
    value *handlers = XML_GetUserData(xml_parser);

    Store_field(*handlers, EXPAT_DEFAULT_HANDLER, ocaml_handler);
    XML_SetDefaultHandler(xml_parser, c_handler);
  
    CAMLreturn (Val_unit);
}

/* 
 * external set_default_handler : expat_parser -> (string -> unit) -> unit =
 *   "expat_XML_SetDefaultHandler"
 */
CAMLprim value
expat_XML_SetDefaultHandler(value parser, value handler)
{
    CAMLparam2(parser, handler);
    CAMLreturn (set_default_handler(parser, default_handler, handler));
}

/*
 * external reset_default_handler : expat_parser -> unit =
 *   "expat_XML_ResetDefaultHandler"
 */
CAMLprim value
expat_XML_ResetDefaultHandler(value parser)
{
    CAMLparam1(parser);
    CAMLreturn (set_default_handler(parser, NULL, Val_unit));
}



/*
 * External Entity Ref handler, setting and resetting
 */
static int
external_entity_ref_handler(XML_Parser xml_parser, 
			    const char *context, const char *base,
			    const char *systemId, const char *publicId) 
{
    CAMLparam0();
    CAMLlocal4(caml_context, caml_base, caml_systemId, caml_publicId);
    value *handlers = XML_GetUserData(xml_parser);
    value arg[4];

    /* 
     * Now put the strings into ocaml values. The parameters context,
     * base, and publicId are optional systemId is never optional.  
     */
    caml_context = Val_option_string(context);
    caml_base = Val_option_string(base);
    caml_systemId = copy_string(systemId); 
    caml_publicId = Val_option_string(publicId);

    /* Call the callback which has more than 3 parameters */
    arg[0] = caml_context;
    arg[1] = caml_base;
    arg[2] = caml_systemId;
    arg[3] = caml_publicId;  
    callbackN(Field(*handlers, EXPAT_EXTERNAL_ENTITY_REF_HANDLER), 4, arg);

    CAMLreturn (XML_STATUS_OK);
}

static value
set_external_entity_ref_handler(value parser,
				XML_ExternalEntityRefHandler c_handler, 
				value ocaml_handler)
{
    CAMLparam2(parser, ocaml_handler);
    XML_Parser xml_parser = XML_Parser_val(parser);
    value *handlers = XML_GetUserData(xml_parser);

    Store_field(*handlers, EXPAT_EXTERNAL_ENTITY_REF_HANDLER, ocaml_handler);
    XML_SetExternalEntityRefHandler(xml_parser, c_handler);
  
    CAMLreturn (Val_unit);
}

/*
 * external set_external_entity_ref_handler : expat_parser -> 
 *   (string option -> string option -> string -> string option -> unit) -> 
 *     unit = "expat_XML_SetExternalEntityRefHandler"
 */
CAMLprim value
expat_XML_SetExternalEntityRefHandler(value parser, value handler)
{
    CAMLparam2(parser, handler);
    CAMLreturn (set_external_entity_ref_handler(parser, 
						external_entity_ref_handler, 
						handler));
}

/*
 * external reset_external_entity_ref_handler : expat_parser -> unit =
 *   "expat_XML_ResetDefaultHandler"
 */
CAMLprim value
expat_XML_ResetExternalEntityRefHandler(value parser)
{
    CAMLparam1(parser);
    CAMLreturn (set_external_entity_ref_handler(parser, NULL, Val_unit));
}




