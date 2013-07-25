#ifndef __STUB_H
#define __STUB_H

/******************************************************************************/
/*****                           DEBUG FUNCTION                           *****/
/******************************************************************************/
/* Uncomment the following line to enable debug                               */
/* #define ENABLE_DEBUG */

#if defined(ENABLE_DEBUG)
void debug(int level, char *format, ...);
#else
#define debug(level, format, args...) ((void)0)
#endif


/******************************************************************************/
/*****                           UTILITY MACROS                           *****/
/******************************************************************************/
/* Library unique ID */
#define UUID              "551087dd-4133-4097-87c6-79c27cde5c15"
#define DEFAULT_OPS_UUID  (UUID "_DEFAULT")
#define THREADS_OPS_UUID  (UUID "_THREADS")

/* Access the lua_State inside an OCaml custom block */
#define lua_State_val(L) (*((lua_State **) Data_custom_val(L))) /* also l-value */

/* This macro is taken from the Lua source code, file ltablib.c line 19 */
#define aux_getn(L,n)	(luaL_checktype(L, n, LUA_TTABLE), luaL_getn(L, n))


/******************************************************************************/
/*****                          DATA STRUCTURES                           *****/
/******************************************************************************/
typedef struct allocator_data
{
    int max_memory;
    int used_memory;
} allocator_data;

typedef struct ocaml_data
{
    value state_value;
    value panic_callback;
    allocator_data ad;
} ocaml_data;


/******************************************************************************/
/*****                    COMMON FUNCTIONS DECLARATION                    *****/
/******************************************************************************/
void push_lud_array(lua_State *L);
ocaml_data * get_ocaml_data(lua_State *L);


/******************************************************************************/
/*****                    MACROS FOR BOILERPLATE CODE                     *****/
/******************************************************************************/
/* For Lua function with signature : lua_State -> void */
#define STUB_STATE_VOID(lua_function) \
CAMLprim \
value lua_function##__stub(value L) \
{ \
    CAMLparam1(L); \
    lua_function(lua_State_val(L)); \
    CAMLreturn(Val_unit); \
}

/* For Lua function with signature : lua_State -> int */
#define STUB_STATE_INT(lua_function) \
CAMLprim \
value lua_function##__stub(value L) \
{ \
    CAMLparam1(L); \
    debug(3, #lua_function "__stub(%p)\n", (void*)(lua_State_val(L))); \
    int retval = lua_function(lua_State_val(L)); \
    debug(4, #lua_function ": RETURN %d\n", retval); \
    CAMLreturn(Val_int(retval)); \
}

/* For Lua function with signature : lua_State -> int -> int -> int */
#define STUB_STATE_INT_INT_INT(lua_function, int1_name, int2_name) \
CAMLprim \
value lua_function##__stub(value L, value int1_name, value int2_name) \
{ \
    CAMLparam3(L, int1_name, int2_name); \
    int retval = lua_function(lua_State_val(L), Int_val(int1_name), Int_val(int2_name)); \
    CAMLreturn(Val_int(retval)); \
}

/* For Lua function with signature : lua_State -> int -> int */
#define STUB_STATE_INT_INT(lua_function, int_name) \
CAMLprim \
value lua_function##__stub(value L, value int_name) \
{ \
    CAMLparam2(L, int_name); \
    int retval = lua_function(lua_State_val(L), Int_val(int_name)); \
    CAMLreturn(Val_int(retval)); \
}

/* For Lua function with signature : lua_State -> int -> void */
#define STUB_STATE_INT_VOID(lua_function, int_name) \
CAMLprim \
value lua_function##__stub(value L, value int_name) \
{ \
    CAMLparam2(L, int_name); \
    debug(3, #lua_function "__stub(%p, %d)\n", (void*)(lua_State_val(L)), Int_val(int_name)); \
    lua_function(lua_State_val(L), Int_val(int_name)); \
    debug(4, #lua_function "__stub" ": RETURNS\n"); \
    CAMLreturn(Val_unit); \
}

/* For Lua function with signature : lua_State -> double -> void */
#define STUB_STATE_DOUBLE_VOID(lua_function, double_name) \
CAMLprim \
value lua_function##__stub(value L, value double_name) \
{ \
    CAMLparam2(L, double_name); \
    lua_function(lua_State_val(L), Double_val(double_name)); \
    CAMLreturn(Val_unit); \
}

/* For Lua function with signature : lua_State -> int -> double */
#define STUB_STATE_INT_DOUBLE(lua_function, int_name) \
CAMLprim \
value lua_function##__stub(value L, value int_name) \
{ \
    CAMLparam2(L, int_name); \
    double retval = lua_function(lua_State_val(L), Int_val(int_name)); \
    CAMLreturn(caml_copy_double(retval)); \
}

/* For Lua function with signature : lua_State -> bool -> void */
#define STUB_STATE_BOOL_VOID(lua_function, bool_name) \
CAMLprim \
value lua_function##__stub(value L, value bool_name) \
{ \
    CAMLparam2(L, bool_name); \
    lua_function(lua_State_val(L), Bool_val(bool_name)); \
    CAMLreturn(Val_unit); \
}

/* For Lua function with signature : lua_State -> int -> int -> void */
#define STUB_STATE_INT_INT_VOID(lua_function, int1_name, int2_name) \
CAMLprim \
value lua_function##__stub(value L, value int1_name, value int2_name) \
{ \
  CAMLparam3(L, int1_name, int2_name); \
  lua_function(lua_State_val(L), Int_val(int1_name), Int_val(int2_name)); \
  CAMLreturn(Val_unit); \
}

/* For Lua function with signature : lua_State -> bool */
#define STUB_STATE_BOOL(lua_function) \
CAMLprim \
value lua_function##__stub(value L) \
{ \
  CAMLparam1(L); \
  int retval = lua_function(lua_State_val(L)); \
  if (retval == 0) \
    CAMLreturn(Val_false); \
  else \
    CAMLreturn(Val_true); \
}

/* For Lua function with signature : lua_State -> int -> bool */
#define STUB_STATE_INT_BOOL(lua_function, int_name) \
CAMLprim \
value lua_function##__stub(value L, value int_name) \
{ \
  CAMLparam2(L, int_name); \
  debug(3, #lua_function "__stub(%p, %d)\n", (void*)(lua_State_val(L)), Int_val(int_name)); \
  int retval = lua_function(lua_State_val(L), Int_val(int_name)); \
  if (retval == 0) \
  { \
    debug(4, #lua_function ": RETURN FALSE\n"); \
    CAMLreturn(Val_false); \
  } \
  else \
  { \
    debug(4, #lua_function ": RETURN TRUE\n"); \
    CAMLreturn(Val_true); \
  } \
}

/* For Lua function with signature : lua_State -> int -> int -> bool */
#define STUB_STATE_INT_INT_BOOL(lua_function, int1_name, int2_name) \
CAMLprim \
value lua_function##__stub(value L, value int1_name, value int2_name) \
{ \
  CAMLparam3(L, int1_name, int2_name); \
  int retval = lua_function(lua_State_val(L), Int_val(int1_name), Int_val(int2_name)); \
  if (retval == 0) \
    CAMLreturn(Val_false); \
  else \
    CAMLreturn(Val_true); \
}

#endif  /* __STUB_H */

