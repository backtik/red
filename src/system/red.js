function r(line,type,a,b,c) {
  ruby_sourceline = line;
  switch (type) {
    case NODE_AND:
      return NEW_NODE(NODE_AND, a, b, 0);
    
    case NODE_ALIAS:
      return NEW_ALIAS(a, b);
    
    case NODE_ARGS:
      return NEW_ARGS(a, b, c);
    
    case NODE_ARRAY:
      for (var i = a.length, last = NEW_NODE(NODE_ARRAY, a[--i], a.length - i,0); i-- > 0;) {
        last = NEW_NODE(NODE_ARRAY, a[i], a.length - i,last);
      }
      return last;
    
    case NODE_ATTRASGN:
      return NEW_ATTRASGN(a, rb_intern(b), c);
    
    case NODE_BEGIN:
      return NEW_BEGIN(a);
    
    case 0xfb: // Bignum
      var big = bignew(a.length, b);
      big.digits = a;
      return NEW_NODE(NODE_LIT, big, 0, 0);
    
    case NODE_BLOCK:
      for (var i = a.length, last = NEW_NODE(NODE_BLOCK, a[--i],0,0); i-- > 0; ) {
        last = NEW_NODE(NODE_BLOCK, a[i], 0, last);
      }
      return last;
    
    case NODE_BLOCK_ARG:
      return NEW_BLOCK_ARG(rb_intern(a));
    
    case NODE_BLOCK_PASS:
      return NEW_NODE(NODE_BLOCK_PASS,0,a,b);
    
    case NODE_BREAK:
      return NEW_BREAK(a);
    
    case NODE_CASE:
      for (var when, i = b.length, last = b[--i]; i-- > 0; ) {
        when = b[i]; when.nd_next = last; last = when;
      }
      return NEW_CASE(a, when);
    
    case NODE_CALL:
      return NEW_CALL(a, rb_intern(b), c);
    
    case NODE_CDECL:
      return (typeof(a) == "string") ? NEW_CDECL(rb_intern(a), b, 0) : NEW_CDECL(0, b, a);
    
    case NODE_CLASS:
      return NEW_CLASS(a, c, b);
    
    case NODE_COLON2:
      return NEW_COLON2(a, rb_intern(b));
    
    case NODE_CONST:
      return NEW_CONST(rb_intern(a));
    
    case NODE_CVAR:
      return NEW_CVAR(rb_intern(a));
    
    case NODE_CVASGN:
      return NEW_CVASGN(rb_intern(a), b);
    
    case NODE_CVDECL:
      return NEW_CVDECL(rb_intern(a), b);
    
    case NODE_DASGN:
      return NEW_DASGN(rb_intern(a), b);
    
    case NODE_DASGN_CURR:
      return NEW_DASGN_CURR(rb_intern(a), b);
    
    case NODE_DEFINED:
      return NEW_DEFINED(a);
    
    case NODE_DEFN:
      return NEW_DEFN(rb_intern(a), b, NOEX_PRIVATE);
    
    case NODE_DEFS:
      return NEW_DEFS(a, rb_intern(b), c);
    
    case NODE_DOT2:
      return NEW_DOT2(a, b);
    
    case NODE_DOT3:
      return NEW_DOT3(a, b);
    
    case NODE_DSTR:
      return NEW_NODE(NODE_DSTR, a, 1, b);
    
    case NODE_DSYM:
      return NEW_NODE(NODE_DSYM, a, 0, b);
    
    case NODE_DVAR:
      return NEW_DVAR(rb_intern(a));
    
    case NODE_ENSURE:
      return NEW_ENSURE(a, b);
    
    case NODE_EVSTR:
      return NEW_EVSTR(a);
    
    case NODE_FALSE:
      return NEW_FALSE();
    
    case NODE_FCALL:
      return NEW_FCALL(rb_intern(a), b);
    
    case 0xfd: // Flo
      return NEW_NODE(NODE_LIT, rb_float_new(a), 0, 0);
    
    case NODE_GASGN:
      return NEW_GASGN(rb_intern(a), b);
    
    case NODE_GVAR:
      return NEW_GVAR(rb_intern(a));
    
    case NODE_HASH:
      return NEW_HASH(a);
    
    case NODE_IASGN:
      return NEW_IASGN(rb_intern(a), b);
    
    case NODE_IF:
      return NEW_IF(a, b, c);
    
    case NODE_ITER:
      return NEW_ITER(b, a, c);
    
    case NODE_IVAR:
      return NEW_IVAR(rb_intern(a));
    
    case NODE_LASGN:
      return NEW_LASGN(rb_intern(a), b);
    
    case NODE_LVAR:
      return NEW_LVAR(rb_intern(a));
    
    case NODE_MASGN:
      return NEW_MASGN(a, b);
    
    case NODE_MODULE:
      return NEW_MODULE(a, b);
    
    case NODE_NEXT:
      return NEW_NEXT(a);
    
    case NODE_NIL:
      return NEW_NIL();
    
    case NODE_NOT:
      return NEW_NOT(a);
    
    case 0xfc: // Num
      return NEW_NODE(NODE_LIT,INT2FIX(a),0,0);
    
    case NODE_OR:
      return NEW_NODE(NODE_OR, a, b, 0);
    
    case NODE_POSTEXE:
      return NEW_POSTEXE();
    
    case NODE_REDO:
      return NEW_REDO();
    
    case NODE_RESBODY:
      return NEW_RESBODY(a, b, c);
    
    case NODE_RESCUE:
      return NEW_RESCUE(a, b, c);
    
    case NODE_RETURN:
      return NEW_RETURN(a);
    
    case NODE_SCLASS:
      return NEW_SCLASS(a, b);
    
    case NODE_SCOPE:
      return NEW_SCOPE(a);
    
    case NODE_SELF:
      return NEW_SELF();
    
    case NODE_SPLAT:
      return NEW_SPLAT(a);
    
    case NODE_STR:
      return NEW_STR(a);
    
    case 0xff: // Sym
      return NEW_NODE(NODE_LIT,ID2SYM(rb_intern(a)),0,0);
    
    case NODE_TRUE:
      return NEW_TRUE();
    
    case NODE_UNTIL:
      return NEW_UNTIL(a, b, c);
    
    case NODE_VALIAS:
      return NEW_VALIAS(a, b);
    
    case NODE_VCALL:
      return NEW_VCALL(rb_intern(a));
    
    case NODE_WHEN:
      return NEW_WHEN(a, b, 0);
    
    case NODE_WHILE:
      return NEW_WHILE(a, b, c);
    
    case NODE_XSTR:
      return NEW_XSTR(a);
    
    case NODE_ZARRAY:
      return NEW_ZARRAY();
    
    default:
      console.log('unimplemented node type ' + type + ' in ' + r);
  }
}

function jsprintf(f,ary) {
  var i = 0, a, o = [], m, p, c, x;
  while (f) {
    if (m = /^[^\x25]+/.exec(f)) {
      o.push(m[0]);
    } else if (m = /^\x25{2}/.exec(f)) { 
      o.push('%');
    } else if (m = /^\x25(?:(\d+)\$)?(\+)?(0|'[^$])?(-)?(\d+)?(?:\.(\d+))?([b-gosuxX])/.exec(f)) {
      if (((a = ary[m[1] || i++]) === null) || (typeof(a) == 'undefined')) { return o.join(''); } //throw("Too few arguments passed to sprintf"); }
      if (/[^s]/.test(m[7]) && (typeof(a) != 'number')) { throw("Expecting number but found " + typeof(a) + ": " + a.toString()); }
      switch (m[7]) {
        case 'b': a = a.toString(2); break;
        case 'c': a = String.fromCharCode(a); break;
        case 'd': a = parseInt(a); break;
        case 'e': a = m[6] ? a.toExponential(m[6]) : a.toExponential(); break;
        case 'f': a = m[6] ? parseFloat(a).toFixed(m[6]) : parseFloat(a); break;
        case 'g': a = m[6] ? Number(String(parseFloat(a).toFixed(m[6]))) : Number(String(parseFloat(a))); break;
        case 'o': a = a.toString(8); break;
        case 's': a = ((a = String(a)) && m[6] ? a.substring(0, m[6]) : a); break;
        case 'u': a = Math.abs(a); break;
        case 'x': a = a.toString(16); break;
        case 'X': a = a.toString(16).toUpperCase(); break;
      }
      a = (/[def]/.test(m[7]) && m[2] && a > 0) ? ('+' + a) : a;
      c = m[3] ? (m[3] == '0' ? '0' : m[3].charAt(1)) : ' ';
      x = m[5] - String(a).length;
      p = m[5] ? (function(i,m) { for (var o = []; m > 0; o[--m] = i); return(o.join('')); })(c, x) : '';
      o.push(m[4] ? (a + p) : (p + a));
    } else {
      throw ("Huh ?!");
    }
    f = f.substring(m[0].length);
  }
  return o.join('');
}

function red_init_bullshit() {
  // hacked
  ruby_sourcefile = 'ruby.js';
  ruby_sourceline = 1;
  rb_cClass  = 0;
  rb_cObject = 0;
  ruby_scope = {};
  scope_vmode = 0;
  ruby_current_node = 0;
  ruby_dyna_vars = 0;
  ruby_running = 0;
  ruby_safe_level = 0;
  ruby_digitmap = "0123456789abcdefghijklmnopqrstuvwxyz";
  last_value = 3600000;
  frame_unique = 1;
  lvtbl = {};
  inspect_tbl = Qnil;
  recursive_hash = Qnil;
  prot_tag = { prev: 0, iter: 0 };
  ruby_errinfo = Qnil;
  lineno = INT2FIX(0);
  ruby_block = 0;
  block_unique = 1;
  cache = {};
  if (typeof(initialized) == "undefined") { initialized = 0; }
  last_id = tLAST_TOKEN;
  
  op_tbl = {
    '..':  tDOT2,
    '...': tDOT3,
    '+':   43,
    '-':   45,
    '*':   42,
    '/':   47,
    '%':   37,
    '**':  tPOW,
    '+@':  tUPLUS,
    '-@':  tUMINUS,
    '|':   124,
    '^':   94,
    '&':   38,
    '<=>': tCMP,
    '>':   62,
    '>=':  tGEQ,
    '<':   60,
    '<=':  tLEQ,
    '==':  tEQ,
    '===': tEQQ,
    '!=':  tNEQ,
    '=~':  tMATCH,
    '!~':  tNMATCH,
    '!':   33,
    '~':   126,
    '!@':  33,
    '~@':  126,
    '[]':  tAREF,
    '[]=': tASET,
    '<<':  tLSHFT,
    '>>':  tRSHFT,
    '::':  tCOLON2,
    '`':   96,
    0:     0
  };
  
  builtin_types = {
    T_NIL:    'nil',
    T_OBJECT: 'Object',
    T_CLASS:  'Class',
    T_ICLASS: 'iClass',
    T_MODULE: 'Module',
    T_FLOAT:  'Float',
    T_STRING: 'String',
    T_REGEXP: 'Regexp',
    T_ARRAY:  'Array',
    T_FIXNUM: 'Fixnum',
    T_HASH:   'Hash',
    T_STRUCT: 'Struct',
    T_BIGNUM: 'Bignum',
    T_FILE:   'File',
    T_TRUE:   'true',
    T_FALSE:  'false',
    T_SYMBOL: 'Symbol',
    T_DATA:   'Data',
    T_MATCH:  'MatchData',
    T_VARMAP: 'Varmap',
    T_SCOPE:  'Scope',
    T_NODE:   'Node',
    T_UNDEF:  'undef'
  };
  
  primes = [
    8 + 3,
    16 + 3,
    32 + 5,
    64 + 3,
    128 + 3,
    256 + 27,
    512 + 9,
    1024 + 9,
    2048 + 5,
    4096 + 3,
    8192 + 27,
    16384 + 43,
    32768 + 3,
    65536 + 45,
    131072 + 29,
    262144 + 3,
    524288 + 21,
    1048576 + 7,
    2097152 + 17,
    4194304 + 15,
    8388608 + 9,
    16777216 + 43,
    33554432 + 35,
    67108864 + 15,
    134217728 + 29,
    268435456 + 3,
    536870912 + 11,
    1073741824 + 85,
    0
  ];
}