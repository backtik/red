function POSFIXABLE(f) { return f < FIXNUM_MAX + 1; }
function NEGFIXABLE(f) { return f >= FIXNUM_MIN; }

function FL_ABLE(x)    { return !SPECIAL_CONST_P(x); }
function FL_TEST(x,f)  { return FL_ABLE(x) ? x.basic.flags & f : 0; }
function FL_UNSET(x,f) { if (FL_ABLE(x)) { x.basic.flags &= ~f; } }

function OBJ_INFECT(x,s) { if (FL_ABLE(x) && FL_ABLE(s)) { x.basic.flags |= s.basic.flags & FL_TAINT; } }

function TYPE(obj) {
  if (FIXNUM_P(obj)) { return T_FIXNUM; }
  if (obj == Qnil)   { return T_NIL;    }
  if (obj == Qfalse) { return T_FALSE;  }
  if (obj == Qtrue)  { return T_TRUE;   }
  if (obj == Qundef) { return T_UNDEF;  }
  if (SYMBOL_P(obj)) { return T_SYMBOL; }
  return BUILTIN_TYPE(obj);
}

function CLASS_OF(obj) {
  if (FIXNUM_P(obj)) { return rb_cFixnum; }
  if (obj == Qnil)   { return rb_cNilClass; }
  if (obj == Qfalse) { return rb_cFalseClass; }
  if (obj == Qtrue)  { return rb_cTrueClass; }
  if (SYMBOL_P(obj)) { return rb_cSymbol; }
  return obj.basic.klass;
}

function rb_safe_level() {
  return ruby_safe_level;
}

function EXCL(r)       { return RTEST(rb_ivar_get(r, id_excl)); }
function SET_EXCL(r,v) { rb_ivar_set(r, id_excl, v ? Qtrue : Qfalse); }

function NOEX_WITH_SAFE(n) { return NOEX_WITH(n, 1); }

function SCOPE_SET(f)  { scope_vmode = f; }
function SCOPE_TEST(f) { return scope_vmode & f; }

function Check_Type(v, t) { return rb_check_type(v, t); }

function RETURN_ENUMERATOR(obj, argc, argv) { if (!rb_block_given_p()) { return rb_enumeratorize(obj, ID2SYM(rb_frame_this_func()), argc, argv); } }

// MEMCPY(nargv+1, argv, VALUE, argc) ==> MEMCPY(nargv, argv, argc, 1)
// argv = [0,1,2,3,4]
// nargv = ['a','b','c','d','e','f']
// nargv ==> ['a',0,1,2,3,4]
function MEMCPY(p1,p2,n,offset) {
  if (!p1) { p1 = []; } // unnecessary?
  if (!p2) { p2 = []; } // unnecessary?
  var offset1 = (offset || 0) > 0 ? offset : 0;
  var offset2 = (offset || 0) < 0 ? offset : 0;
  for (var i = 0; i < n; ++i) {
    p1[i + offset1] = p2[i - offset2];
  }
}

// changed ruby_longjmp
function JUMP_TAG(st) {
  ruby_frame = prot_tag.frame;
  ruby_iter = prot_tag.iter;
  throw(st); // was ruby_longjmp
}

// verbatim
function DMETHOD_P() {
  return ruby_frame.flags & FRAME_DMETH;
}

// verbatim
function nd_set_type(n, t) {
  n.flags = ((n.flags & ~FL_UMASK) | ((t << FL_USHIFT) & FL_UMASK));
}
