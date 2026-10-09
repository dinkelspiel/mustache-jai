//
// This file was auto-generated using the following command:
//
// jai generate.jai
//
#import "POSIX";



MUSTACH_VERSION :: 102;
MUSTACH_VERSION_MAJOR :: MUSTACH_VERSION / 100;
MUSTACH_VERSION_MINOR :: MUSTACH_VERSION % 100;

MUSTACH_MAX_DEPTH :: 256;

MUSTACH_MAX_NESTING :: 64;

MUSTACH_MAX_LENGTH :: 4096;

MUSTACH_MAX_DELIM_LENGTH :: 8;

Mustach_With_NoExtensions :: 0;
Mustach_With_Colon :: 1;
Mustach_With_EmptyTag :: 2;
Mustach_With_AllExtensions :: 3;

MUSTACH_OK :: 0;
MUSTACH_ERROR :: enum {
    SYSTEM            :: -1;
    UNEXPECTED_END    :: -2;
    EMPTY_TAG         :: -3;
    TAG_TOO_LONG      :: -4;
    BAD_SEPARATORS    :: -5;
    TOO_DEEP          :: -6;
    CLOSING           :: -7;
    BAD_UNESCAPE_TAG  :: -8;
    INVALID_ITF       :: -9;
    ITEM_NOT_FOUND    :: -10;
    PARTIAL_NOT_FOUND :: -11;
    UNDEFINED_TAG     :: -12;
    TOO_MUCH_NESTING  :: -13;

    USER_BASE         :: -100;

    MUSTACH_ERROR_SYSTEM            :: SYSTEM;
    MUSTACH_ERROR_UNEXPECTED_END    :: UNEXPECTED_END;
    MUSTACH_ERROR_EMPTY_TAG         :: EMPTY_TAG;
    MUSTACH_ERROR_TAG_TOO_LONG      :: TAG_TOO_LONG;
    MUSTACH_ERROR_BAD_SEPARATORS    :: BAD_SEPARATORS;
    MUSTACH_ERROR_TOO_DEEP          :: TOO_DEEP;
    MUSTACH_ERROR_CLOSING           :: CLOSING;
    MUSTACH_ERROR_BAD_UNESCAPE_TAG  :: BAD_UNESCAPE_TAG;
    MUSTACH_ERROR_INVALID_ITF       :: INVALID_ITF;
    MUSTACH_ERROR_ITEM_NOT_FOUND    :: ITEM_NOT_FOUND;
    MUSTACH_ERROR_PARTIAL_NOT_FOUND :: PARTIAL_NOT_FOUND;
    MUSTACH_ERROR_UNDEFINED_TAG     :: UNDEFINED_TAG;
    MUSTACH_ERROR_TOO_MUCH_NESTING  :: TOO_MUCH_NESTING;

    MUSTACH_ERROR_USER_BASE         :: USER_BASE;
}

/**
* mustach_itf - pure abstract mustach - interface for callbacks
*
* The functions enter and next should return 0 or 1.
*
* All other functions should normally return MUSTACH_OK (zero).
*
* If any function returns a negative value, it means an error that
* stop the processing and that is reported to the caller. Mustach
* also has its own error codes. Using the macros MUSTACH_ERROR_USER
* and MUSTACH_IS_ERROR_USER could help to avoid clashes.
*
* @start: If defined (can be NULL), starts the mustach processing
*         of the closure, called at the very beginning before any
*         mustach processing occurs.
*
* @put: If defined (can be NULL), writes the value of 'name'
*       to 'file' with 'escape' or not.
*       As an extension (see NO_ALLOW_EMPTY_TAG), the 'name' can be
*       the empty string. In that later case an implementation can
*       return MUSTACH_ERROR_EMPTY_TAG to refuse empty names.
*       If NULL and 'get' NULL the error MUSTACH_ERROR_INVALID_ITF
*       is returned.
*
* @enter: Enters the section of 'name' if possible.
*         Musts return 1 if entered or 0 if not entered.
*         When 1 is returned, the function 'leave' will always be called.
*         Conversely 'leave' is never called when enter returns 0 or
*         a negative value.
*         When 1 is returned, the function must activate the first
*         item of the section.
*
* @next: Activates the next item of the section if it exists.
*        Musts return 1 when the next item is activated.
*        Musts return 0 when there is no item to activate.
*
* @leave: Leaves the last entered section
*
* @partial: If defined (can be NULL), returns in 'sbuf' the content of the
*           partial of 'name'. @see mustach_sbuf
*           If NULL but 'get' not NULL, 'get' is used instead of partial.
*           If NULL and 'get' NULL and 'put' not NULL, 'put' is called with
*           a true FILE.
*
* @emit: If defined (can be NULL), writes the 'buffer' of 'size' with 'escape'.
*        If NULL the standard function 'fwrite' is used with a true FILE.
*        If not NULL that function is called instead of 'fwrite' to output
*        text.
*        It implies that if you define either 'partial' or 'get' callback,
*        the meaning of 'FILE *file' is abstract for mustach's process and
*        then you can use 'FILE*file' pass any kind of pointer (including NULL)
*        to the function 'fmustach'. An example of a such behaviour is given by
*        the implementation of 'mustach_json_c_write'.
*
* @get: If defined (can be NULL), returns in 'sbuf' the value of 'name'.
*       As an extension (see NO_ALLOW_EMPTY_TAG), the 'name' can be
*       the empty string. In that later case an implementation can
*       return MUSTACH_ERROR_EMPTY_TAG to refuse empty names.
*       If 'get' is NULL and 'put' NULL the error MUSTACH_ERROR_INVALID_ITF
*       is returned.
*
* @stop: If defined (can be NULL), stops the mustach processing
*        of the closure, called at the very end after all mustach
*        processing occurered. The status returned by the processing
*        is passed to the stop.
*
* The array below summarize status of callbacks:
*
*    FULLY OPTIONAL:   start partial
*    MANDATORY:        enter next leave
*    COMBINATORIAL:    put emit get
*
* Not definig a MANDATORY callback returns error MUSTACH_ERROR_INVALID_ITF.
*
* For COMBINATORIAL callbacks the array below summarize possible combinations:
*
*  combination  : put     : emit    : get     : abstract FILE
*  -------------+---------+---------+---------+-----------------------
*  HISTORIC     : defined : NULL    : NULL    : NO: standard FILE
*  MINIMAL      : NULL    : NULL    : defined : NO: standard FILE
*  CUSTOM       : NULL    : defined : defined : YES: abstract FILE
*  DUCK         : defined : NULL    : defined : NO: standard FILE
*  DANGEROUS    : defined : defined : any     : YES or NO, depends on 'partial'
*  INVALID      : NULL    : any     : NULL    : -
*
* The DUCK case runs on one leg. 'get' is not used if 'partial' is defined
* but is used for 'partial' if 'partial' is NULL. Thus for clarity, do not use
* it that way but define 'partial' and let 'get' be NULL.
*
* The DANGEROUS case is special: it allows abstract FILE if 'partial' is defined
* but forbids abstract FILE when 'partial' is NULL.
*
* The INVALID case returns error MUSTACH_ERROR_INVALID_ITF.
*/
mustach_itf :: struct {
    start:   #type (closure: *void) -> s32 #c_call;
    put:     #type (closure: *void, name: *u8, escape: s32, file: *FILE) -> s32 #c_call;
    enter:   #type (closure: *void, name: *u8) -> s32 #c_call;
    next:    #type (closure: *void) -> s32 #c_call;
    leave:   #type (closure: *void) -> s32 #c_call;
    partial: #type (closure: *void, name: *u8, sbuf: *mustach_sbuf) -> s32 #c_call;
    emit:    #type (closure: *void, buffer: *u8, size: u64, escape: s32, file: *FILE) -> s32 #c_call;
    get:     #type (closure: *void, name: *u8, sbuf: *mustach_sbuf) -> s32 #c_call;
    stop:    #type (closure: *void, status: s32) -> void #c_call;
}

/**
* mustach_sbuf - Interface for handling zero terminated strings
*
* That structure is used for returning zero terminated strings -in 'value'-
* to mustach. The callee can provide a function for releasing the returned
* 'value'. Three methods for releasing the string are possible.
*
*  1. no release: set either 'freecb' or 'releasecb' with NULL (done by default)
*  2. release without closure: set 'freecb' to its expected value
*  3. release with closure: set 'releasecb' and 'closure' to their expected values
*
* @value: The value of the string. That value is not changed by mustach -const-.
*
* @freecb: The function to call for freeing the value without closure.
*          For convenience, signature of that callback is compatible with 'free'.
*          Can be NULL.
*
* @releasecb: The function to release with closure.
*             Can be NULL.
*
* @closure: The closure to use for 'releasecb'.
*
* @length: Length of the value or zero if unknown and value null terminated.
*          To return the empty string, let it to zero and let value to NULL.
*/
mustach_sbuf :: struct {
    value:   *u8;
    union {
        freecb:    #type (unknown0: *void) -> void #c_call;
        releasecb: #type (value: *u8, closure: *void) -> void #c_call;
    }

    closure: *void;
    length:  u64;
}

/**
* mustach_file - Renders the mustache 'template' in 'file' for 'itf' and 'closure'.
*
* @template: the template string to instantiate
* @length:   length of the template or zero if unknown and template null terminated
* @itf:      the interface to the functions that mustach calls
* @closure:  the closure to pass to functions called
* @file:     the file where to write the result
*
* Returns 0 in case of success, -1 with errno set in case of system error
* a other negative value in case of error.
*/
mustach_file :: (template: *u8, length: u64, itf: *mustach_itf, closure: *void, flags: s32, file: *FILE) -> s32 #foreign mustach;

/**
* mustach_fd - Renders the mustache 'template' in 'fd' for 'itf' and 'closure'.
*
* @template: the template string to instantiate
* @length:   length of the template or zero if unknown and template null terminated
* @itf:      the interface to the functions that mustach calls
* @closure:  the closure to pass to functions called
* @fd:       the file descriptor number where to write the result
*
* Returns 0 in case of success, -1 with errno set in case of system error
* a other negative value in case of error.
*/
mustach_fd :: (template: *u8, length: u64, itf: *mustach_itf, closure: *void, flags: s32, fd: s32) -> s32 #foreign mustach;

/**
* mustach_mem - Renders the mustache 'template' in 'result' for 'itf' and 'closure'.
*
* @template: the template string to instantiate
* @length:   length of the template or zero if unknown and template null terminated
* @itf:      the interface to the functions that mustach calls
* @closure:  the closure to pass to functions called
* @result:   the pointer receiving the result when 0 is returned
* @size:     the size of the returned result
*
* Returns 0 in case of success, -1 with errno set in case of system error
* a other negative value in case of error.
*/
mustach_mem :: (template: *u8, length: u64, itf: *mustach_itf, closure: *void, flags: s32, result: **u8, size: *u64) -> s32 #foreign mustach;

#scope_file

mustach :: #library,no_dll "../linux/mustach";
