require 'parse_tree'

module Red
  require 'compile'
  
  class Preprocessor
    begin # hide constants
      NODE_TYPES = {
        :NODE_ALIAS       => 0x01,
        :NODE_AND         => 0x02,
        :NODE_ARGS        => 0x03,
        :NODE_ARGSCAT     => 0x04,
        :NODE_ARGSPUSH    => 0x05,
        :NODE_ARRAY       => 0x06,
        :NODE_ATTRASGN    => 0x07,
        :NODE_ATTRSET     => 0x08,
        :NODE_BACK_REF    => 0x09,
        :NODE_BEGIN       => 0x0a,
        :NODE_BLOCK       => 0x0b,
        :NODE_BLOCK_ARG   => 0x0c,
        :NODE_BLOCK_PASS  => 0x0d,
        :NODE_BMETHOD     => 0x0e,
        :NODE_BREAK       => 0x0f,
        :NODE_CALL        => 0x10,
        :NODE_CASE        => 0x11,
        :NODE_CDECL       => 0x12,
        :NODE_CFUNC       => 0x13,
        :NODE_CLASS       => 0x14,
        :NODE_COLON2      => 0x15,
        :NODE_COLON3      => 0x16,
        :NODE_CONST       => 0x17,
        :NODE_CREF        => 0x18,
        :NODE_CVAR        => 0x19,
        :NODE_CVASGN      => 0x1a,
        :NODE_CVDECL      => 0x1b,
        :NODE_DASGN       => 0x1c,
        :NODE_DASGN_CURR  => 0x1d,
        :NODE_DEFINED     => 0x1e,
        :NODE_DEFN        => 0x1f,
        :NODE_DEFS        => 0x20,
        :NODE_DMETHOD     => 0x21,
        :NODE_DOT2        => 0x22,
        :NODE_DOT3        => 0x23,
        :NODE_DREGX       => 0x24,
        :NODE_DREGX_ONCE  => 0x25,
        :NODE_DSTR        => 0x26,
        :NODE_DSYM        => 0x27,
        :NODE_DVAR        => 0x28,
        :NODE_DXSTR       => 0x29,
        :NODE_ENSURE      => 0x2a,
        :NODE_EVSTR       => 0x2b,
        :NODE_FALSE       => 0x2c,
        :NODE_FBODY       => 0x2d,
        :NODE_FCALL       => 0x2e,
        :NODE_FOR         => 0x2f,
        :NODE_GASGN       => 0x30,
        :NODE_GVAR        => 0x31,
        :NODE_HASH        => 0x32,
        :NODE_IASGN       => 0x33,
        :NODE_IF          => 0x34,
        :NODE_IFUNC       => 0x35,
        :NODE_ITER        => 0x36,
        :NODE_IVAR        => 0x37,
        :NODE_LASGN       => 0x38,
        :NODE_LIST        => 0x39,
        :NODE_LIT         => 0x3a,
        :NODE_LVAR        => 0x3b,
        :NODE_MASGN       => 0x3c,
        :NODE_MATCH       => 0x3d,
        :NODE_MATCH2      => 0x3e,
        :NODE_MATCH3      => 0x3f,
        :NODE_METHOD      => 0x40,
        :NODE_MODULE      => 0x41,
        :NODE_NEWLINE     => 0x42,
        :NODE_NEXT        => 0x43,
        :NODE_NIL         => 0x44,
        :NODE_NOT         => 0x45,
        :NODE_NTH_REF     => 0x46,
        :NODE_OP_ASGN1    => 0x47,
        :NODE_OP_ASGN2    => 0x48,
        :NODE_OP_ASGN22   => 0x49,
        :NODE_OP_ASGN_OR  => 0x4a,
        :NODE_OP_ASGN_AND => 0x4b,
        :NODE_OPT_N       => 0x4c,
        :NODE_OR          => 0x4d,
        :NODE_POSTEXE     => 0x4e,
        :NODE_PREEXE      => 0x4f,
        :NODE_REDO        => 0x50,
        :NODE_RESBODY     => 0x51,
        :NODE_RESCUE      => 0x52,
        :NODE_RETRY       => 0x53,
        :NODE_RETURN      => 0x54,
        :NODE_RFUNC       => 0x55,
        :NODE_SCLASS      => 0x56,
        :NODE_SCOPE       => 0x57,
        :NODE_SELF        => 0x58,
        :NODE_SPLAT       => 0x59,
        :NODE_STR         => 0x5a,
        :NODE_SUPER       => 0x5b,
        :NODE_SVALUE      => 0x5c,
        :NODE_TO_ARY      => 0x5d,
        :NODE_TRUE        => 0x5e,
        :NODE_UNDEF       => 0x5f,
        :NODE_UNLESS      => 0x60,
        :NODE_UNTIL       => 0x61,
        :NODE_VALIAS      => 0x62,
        :NODE_VCALL       => 0x63,
        :NODE_WHEN        => 0x64,
        :NODE_WHILE       => 0x65,
        :NODE_XSTR        => 0x66,
        :NODE_YIELD       => 0x67,
        :NODE_ZARRAY      => 0x68,
        :NODE_ZSUPER      => 0x69
      }
      TAGS = {
        :TAG_RETURN => 0x1,
        :TAG_BREAK  => 0x2,
        :TAG_NEXT   => 0x3,
        :TAG_RETRY  => 0x4,
        :TAG_REDO   => 0x5,
        :TAG_RAISE  => 0x6,
        :TAG_THROW  => 0x7,
        :TAG_FATAL  => 0x8,
        :TAG_MASK   => 0xf
      }
      TYPES = {
        :T_NIL    => 0x01,
        :T_OBJECT => 0x02,
        :T_CLASS  => 0x03,
        :T_ICLASS => 0x04,
        :T_MODULE => 0x05,
        :T_FLOAT  => 0x06,
        :T_STRING => 0x07,
        :T_REGEXP => 0x08,
        :T_ARRAY  => 0x09,
        :T_FIXNUM => 0x0a,
        :T_HASH   => 0x0b,
        :T_STRUCT => 0x0c,
        :T_BIGNUM => 0x0d,
        :T_FILE   => 0x0e,
        :T_TRUE   => 0x20,
        :T_FALSE  => 0x21,
        :T_DATA   => 0x22,
        :T_MATCH  => 0x23,
        :T_SYMBOL => 0x24,
        :T_BLKTAG => 0x3b,
        :T_UNDEF  => 0x3c,
        :T_VARMAP => 0x3d,
        :T_SCOPE  => 0x3e,
        :T_NODE   => 0x3f,
        :T_MASK   => 0x3f
      }
      NOEX_FLAGS = {
        :NOEX_PUBLIC    => 0,
        :NOEX_NOSUPER   => 1,
        :NOEX_PRIVATE   => 2,
        :NOEX_PROTECTED => 4,
        :NOEX_MASK      => 6,
        :NOEX_TAINTED   => 8,
        :NOEX_UNDEF     => 1
      }
      MAX_MIN = {
        :LONG_MAX   => 2147483647,
        :LONG_MIN   => -2147483648,
        :FIXNUM_MAX => 2147483647 >> 1,
        :FIXNUM_MIN => -2147483648 >> 1,
      }
      ITER_FLAGS = {
        :ITER_NOT => 0,
        :ITER_PRE => 1,
        :ITER_CUR => 2,
        :ITER_PAS => 3
      }
      USER_FLAGS = {
        :FL_USHIFT    => 11,
        :FL_USER0     => 1 << (11 + 0),
        :FL_USER1     => 1 << (11 + 1),
        :FL_USER2     => 1 << (11 + 2),
        :FL_USER3     => 1 << (11 + 3),
        :FL_USER4     => 1 << (11 + 4),
        :FL_USER5     => 1 << (11 + 5),
        :FL_USER6     => 1 << (11 + 6),
        :FL_USER7     => 1 << (11 + 7),
        :FL_MARK      => 1 << 6,
        :FL_FINALIZE  => 1 << 7,
        :FL_TAINT     => 1 << 8,
        :FL_EXIVAR    => 1 << 9,
        :FL_FREEZE    => 1 << 10,
        :FL_SINGLETON => 1 << 11,
        :FL_UMASK     => 0xff << 11
      }
      SCOPE_FLAGS = {
        :SCOPE_ALLOCA       => 0,
        :SCOPE_MALLOC       => 1,
        :SCOPE_NOSTACK      => 2,
        :SCOPE_DONT_RECYCLE => 4,
        :SCOPE_MODFUNC      => 5,
        :SCOPE_MASK         => 7,
        :SCOPE_CLONE        => 8,
        :SCOPE_PUBLIC       => 0,
        :SCOPE_PRIVATE      => 1,
        :SCOPE_PROTECTED    => 2
      }
      ID_FLAGS = {
        :ID_SCOPE_SHIFT => 3,
        :ID_LOCAL       => 0x01,
        :ID_INSTANCE    => 0x02,
        :ID_GLOBAL      => 0x03,
        :ID_ATTRSET     => 0x04,
        :ID_CONST       => 0x05,
        :ID_CLASS       => 0x06,
        :ID_JUNK        => 0x07,
        :ID_INTERNAL    => 0x07,
        :ID_SCOPE_MASK  => 0x07
      }
      TOKENS = {
        :tUPLUS      => 317,
        :tUMINUS     => 318,
        :tPOW        => 319,
        :tCMP        => 320,
        :tEQ         => 321,
        :tEQQ        => 322,
        :tNEQ        => 323,
        :tGEQ        => 324,
        :tLEQ        => 325,
        :tMATCH      => 328,
        :tNMATCH     => 329,
        :tDOT2       => 330,
        :tDOT3       => 331,
        :tAREF       => 332,
        :tASET       => 333,
        :tLSHFT      => 334,
        :tRSHFT      => 335,
        :tCOLON2     => 336,
        :tLAST_TOKEN => 359
      }
      PROT_FLAGS = {
        :PROT_NONE   => 0,
        :PROT_FUNC   => 1,
        :PROT_THREAD => 2,
        :PROT_LOOP   => 3,
        :PROT_LAMBDA => 5,
        :PROT_YIELD  => 7
      }
      PROC_FLAGS = {
        :PROC_TMASK  => (1 << (11 + 1))|(1 << (11 + 2))|(1 << (11 + 3)),
        :PROC_TSHIFT => 11 + 1,
        :PROC_TMAX   => ((1 << (11 + 1))|(1 << (11 + 2))|(1 << (11 + 3))) >> 12
      }
      YIELD_FLAGS = {
        :YIELD_LAMBDA_CALL => 1,
        :YIELD_PROC_CALL   => 2,
        :YIELD_PUBLIC_DEF  => 4,
        :YIELD_FUNC_AVALUE => 1,
        :YIELD_FUNC_SVALUE => 2,
        :YIELD_FUNC_LAMBDA => 3
      }
      CSTAT_FLAGS = {
        :CSTAT_PRIV  => 1,
        :CSTAT_PROT  => 2,
        :CSTAT_VCALL => 4,
        :CSTAT_SUPER => 8
      }
      BLOCK_FLAGS = {
        :BLOCK_D_SCOPE => 1,
        :BLOCK_LAMBDA  => 2
      }
      NODE_SLOTS = {
        :nd_head  => :u1,
        :nd_alen  => :u2,
        :nd_next  => :u3,
        
        :nd_cond  => :u1,
        :nd_body  => :u2,
        :nd_else  => :u3,
        
        :nd_orig  => :u3,
        
        :nd_resq  => :u2,
        :nd_ensr  => :u3,
        
        :nd_1st   => :u1,
        :nd_2nd   => :u2,
        
        :nd_stts  => :u1,
        
        :nd_entry => :u3,
        
        :nd_vid   => :u1,
        :nd_cflag => :u2,
        :nd_cval  => :u3,
        
        :nd_cnt   => :u3,
        :nd_tbl   => :u1,
        
        :nd_var   => :u1,
        :nd_ibdy  => :u2,
        :nd_iter  => :u3,
        
        :nd_value => :u2,
        :nd_aid   => :u3,
        
        :nd_lit   => :u1,
        
        :nd_frml  => :u1,
        :nd_rest  => :u2,
        :nd_opt   => :u1,
        
        :nd_recv  => :u1,
        :nd_mid   => :u2,
        :nd_args  => :u3,
        
        :nd_noex  => :u1,
        :nd_defn  => :u3,
        
        :nd_cfnc  => :u1,
        :nd_argc  => :u2,
        
        :nd_cpath => :u1,
        :nd_super => :u3,
        
        :nd_modl  => :u1,
        :nd_clss  => :u1,
        
        :nd_beg   => :u1,
        :nd_end   => :u2,
        :nd_state => :u3,
        
        :nd_rval  => :u2,
        
        :nd_nth   => :u2,
        
        :nd_tag   => :u1,
        :nd_tval  => :u2,
      }
      ST_FLAGS = {
        :ST_CONTINUE => 0x05,
        :ST_STOP     => 0x06,
        :ST_DELETE   => 0x07,
        :ST_CHECK    => 0x08
      }
      TRUTH = {
        :Qfalse => 0,
        :Qtrue  => 2,
        :Qnil   => 4,
        :Qundef => 6
      }
      MISC = {
        :ARY_MAX_SIZE       => 4294967295,
        :ARY_TMPLOCK        => 1 << (11 + 1),
        :BIGRAD             => 1 << 12,
        :BITSPERDIG         => 12,
        :DIGSPERLONG        => 3,
        :ID_ALLOCATOR       => 1,
        :FIXNUM_FLAG        => 0x01,
        :SYMBOL_FLAG        => 0x0e,
        :IMMEDIATE_MASK     => 0x03,
        :CACHE_MASK         => 0x7ff,
        :FLT_ROUNDS         => 1,
        :FLT_RADIX          => 2,
        :DBL_DIG            => 15,
        :DBL_MANT_DIG       => 53,
        :DBL_MIN_EXP        => -1021,
        :DBL_MAX_EXP        => 1024,
        :DBL_MIN_10_EXP     => -307,
        :DBL_MAX_10_EXP     => 308,
        :DVAR_DONT_RECYCLE  => 1 << (11 + 2),
        :FRAME_DMETH        => 1,
        :HASH_DELETED       => 1 << (11 + 1),
        :HASH_PROC_DEFAULT  => 1 << (11 + 2),
        :MIN_SIZE           => 8,
        :NODE_LSHIFT        => 11 + 8,
        :NODE_LMASK         => (1 << (4 * 8 - 19)) - 1,
        :ruby_cbase         => "ruby_cref.u1",
        :BEGIN_CALLARGS     => "(function CALLARGS_MACRO(){var tmp_block=ruby_block,tmp_iter=ruby_iter.iter;switch(tmp_iter){case 1:if(ruby_block){ruby_block=ruby_block.outer;}case 3:tmp_iter=0;}(function ITER_MACRO(){var _iter={prev:ruby_iter,iter:tmp_iter};ruby_iter=_iter",
        :END_CALLARGS       => "ruby_block=tmp_block;ruby_iter=_iter.prev;})();})()"
      }
      RUBY_CONSTANTS = [
        NODE_TYPES,
        TAGS,
        TYPES,
        NOEX_FLAGS,
        MAX_MIN,
        ITER_FLAGS,
        USER_FLAGS,
        SCOPE_FLAGS,
        ID_FLAGS,
        TOKENS,
        PROT_FLAGS,
        PROC_FLAGS,
        YIELD_FLAGS,
        CSTAT_FLAGS,
        BLOCK_FLAGS,
        NODE_SLOTS,
        ST_FLAGS,
        TRUTH,
        MISC
      ].inject({}) {|x,result| result.merge(x) }
      
      NODE_MACROS = {
        :NEW_ALIAS       => "rb_node_newnode(NODE_ALIAS,%s,%s,0)",
        :NEW_ARGS        => "rb_node_newnode(NODE_ARGS,%2$s,%3$s,%1$s)",
        :NEW_ARGSCAT     => "rb_node_newnode(NODE_ARGSCAT,%s,%s,0)",
        :NEW_ARGSPUSH    => "rb_node_newnode(NODE_ARGSPUSH,%s,%s,0)",
        :NEW_ARRAY       => "rb_node_newnode(NODE_ARRAY,%s,1,0)",
        :NEW_ATTRASGN    => "rb_node_newnode(NODE_ATTRASGN,%s,%s,%s)",
        :NEW_ATTRSET     => "rb_node_newnode(NODE_ATTRSET,%s,0,0)",
        :NEW_BACK_REF    => "rb_node_newnode(NODE_BACK_REF,0,%s,local_cnt('~'))",
        :NEW_BEGIN       => "rb_node_newnode(NODE_BEGIN,0,%s,0)",
        :NEW_BLOCK       => "rb_node_newnode(NODE_BLOCK,%s,0,0)",
        :NEW_BLOCK_ARG   => "rb_node_newnode(NODE_BLOCK_ARG,%1$s,0,local_cnt(%1$s))",
        :NEW_BLOCK_PASS  => "rb_node_newnode(NODE_BLOCK_PASS,0,%s,0)",
        :NEW_BMETHOD     => "rb_node_newnode(NODE_BMETHOD,0,0,%s)",
        :NEW_BREAK       => "rb_node_newnode(NODE_BREAK,%s,0,0)",
        :NEW_CALL        => "rb_node_newnode(NODE_CALL,%s,%s,%s)",
        :NEW_CASE        => "rb_node_newnode(NODE_CASE,%s,%s,0)",
        :NEW_CDECL       => "rb_node_newnode(NODE_CDECL,%s,%s,%s)",
        :NEW_CFUNC       => "rb_node_newnode(NODE_CFUNC,%s,%s,0)",
        :NEW_CLASS       => "rb_node_newnode(NODE_CLASS,%s,%s,%s)",
        :NEW_COLON2      => "rb_node_newnode(NODE_COLON2,%s,%s,0)",
        :NEW_COLON3      => "rb_node_newnode(NODE_COLON3,0,%s,0)",
        :NEW_CONST       => "rb_node_newnode(NODE_CONST,%s,0,0)",
        :NEW_CREF        => "rb_node_newnode(NODE_CREF,0,0,%s)",
        :NEW_CVAR        => "rb_node_newnode(NODE_CVAR,%s,0,0)",
        :NEW_CVASGN      => "rb_node_newnode(NODE_CVASGN,%s,%s,0)",
        :NEW_CVDECL      => "rb_node_newnode(NODE_CVDECL,%s,%s,0)",
        :NEW_DASGN       => "rb_node_newnode(NODE_DASGN,%s,%s,0)",
        :NEW_DASGN_CURR  => "rb_node_newnode(NODE_DASGN_CURR,%s,%s,0)",
        :NEW_DEFINED     => "rb_node_newnode(NODE_DEFINED,%s,0,0)",
        :NEW_DEFN        => "rb_node_newnode(NODE_DEFN,%3$s,%1$s,%2$s)",
        :NEW_DEFS        => "rb_node_newnode(NODE_DEFS,%s,%s,%s)",
        :NEW_DMETHOD     => "rb_node_newnode(NODE_DMETHOD,0,0,%s)",
        :NEW_DOT2        => "rb_node_newnode(NODE_DOT2,%s,%s,0)",
        :NEW_DOT3        => "rb_node_newnode(NODE_DOT3,%s,%s,0)",
        :NEW_DSTR        => "rb_node_newnode(NODE_DSTR,%s,1,0)",
        :NEW_DSYM        => "rb_node_newnode(NODE_DSYM,%s,0,0)",
        :NEW_DVAR        => "rb_node_newnode(NODE_DVAR,%s,0,0)",
        :NEW_DXSTR       => "rb_node_newnode(NODE_DXSTR,%s,0,0)",
        :NEW_ENSURE      => "rb_node_newnode(NODE_ENSURE,%s,0,%s)",
        :NEW_EVSTR       => "rb_node_newnode(NODE_EVSTR,0,(%s),0)",
        :NEW_FALSE       => "rb_node_newnode(NODE_FALSE,0,0,0)",
        :NEW_FBODY       => "rb_node_newnode(NODE_FBODY,%s,%s,o)",
        :NEW_FCALL       => "rb_node_newnode(NODE_FCALL,0,%s,%s)",
        :NEW_FOR         => "rb_node_newnode(NODE_FOR,%1$s,%3$s,%2$s)",
        :NEW_GASGN       => "rb_node_newnode(NODE_GASGN,%1$s,%2$s,rb_global_entry(%1$s))",
        :NEW_GVAR        => "rb_node_newnode(NODE_GVAR,%1$s,0,rb_global_entry(%1$s))",
        :NEW_HASH        => "rb_node_newnode(NODE_HASH,%s,0,0)",
        :NEW_IASGN       => "rb_node_newnode(NODE_IASGN,%s,%s,0)",
        :NEW_IF          => "rb_node_newnode(NODE_IF,%s,%s,%s)",
        :NEW_IFUNC       => "rb_node_newnode(NODE_IFUNC,%s,%s,0)",
        :NEW_ITER        => "rb_node_newnode(NODE_ITER,%1$s,%3$s,%2$s)",
        :NEW_IVAR        => "rb_node_newnode(NODE_IVAR,%s,0,0)",
        :NEW_LASGN       => "rb_node_newnode(NODE_LASGN,%1$s,%2$s,local_cnt(%1$s))",
        :NEW_LVAR        => "rb_node_newnode(NODE_LVAR,%1$s,0,local_cnt(%1$s))",
        :NEW_MASGN       => "rb_node_newnode(NODE_MASGN,%s,0,%s)",
        :NEW_MATCH       => "rb_node_newnode(NODE_MATCH,%s,0,0)",
        :NEW_MATCH2      => "rb_node_newnode(NODE_MATCH2,%s,%s,0)",
        :NEW_MATCH3      => "rb_node_newnode(NODE_MATCH3,%s,%s,0)",
        :NEW_METHOD      => "rb_node_newnode(NODE_METHOD,%2$s,%1$s,0)",
        :NEW_MODULE      => "rb_node_newnode(NODE_MODULE,%s,%s,0)",
        :NEW_NEWLINE     => "rb_node_newnode(NODE_NEWLINE,0,0,%s)",
        :NEW_NEXT        => "rb_node_newnode(NODE_NEXT,%s,0,0)",
        :NEW_NIL         => "rb_node_newnode(NODE_NIL,0,0,0)",
        :NEW_NOT         => "rb_node_newnode(NODE_NOT,0,%s,0)",
        :NEW_NTH_REF     => "rb_node_newnode(NODE_NTH_REF,0,%s,local_cnt('~'))",
        :NEW_OP_ASGN1    => "rb_node_newnode(NODE_OP_ASGN1,%s,%s,%s)",
        :NEW_OP_ASGN2    => "rb_node_newnode(NODE_OP_ASGN2,%1$s,%4$s,rb_node_newnode(NODE_OP_ASGN2,%2$s,%3$s,rb_id_attrset(%2$s)))",
        :NEW_OP_ASGN22   => "rb_node_newnode(NODE_OP_ASGN2,%1$s,%2$s,rb_id_attrset(%1$s))",
        :NEW_OP_ASGN_OR  => "rb_node_newnode(NODE_OP_ASGN_OR,%s,%s,0)",
        :NEW_OP_ASGN_AND => "rb_node_newnode(NODE_OP_ASGN_AND,%s,%s,0)",
        :NEW_OPT_N       => "rb_node_newnode(NODE_OPT_N,0,%s,0)",
        :NEW_POSTEXE     => "rb_node_newnode(NODE_POSTEXE,0,0,0)",
        :NEW_REDO        => "rb_node_newnode(NODE_REDO,0,0,0)",
        :NEW_RESBODY     => "rb_node_newnode(NODE_RESBODY,%3$s,%2$s,%1$s)",
        :NEW_RESCUE      => "rb_node_newnode(NODE_RESCUE,%s,%s,%s)",
        :NEW_RETRY       => "rb_node_newnode(NODE_RETRY,0,0,0)",
        :NEW_RETURN      => "rb_node_newnode(NODE_RETURN,%s,0,0)",
        :NEW_SCLASS      => "rb_node_newnode(NODE_SCLASS,%s,%s,0)",
        :NEW_SCOPE       => "rb_node_newnode(NODE_SCOPE,local_tbl(),0,%s)",
        :NEW_SELF        => "rb_node_newnode(NODE_SELF,0,0,0)",
        :NEW_SPLAT       => "rb_node_newnode(NODE_SPLAT,%s,0,0)",
        :NEW_STR         => "rb_node_newnode(NODE_STR,%s,0,0)",
        :NEW_SUPER       => "rb_node_newnode(NODE_SUPER,0,0,%s)",
        :NEW_SVALUE      => "rb_node_newnode(NODE_SVALUE,%s,0,0)",
        :NEW_TO_ARY      => "rb_node_newnode(NODE_TO_ARY,%s,0,0)",
        :NEW_TRUE        => "rb_node_newnode(NODE_TRUE,0,0,0)",
        :NEW_UNDEF       => "rb_node_newnode(NODE_UNDEF,0,%s,0)",
        :NEW_UNTIL       => "rb_node_newnode(NODE_UNTIL,%s,%s,%s)",
        :NEW_VALIAS      => "rb_node_newnode(NODE_VALIAS,%s,%s,0)",
        :NEW_VCALL       => "rb_node_newnode(NODE_VCALL,0,%s,0)",
        :NEW_WHEN        => "rb_node_newnode(NODE_WHEN,%s,%s,%s)",
        :NEW_WHILE       => "rb_node_newnode(NODE_WHILE,%s,%s,%s)",
        :NEW_XSTR        => "rb_node_newnode(NODE_XSTR,%s,0,0)",
        :NEW_YIELD       => "rb_node_newnode(NODE_YIELD,%s,0,%s)",
        :NEW_ZARRAY      => "rb_node_newnode(NODE_ZARRAY,0,0,0)",
        :NEW_ZSUPER      => "rb_node_newnode(NODE_ZSUPER,0,0,0)"
      }
      PUSH_POP = {
        :PUSH_BLOCK => "(function BLOCK_MACRO(){var _block={vars:(%1$s),body:(%2$s),self:self,frame:ruby_frame,klass:ruby_class,cref:ruby_cref,scope:ruby_scope,prev:ruby_block,outer:ruby_block,iter:ruby_iter.iter,vmode:scope_vmode,flags:BLOCK_D_SCOPE,dyna_vars:ruby_dyna_vars,block_obj:0,uniq:(%2$s)?block_unique++:0};_block.frame.node=ruby_current_node;if(%2$s){prot_tag.blkid=_block.uniq;}ruby_block=_block",
        :POP_BLOCK  => "ruby_block=_block.prev;})()",
        
        :PUSH_CLASS => "(function CLASS_MACRO(){var _class=ruby_class;ruby_class=(%s)",
        :POP_CLASS  => "ruby_class=_class;})()",
        
        :PUSH_CREF  => "ruby_cref=rb_node_newnode(NODE_CREF,(%s),0,ruby_cref)",
        :POP_CREF   => "ruby_cref=ruby_cref.nd_next",
        
        :PUSH_FRAME => "(function FRAME_MACRO(){var _frame={prev:ruby_frame,tmp:0,node:ruby_current_node,iter:ruby_iter.iter,argc:0,flags:0,uniq:frame_unique++};ruby_frame=_frame",
        :POP_FRAME  => "ruby_current_node=_frame.node;ruby_frame=_frame.prev;})()",
        
        :PUSH_ITER  => "(function ITER_MACRO(){var _iter={prev:ruby_iter,iter:(%s)};ruby_iter=_iter",
        :POP_ITER   => "ruby_iter=_iter.prev;})()",
        
        :PUSH_SCOPE => "(function SCOPE_MACRO(){var _vmode=scope_vmode,_scope={rvalue:last_value+=4,basic:{klass:0,flags:T_SCOPE},local_tbl:0,local_vars:[],flags:0};var _old=ruby_scope;ruby_scope=_scope;scope_vmode=SCOPE_PUBLIC",
        :POP_SCOPE  => "if(ruby_scope.flags&SCOPE_DONT_RECYCLE){if(_old){scope_dup(_old);}}if(!(ruby_scope.flags&SCOPE_MALLOC)){ruby_scope.local_vars=[];ruby_scope.local_tbl=0;}ruby_scope.flags|=SCOPE_NOSTACK;ruby_scope=_old;scope_vmode=_vmode;})()",
        
        :PUSH_TAG   => "(function TAG_MACRO(){var _tag={retval:Qnil,frame:ruby_frame,iter:ruby_iter,prev:prot_tag,scope:ruby_scope,tag:(%s),dst:0,blkid:0};prot_tag=_tag",
        :POP_TAG    => "prot_tag=_tag.prev;})()",
        
        :PUSH_VARS  => "(function VARS_MACRO(){var _old=ruby_dyna_vars;ruby_dyna_vars=0",
        :POP_VARS   => "if(_old&&(ruby_scope.flags&SCOPE_DONT_RECYCLE)&&_old.flags){FL_SET(_old,DVAR_DONT_RECYCLE);}ruby_dyna_vars=_old;})()",
        
        :SETUP_ARGS => "(function SETUP_ARGS_MACRO(){var n=(%s);if(!n){argc=0;argv=0;}else if(((n.flags>>FL_USHIFT)&0xff)==NODE_ARRAY){argc=n.nd_alen;if(argc>0){argv=[];for(var i=0;i<argc;i++){argv[i]=rb_eval(self,n.nd_head);n=n.nd_next;}}else{argc=0;argv=0;}}else{var args=rb_eval(self,n);if(TYPE(args)!=T_ARRAY){args=rb_ary_to_ary(args);}argc=args.ptr.length;argv=[];MEMCPY(argv,args.ptr,argc);}})()"
      }
      MISC = {
        :ADD_DIRECT      => "do{var entry;if(((%1$s).num_entries/(%1$s).num_bins)>5){rehash(%1$s);(%5$s)=(%4$s)%%(%1$s).num_bins;}entry={};entry.hash=(%4$s);entry.key=(%2$s);entry.record=(%3$s);entry.next=(%1$s).bins[(%5$s)];(%1$s).bins[(%5$s)]=entry;(%1$s).num_entries++;}while(0)",
        :BDIGITS         => "(%s).digits",
        :BIGDN           => "((%s)>>BITSPERDIG)",
        :BIGLO           => "((%s)&(BIGRAD-1))",
        :BIGUP           => "((%s)<<BITSPERDIG)",
        :BIGZEROP        => "((%1$s).len == 0 || (((%1$s).digits[0] === 0) && (((%1$s).len == 1) || bigzero_p(%1$s))))",
        :bignew          => "bignew_1(rb_cBignum,%s,%s)",
        :BUILTIN_TYPE    => "((%s).basic.flags&T_MASK)",
        :Data_Get_Struct => "do{rb_check_type(%1$s,T_DATA);var %2$s=%1$s.data;}while(0)",
        :do_hash         => "((%2$s).type.hash(%1$s))",
        :EXPR1           => "((((%s)>>3)^(%s))&CACHE_MASK)",
        :FIX2INT         => "((%s)>>1)",
        :FIX2LONG        => "((%s)>>1)",
        :FIX2ULONG       => "((%s)>>1)",
        :FIXABLE         => "(((%1$s)<FIXNUM_MAX+1)&&((%1$s)>=FIXNUM_MIN))",
        :FIXNUM_P        => "((%s)&FIXNUM_FLAG)",
        :FL_SET          => "(FL_ABLE(%1$s)?(%1$s).basic.flags|=(%2$s):0)",
        :GetTimeval      => "do{var %2$s=(%1$s).data;}while(0)",
        :ID2SYM          => "((%s)<<8|SYMBOL_FLAG)",
        :IMMEDIATE_P     => "((%s)&IMMEDIATE_MASK)",
        :INT2FIX         => "((%s)<<1|FIXNUM_FLAG)",
        :INT2NUM         => "rb_int2inum(%s)",
        :ISALNUM         => "(/[a-zA-Z0-9]/).test(%s)",
        :ISASCII         => "((%s).charCodeAt(0)<128)",
        :ISDIGIT         => "(/[0-9]/).test(%s)",
        :ISUPPER         => "(/[A-Z]/).test(%s)",
        :LONG2FIX        => "((%s)<<1|FIXNUM_FLAG)",
        :LONG2NUM        => "rb_int2inum(%s)",
        :nd_line         => "(((%s).flags>>NODE_LSHIFT)&NODE_LMASK)",
        :nd_set_line     => "((%1$s).flags=(((%1$s).flags&~(-1<<NODE_LSHIFT))|(((%2$s)&NODE_LMASK)<<NODE_LSHIFT)))",
        :nd_type         => "(((%s).flags>>FL_USHIFT)&0xff)",
        :NEW_NODE        => "rb_node_newnode(%s,%s,%s,%s)",
        :NEWOBJ          => "var %s={rvalue:last_value+=4}",
        :NIL_P           => "((%s)==Qnil)",
        :NOEX_SAFE       => "((%s)>>4)",
        :NOEX_WITH       => "((%s)|(%s)<<4)",
        :NUM2DBL         => "rb_num2dbl(%s)",
        :NUM2INT         => "(((%1$s)&FIXNUM_FLAG)?((%1$s)>>1):rb_num2long(%1$s))",
        :NUM2LONG        => "(((%1$s)&FIXNUM_FLAG)?((%1$s)>>1):rb_num2long(%1$s))",
        :OBJ_FROZEN      => "(FL_ABLE(%1$s)?(%1$s).basic.flags&FL_FREEZE:0)",
        :OBJ_FREEZE      => "(FL_ABLE(%1$s)?(%1$s).basic.flags|=FL_FREEZE:0)",
        :OBJ_TAINT       => "(FL_ABLE(%1$s)?(%1$s).basic.flags|=FL_TAINT:0)",
        :OBJ_TAINTED     => "(FL_ABLE(%1$s)?(%1$s).basic.flags&FL_TAINT:0)",
        :OBJSETUP        => "((%s).basic={klass:(%s),flags:(%s)})",
        :range           => "Math.max(%s, Math.min(%s, %s))",
        :rb_int_new      => "rb_int2inum(%s)",
        :return_value    => "do{if((prot_tag.retval=(%s))==Qundef){prot_tag.retval=Qnil;}}while(0)",
        :RETURN          => "throw({goto_flag:finish_flag,value:(%s)})",
        :RTEST           => "(((%1$s)!=Qnil)&&((%1$s)!==Qfalse))",
        :SPECIAL_CONST_P => "(((%1$s)&IMMEDIATE_MASK)||!(((%1$s)!=Qnil)&&((%1$s)!==Qfalse)))",
        :SYM2ID          => "((%s)>>8)",
        :SYMBOL_P        => "(((%s)&0xff)==SYMBOL_FLAG)",
        :TAG_DST         => "(prot_tag.dst==ruby_frame.uniq)"
      }
      RUBY_MACROS = [
        PUSH_POP,
        NODE_MACROS,
        MISC
      ].inject({}) {|x,result| result.merge(x) }
    end
    
    def process!(str)
      self.process_macros!(str)
      self.process_constants!(str)
      return true
    end
    
    def process_constants!(str)
      RUBY_CONSTANTS.each do |name,value|
        str.gsub!(/\b#{name}\b/, value.to_s)
      end
    end
    
    def process_macros!(str)
      parser = RawParseTree.new
      RUBY_MACROS.each do |name, value|
        str.gsub!(/\b#{name}\(#{'(?:[^()]|\(' * 5}[^()]*#{'\))*' * 5}\)/) do |macro|
          value % macro_args(macro)
        end
      end
    end
    
    def macro_args(str)
      args = []
      open = 0
      buffer = ""
      args_reached = false
      str.each_byte do |c|
        case c
        when ?(
          unless args_reached
            args_reached = true
            next
          end
          open += 1
        when ?)
          if open.zero?
            args.push(buffer)
            return args
          end
          open -= 1
        when ?,
          if open.zero?
            args.push(buffer)
            buffer = ""
            next
          end
        end
        next unless args_reached
        buffer += c.chr
      end
    end
  end
  
  $line = 0
  TYPES = Preprocessor::NODE_TYPES
  
  class Alias < String
    def initialize(m1_sexp, m2_sexp, options)
      m1 = m1_sexp.red!
      m2 = m2_sexp.red!
      self << "r(%s,%s,%s,%s)" % [$line, TYPES[:NODE_ALIAS], m1, m2]
    end
  end
  
  class And < String
    def initialize(sexp1, sexp2, options)
      expr1 = sexp1.red!
      expr2 = sexp2.red!
      self << "r(%s,%s,%s,%s)" % [$line, TYPES[:NODE_AND], expr1, expr2]
    end
  end
  
  class Args < String
    def initialize(*args)
      options = args.pop
      rest = 0
      opts = 0
      argc = 0
      while (arg = args[argc]) && arg.is_a?(Symbol)
        break if arg.to_s[0,1] == "*" && rest = [:lasgn, arg.to_s[1..-1], 0].red!
        argc += 1
      end
      if assignment_block_sexp = args.assoc(:block)
        argc -= (assignment_block_sexp.size - 1)
        opts = assignment_block_sexp.red!
      end
      self << "r(%s,%s,%s,%s,%s)" % [$line, TYPES[:NODE_ARGS], argc, opts, rest]
    end
  end
  
  class Array < String
    def initialize(*element_sexps)
      options = element_sexps.pop
      elements = element_sexps.map {|x| x.red! }.join(",")
      self << "r(%s,%s,[%s])" % [$line, TYPES[:NODE_ARRAY], elements]
    end
  end
  
  class Attrasgn < String
    def initialize(receiver_sexp, method_name, array_sexp, options)
      receiver = receiver_sexp.red!
      arguments = array_sexp.red!
      self << "r(%s,%s,%s,'%s',%s)" % [$line, TYPES[:NODE_ATTRASGN], receiver, method_name, arguments]
    end
  end
  
  class Begin < String
    def initialize(sexp, options)
      expr = sexp.red!
      self << "r(%s,%s,%s)" % [$line, TYPES[:NODE_BEGIN], expr]
    end
  end
  
  class Block < String
    def initialize(*line_sexps)
      options = line_sexps.pop
      lines = line_sexps.map {|line_sexp| line_sexp.red! }.join(",")
      self << "r(%s,%s,[%s])" % [$line, TYPES[:NODE_BLOCK], lines]
    end
  end
  
  class Block_arg < String
    def initialize(arg_name, options)
      self << "r(%s,%s,'%s')" % [$line, TYPES[:NODE_BLOCK_ARG], arg_name]
    end
  end
  
  class Block_pass < String
    def initialize(proc_sexp, iterator_sexp, options)
      proc = proc_sexp.red!
      iterator = iterator_sexp.red!
      self << "r(%s,%s,%s,%s)" % [$line, TYPES[:NODE_BLOCK_PASS], proc, iterator]
    end
  end
  
  class Break < String
    def initialize(*args)
      options = args.pop
      value = args.shift.red!
      self << "r(%s,%s,%s)" % [$line, TYPES[:NODE_BREAK], value]
    end
  end
  
  class Case < String
    def initialize(condition_sexp, *when_sexps)
      options = when_sexps.pop
      condition = condition_sexp.red!
      whens = when_sexps.map {|when_sexp| when_sexp.red! }.join(",")
      self << "r(%s,%s,%s,[%s])" % [$line, TYPES[:NODE_CASE], condition, whens]
    end
  end
  
  class Call < String
    def initialize(receiver_sexp, method_name, *args)
      # return self << inject_red_required_file(*args) if method_name == :require
      options = args.pop
      receiver = receiver_sexp.red!
      arguments = (array_sexp = args.pop) ? array_sexp.red! : "0"
      $mc.add_method(method_name)
      self << "r(%s,%s,%s,'%s',%s)" % [$line, TYPES[:NODE_CALL], receiver, method_name, arguments]
    end
  end
  
  class Cdecl < String
    def initialize(constant_sexp, value_sexp, options)
      constant = constant_sexp.red!
      value = value_sexp.red!
      self << "r(%s,%s,%s,%s)" % [$line, TYPES[:NODE_CDECL], constant, value]
    end
  end
  
  class Class < String
    def initialize(class_sexp, superclass_sexp, scope_sexp, options)
      class_sexp = [:colon2, nil, class_sexp] if class_sexp.is_a? Symbol
      klass = class_sexp.red!
      superclass = superclass_sexp.red!
      scope = scope_sexp.red!
      self << "r(%s,%s,%s,%s,%s)" % [$line, TYPES[:NODE_CLASS], klass, superclass, scope]
    end
  end
  
  class Colon2 < String
    def initialize(object_sexp, constant_name, options)
      object = object_sexp.red!
      self << "r(%s,%s,%s,'%s')" % [$line, TYPES[:NODE_COLON2], object, constant_name]
    end
  end
  
  class Colon3 < String
    def initialize(constant_name, options)
      self << "r(%s,%s,'%s')" % [$line, TYPES[:NODE_COLON3], constant_name]
    end
  end
  
  class Const < String
    def initialize(constant_name, options)
      self << "r(%s,%s,'%s')" % [$line, TYPES[:NODE_CONST], constant_name]
    end
  end
  
  class Cvar < String
    def initialize(variable_name, options)
      self << "r(%s,%s,'%s')" % [$line, TYPES[:NODE_CVAR], variable_name]
    end
  end
  
  class Cvasgn < String
    def initialize(variable_name, value_sexp, options)
      value = value_sexp.red!
      self << "r(%s,%s,'%s',%s)" % [$line, TYPES[:NODE_CVASGN], variable_name, value]
    end
  end
  
  class Cvdecl < String
    def initialize(variable_name, value_sexp, options)
      value = value_sexp.red!
      self << "r(%s,%s,'%s',%s)" % [$line, TYPES[:NODE_CVDECL], variable_name, value]
    end
  end
  
  class Dasgn < String
    def initialize(variable_name, *args)
      options = args.pop
      value = args.shift.red!
      self << "r(%s,%s,'%s',%s)" % [$line, TYPES[:NODE_DASGN], variable_name, value]
    end
  end
  
  class Dasgn_curr < String
    def initialize(variable_name, *args)
      options = args.pop
      value = args.shift.red!
      self << "r(%s,%s,'%s',%s)" % [$line, TYPES[:NODE_DASGN_CURR], variable_name, value]
    end
  end
  
  class Defined < String
    def initialize(sexp, options)
      expr = sexp.red!
      self << "r(%s,%s,%s)" % [$line, TYPES[:NODE_DEFINED], expr]
    end
  end
  
  class Defn < String
    def initialize(method_name, scope_sexp, options)
      scope = scope_sexp.red!
      self << "r(%s,%s,'%s',%s)" % [$line, TYPES[:NODE_DEFN], method_name, scope]
    end
  end
  
  class Defs < String
    def initialize(receiver_sexp, method_name, scope_sexp, options)
      receiver = receiver_sexp.red!
      scope = scope_sexp.red!
      self << "r(%s,%s,%s,'%s',%s)" % [$line, TYPES[:NODE_DEFS], receiver, method_name, scope]
    end
  end
  
  class Dot2 < String
    def initialize(start_sexp, finish_sexp, options)
      start = start_sexp.red!
      finish = finish_sexp.red!
      self << "r(%s,%s,%s,%s)" % [$line, TYPES[:NODE_DOT2], start, finish]
    end
  end
  
  class Dot3 < String
    def initialize(start_sexp, finish_sexp, options)
      start = start_sexp.red!
      finish = finish_sexp.red!
      self << "r(%s,%s,%s,%s)" % [$line, TYPES[:NODE_DOT3], start, finish]
    end
  end
  
  class Dstr < String
    def initialize(string, *element_sexps)
      options = element_sexps.pop
      elements = element_sexps.map {|x| (x.first == :str ? [:evstr, x] : x).red! }.join(",")
      self << "r(%s,%s,'%s',r(%s,%s,[%s]))" % [$line, TYPES[:NODE_DSTR], string, $line, TYPES[:NODE_BLOCK], elements]
    end
  end
  
  class Dsym < String
    def initialize(string, *element_sexps)
      options = element_sexps.pop
      elements = element_sexps.map {|x| (x.first == :str ? [:evstr, x] : x).red! }.join(",")
      self << "r(%s,%s,'%s',r(%s,%s,[%s]))" % [$line, TYPES[:NODE_DSYM], string, $line, TYPES[:NODE_BLOCK], elements]
    end
  end
  
  class Dvar < String
    def initialize(variable_name, options)
      self << "r(%s,%s,'%s')" % [$line, TYPES[:NODE_DVAR], variable_name]
    end
  end
  
  class Ensure < String
    def initialize(body_sexp, ensure_sexp, options)
      body_expr = body_sexp.red!
      ensure_expr = ensure_sexp.red!
      self << "r(%s,%s,%s,%s)" % [$line, TYPES[:NODE_ENSURE], body_expr, ensure_expr]
    end
  end
  
  class Evstr < String
    def initialize(sexp, options)
      expr = sexp.red!
      self << "r(%s,%s,%s)" % [$line, TYPES[:NODE_EVSTR], expr]
    end
  end
  
  class False < String
    def initialize(options)
      self << "r(%s,%s)" % [$line, TYPES[:NODE_FALSE]]
    end
  end
  
  class Fcall < String
    def initialize(method_name, *args)
      options = args.pop
      arguments = (array_sexp = args.pop) ? array_sexp.red! : "0"
      $mc.add_method(method_name)
      self << "r(%s,%s,'%s',%s)" % [$line, TYPES[:NODE_FCALL], method_name, arguments]
    end
  end
  
  class Gasgn < String
    def initialize(variable_name, value_sexp, options)
      value = value_sexp.red!
      self << "r(%s,%s,'%s',%s)" % [$line, TYPES[:NODE_GASGN], variable_name, value]
    end
  end
  
  class Gvar < String
    def initialize(variable_name, options)
      self << "r(%s,%s,'%s')" % [$line, TYPES[:NODE_GVAR], variable_name]
    end
  end
  
  class Hash < String
    def initialize(*element_sexps)
      options  = element_sexps.pop
      elements = element_sexps.map {|x| x.red! }.join(",")
      self << "r(%s,%s,[%s])" % [$line, TYPES[:NODE_HASH], elements]
    end
  end
  
  class If < String
    def initialize(condition_sexp, body_sexp, else_sexp, options)
      condition = condition_sexp.red!
      body_expr = body_sexp.red!
      else_expr = else_sexp.red!
      self << "r(%s,%s,%s,%s,%s)" % [$line, TYPES[:NODE_IF], condition, body_expr, else_expr]
    end
  end
  
  class Iasgn < String
    def initialize(variable_name, value_sexp, options)
      value = value_sexp.red!
      self << "r(%s,%s,'%s',%s)" % [$line, TYPES[:NODE_IASGN], variable_name, value]
    end
  end
  
  class Iter < String
    def initialize(receiver_sexp, dvars_sexp, body_sexp, options)
      receiver = receiver_sexp.red!
      dvars = dvars_sexp.red!
      body = body_sexp.red!
      self << "r(%s,%s,%s,%s,%s)" % [$line, TYPES[:NODE_ITER], receiver, dvars, body]
    end
  end
  
  class Ivar < String
    def initialize(variable_name, options)
      self << "r(%s,%s,'%s')" % [$line, TYPES[:NODE_IVAR], variable_name]
    end
  end
  
  class Lasgn < String
    def initialize(variable_name, *args)
      options = args.pop
      value = args.shift.red!
      self << "r(%s,%s,'%s',%s)" % [$line, TYPES[:NODE_LASGN], variable_name, value]
    end
  end
  
  class Lvar < String
    def initialize(variable_name, options)
      self << "r(%s,%s,'%s')" % [$line, TYPES[:NODE_LVAR], variable_name]
    end
  end
  
  class Lit < String
    def initialize(value, options)
      case value.class.to_s
      when 'Fixnum'
        self << "r(%s,%s,%d)" % [$line, 0xfc, value]
      when 'Float'
        self << "r(%s,%s,%.15f)" % [$line, 0xfd, value]
      when 'Regexp'
        self << "r(%s,%s,%p)" % [$line, 0xfe, value]
      when 'Symbol'
        self << "r(%s,%s,'%s')" % [$line, 0xff, value]
      end
    end
  end
  
  class Masgn < String
    def initialize(args_array_sexp, rest_arg_sexp, value_sexp, options)
      args_array = args_array_sexp.red!
      rest_arg = rest_arg_sexp.red!
      value = value_sexp.red!
      self << "r(%s,%s,%s,%s,%s)" % [$line, TYPES[:NODE_MASGN], args_array, rest_arg, value]
    end
  end
  
  class Module < String
    def initialize(module_sexp, scope_sexp, options)
      module_sexp = [:colon2, nil, module_sexp] if module_sexp.is_a? Symbol
      mod = module_sexp.red!
      scope = scope_sexp.red!
      self << "r(%s,%s,%s,%s)" % [$line, TYPES[:NODE_MODULE], mod, scope]
    end
  end
  
  class Newline < String
    def initialize(line, file, sexp, options)
      $line = line
      self << sexp.red!
    end
  end
  
  class Next < String
    def initialize(*args)
      options = args.pop
      value = args.shift.red!
      self << "r(%s,%s,%s)" % [$line, TYPES[:NODE_NEXT], value]
    end
  end
  
  class Nil < String
    def initialize(options)
      self << "r(%s,%s)" % [$line, TYPES[:NODE_NIL]]
    end
  end
  
  class Not < String
    def initialize(sexp, options)
      expr = sexp.red!
      self << "r(%s,%s,%s)" % [$line, TYPES[:NODE_NOT], expr]
    end
  end
  
  class Or < String
    def initialize(sexp1, sexp2, options)
      expr1 = sexp1.red!
      expr2 = sexp2.red!
      self << "r(%s,%s,%s,%s)" % [$line, TYPES[:NODE_OR], expr1, expr2]
    end
  end
  
  class Postexe < String
    def initialize(options)
      self << "r(%s,%s)" % [$line, TYPES[:NODE_POSTEXE]]
    end
  end
  
  class Redo < String
    def initialize(options)
      self << "r(%s,%s)" % [$line, TYPES[:NODE_REDO]]
    end
  end
  
  class Resbody < String
    def initialize(array_sexp, exceptions_sexp, *args)
      options = args.pop
      array = array_sexp.red!
      exceptions = exceptions_sexp.red!
      resbody = args.shift.red!
      self << "r(%s,%s,%s,%s,%s)" % [$line, TYPES[:NODE_RESBODY], array, exceptions, resbody]
    end
  end
  
  class Rescue < String
    def initialize(body_sexp, resbody_sexp, *args)
      options = args.pop
      body = body_sexp.red!
      resbody = resbody_sexp.red!
      _else = args.shift.red!
      self << "r(%s,%s,%s,%s,%s)" % [$line, TYPES[:NODE_RESCUE], body, resbody, _else]
    end
  end
  
  class Return < String
    def initialize(*args)
      options = args.pop
      value = args.shift.red!
      self << "r(%s,%s,%s)" % [$line, TYPES[:NODE_RETURN], value]
    end
  end
  
  class Sclass < String
    def initialize(receiver_sexp, scope_sexp, options)
      receiver = receiver_sexp.red!
      scope = scope_sexp.red!
      self << "r(%s,%s,%s,%s)" % [$line, TYPES[:NODE_SCLASS], receiver, scope]
    end
  end
  
  class Scope < String
    def initialize(scope_sexp, options = nil)
      options = options || scope_sexp
      scope = scope_sexp == options ? "0" : scope_sexp.red!
      self << "r(%s,%s,%s)" % [$line, TYPES[:NODE_SCOPE], scope]
    end
  end
  
  class Self < String
    def initialize(options)
      self << "r(%s,%s)" % [$line, TYPES[:NODE_SELF]]
    end
  end
  
  class Splat < String
    def initialize(sexp, options)
      expr = sexp.red!
      self << "r(%s,%s,%s)" % [$line, TYPES[:NODE_SPLAT], expr]
    end
  end
  
  class Str < String
    def initialize(string_sexp, options)
      self << "r(%s,%s,%s)" % [$line, TYPES[:NODE_STR], string_sexp.inspect]
    end
  end
  
  class True < String
    def initialize(options)
      self << "r(%s,%s)" % [$line, TYPES[:NODE_TRUE]]
    end
  end
  
  class Until < String
    def initialize(condition_sexp, block_sexp, strict, options)
      condition = condition_sexp.red!
      block = block_sexp.red!
      self << "r(%s,%s,%s,%s,%s)" % [$line, TYPES[:NODE_UNTIL], condition, block, strict]
    end
  end
  
  class Valias < String
    def initialize(v1_sexp, v2_sexp, options)
      v1 = v1_sexp.red!
      v2 = v2_sexp.red!
      self << "r(%s,%s,%s,%s)" % [$line, TYPES[:NODE_VALIAS], v1, v2]
    end
  end
  
  class Vcall < String
    def initialize(variable_name, options)
      self << "r(%s,%s,'%s')" % [$line, TYPES[:NODE_VCALL], variable_name]
    end
  end
  
  class When < String
    def initialize(condition_sexp, body_sexp, options)
      condition = condition_sexp.red!
      body = body_sexp.red!
      self << "r(%s,%s,%s,%s)" % [$line, TYPES[:NODE_WHEN], condition, body]
    end
  end
  
  class While < String
    def initialize(condition_sexp, block_sexp, strict_sexp, options)
      condition = condition_sexp.red!
      block = block_sexp.red!
      strict = strict.red!
      self << "r(%s,%s,%s,%s,%s)" % [$line, TYPES[:NODE_WHILE], condition, block, strict]
    end
  end
  
  class Xstr < String
    def initialize(string_sexp, options)
      self << "r(%s,%s,function() { %s; })" % [$line, TYPES[:NODE_XSTR], string_sexp]
    end
  end
  
  class Zarray < String
    def initialize(options)
      self << "r(%s,%s)" % [$line, TYPES[:NODE_ZARRAY]]
    end
  end
  
  class ::Array
    def red!(options = {})
      sexp_type = self.shift.to_s
      node_class = Object.instance_eval(sexp_type.capitalize)
      node_class.new(*(self + [options]))
    end
  end
  
  class ::FalseClass
    def red!(options = {})
      "0"
    end
  end
  
  class ::Integer
    def red!(options = {})
      "%d" % self
    end
  end
  
  class ::NilClass
    def red!(options = {})
      "0"
    end
  end
  
  class ::Symbol
    def red!(options = {})
      "'%s'" % self
    end
  end
  
  class ::TrueClass
    def red!(options = {})
      "2"
    end
  end
  
  def inject_red_required_file(*args)
    options = args.pop
    return self.parse_and_compile_ast(File.read(args.last.last))
  end
  
  def minify(js)
    quote_queue = []
    js.gsub!(/\/\/.*/," ")
    js.gsub!(/\n/," ")
    js.gsub!(/\s+/," ")
    js.gsub!(/".*?"/) {|match| quote_queue.push(match); "$__$" }
    js.gsub!(/\/\*\s.+?\s\*\//," ")
    js.gsub!(/([a-zA-Z0-9_$\\])\s([^a-zA-Z0-9_$\\])/,'\1\2')
    js.gsub!(/([^a-zA-Z0-9_$\\])\s([a-zA-Z0-9_$\\])/,'\1\2')
    js.gsub!(/([^a-zA-Z0-9_$\\])\s([^a-zA-Z0-9_$\\])/,'\1\2')
    js.gsub!(/([^a-zA-Z0-9_$\\])\s([^a-zA-Z0-9_$\\])/,'\1\2')
    js.gsub!(/\$__\$/) { quote_queue.shift }
    raise "Unterminated javascript string literal" unless quote_queue.empty?
    return js
  end
  
  def parse_and_compile_ast(str)
    RawParseTree.new(true).parse_tree_for_string(str)[0].red!
  end
  
  def rb_to_gz(path)
    ungzipped = rb_to_js(path.gsub(/js/,'red'))
    ::File.open('stream','w+') do |f|
      gzw = GzipWriter.new(f)
      gzw.write(ungzipped)
      gzw.close
    end
    gzipped = ::File.read('stream')
    ::File.delete('stream')
    return gzipped
  end
  
  def rb_to_js(path)
    pre = "ruby_init();\ntry{ruby_sourcefile='%s';rb_eval(ruby_top_self," % path
    post = ");}catch(x){if(typeof(state=x)!='number'){throw(state);}error_print();}"
    red_js = pre + self.parse_and_compile_ast(::File.read(path)) + post
    puts "\n\n#{red_js}\n\n\n"
    ruby_source = SOURCE_FILES.inject("") {|result,x| result += File.read(x) }
    $mc.add_function(:ruby_init)
    ruby_source += $mc.functions
    ruby_source += $mc.methods
    condensed_ruby_source = self.minify(ruby_source)
    Preprocessor.new.process!(condensed_ruby_source)
    source = condensed_ruby_source + red_js
  # $mc.compiled_functions.each do |name,stub|
  #   source.gsub!(/\b#{name}\b/,stub)
  # end
    return source
  end
  
  RUBY_SOURCE_FILES = %w[
    src/system/macro.js
    src/system/red.js
  ]
  SOURCE_FILES = RUBY_SOURCE_FILES
end
