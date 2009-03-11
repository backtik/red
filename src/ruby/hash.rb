class Red::MethodCompiler
  # verbatim
  def clear_i
    <<-END
      function clear_i(key, value, dummy) {
        return ST_DELETE;
      }
    END
  end
  
  # CHECK
  def hash_alloc
    add_function :hash_alloc0, :st_init_table
    <<-END
      function hash_alloc(klass) {
        var hash = hash_alloc0(klass);
        hash.tbl = st_init_table(objhash);
        return hash;
      }
    END
  end
  
  # CHECK
  def hash_alloc0
    <<-END
      function hash_alloc0(klass) {
        var hash = NEWOBJ();
        OBJSETUP(hash, klass, T_HASH);
        hash.ifnone = Qnil;
        hash.iter_lev = 0;
        return hash;
      }
    END
  end
  
  # modified "num_entries" handling
  def hash_equal
    add_function :rb_respond_to, :rb_intern, :rb_equal, :rb_exec_recursive, :recursive_eql
    add_method :to_hash
    <<-END
      function hash_equal(hash1, hash2, eql) {
        var data = {};
        if (hash1 == hash2) { return Qtrue; }
        if (TYPE(hash2) != T_HASH) {
          if (!rb_respond_to(hash2, rb_intern("to_hash"))) { return Qfalse; }
          return rb_equal(hash2, hash1);
        }
        if (hash1.num_entries != hash2.num_entries) { return Qfalse; }
        if (eql && !(rb_equal(hash1.ifnone, hash2.ifnone) && (FL_TEST(hash1, HASH_PROC_DEFAULT) == FL_TEST(hash2, HASH_PROC_DEFAULT)))) { return Qfalse; }
        data.tbl = hash2.tbl;
        data.eql = eql;
        return rb_exec_recursive(recursive_eql, hash1, data);
      }
      
    END
  end
  
  # verbatim
  def hash_foreach_call
    add_function :st_foreach, :hash_foreach_iter, :rb_raise
    <<-END
      function hash_foreach_call(arg) {
        if (st_foreach(arg.hash.tbl, hash_foreach_iter, arg)) { rb_raise(rb_eRuntimeError, "hash modified during iteration"); }
        return Qnil;
      }
    END
  end
  
  # verbatim
  def hash_foreach_ensure
    add_function :st_cleanup_safe
    <<-END
      function hash_foreach_ensure(hash) {
        hash.iter_lev--;
        if (hash.iter_lev === 0) {
          if (FL_TEST(hash, HASH_DELETED)) {
            st_cleanup_safe(hash.tbl, Qundef);
            FL_UNSET(hash, HASH_DELETED);
          }
        }
        return 0;
      }
    END
  end
  
  # verbatim
  def hash_foreach_iter
    add_function :rb_raise, :st_delete_safe
    <<-END
      function hash_foreach_iter(key, value, arg) {
        var status;
        var tbl = arg.hash.tbl;
        if (key == Qundef) { return ST_CONTINUE; }
        status = arg.func(key, value, arg.arg);
        if (arg.hash.tbl != tbl) { rb_raise(rb_eRuntimeError, "rehash occurred during iteration"); }
        switch (status) {
          case ST_DELETE:
            st_delete_safe(tbl, key, 0, Qundef);
            FL_SET(arg.hash, HASH_DELETED);
          case ST_CONTINUE:
            break;
          case ST_STOP:
            return ST_STOP;
        }
        return ST_CHECK;
      }
    END
  end
  
  # modified so that hval is an array containing the hash value
  def hash_i
    <<-END
      function hash_i(key, val, hval) {
        if (key == Qundef) { return ST_CONTINUE; }
        hval[0] ^= rb_hash(key);
        hval[0] ^= rb_hash(val);
        return ST_CONTINUE;
      }
    END
  end
  
  # removed str_buf handling
  def inspect_hash
    add_function :rb_hash_foreach, :inspect_i
    <<-END
      function inspect_hash(hash) {
        var str = rb_str_new("{");
        rb_hash_foreach(hash, hash_inspect_i, str);
        str.ptr += '}';
        OBJ_INFECT(str, hash);
        return str;
      }
    END
  end
  
  # removed str_buf handling, renamed from "inspect_i"
  def hash_inspect_i
    add_function :rb_inspect
    <<-END
      function hash_inspect_i(key, value, str) {
        if (key == Qundef) { return ST_CONTINUE; }
        if (str.ptr.length > 1) { str.ptr += ', '; }
        var str2 = rb_inspect(key);
        str.ptr += str2.ptr;
        OBJ_INFECT(str, str2);
        str.ptr += ' => ';
        str2 = rb_inspect(value);
        str.ptr += str2.ptr;
        OBJ_INFECT(str, str2);
        return ST_CONTINUE;
      }
    END
  end
  
  # verbatim
  def numcmp
    <<-END
      function numcmp(x, y) {
        return x != y;
      }
    END
  end
  
  # verbatim
  def numhash
    <<-END
      function numhash(n) {
        return n;
      }
    END
  end
  
  # verbatim
  def rb_any_cmp
    add_function :rb_str_cmp, :rb_eql
    <<-END
      function rb_any_cmp(a, b) {
        if (a == b) { return 0; }
        if (FIXNUM_P(a) && FIXNUM_P(b)) { return a != b; }
        if ((TYPE(a) == T_STRING) && (a.basic.klass == rb_cString) && (TYPE(b) == T_STRING) && (b.basic.klass == rb_cString)) { return rb_str_cmp(a, b); }
        if ((a == Qundef) || (b == Qundef)) { return -1; }
        if (SYMBOL_P(a) && SYMBOL_P(b)) { return a != b; }
        return !rb_eql(a, b); // was "rb_with_disable_interrupt(eql, [a, b])"
      }
    END
  end
  
  # verbatim
  def rb_any_hash
    add_function :rb_str_hash, :rb_funcall
    add_method :hash, :%
    <<-END
      function rb_any_hash(a) {
        var hval;
        var hnum;
        switch (TYPE(a)) {
          case T_FIXNUM:
          case T_SYMBOL:
            hnum = a;
            break;
          case T_STRING:
            hnum = rb_str_hash(a);
            break;
          default:
            hval = rb_funcall(a, id_hash, 0);
            if (!FIXNUM_P(hval)) { hval = rb_funcall(hval, '%', 1, INT2FIX(536870923)); }
            hnum = FIX2LONG(hval);
        }
        hnum <<= 1;
        return hnum >> 1;
      }
    END
  end
  
  def rb_hash
    add_function :rb_funcall
    add_method :hash
    <<-END
      function rb_hash(obj) {
        return rb_funcall(obj, id_hash, 0);
      }
    END
  end
  
  # verbatim
  def rb_hash_aref
    add_function :rb_funcall, :st_lookup
    add_method :default
    <<-END
      function rb_hash_aref(hash, key) {
        if (!(val = st_lookup(hash.tbl, key))[0]) { return rb_funcall(hash, id_default, 1, key); }
        return val[1];
      }
    END
  end
  
  # CHECK
  def rb_hash_aset
    add_function :rb_hash_modify, :rb_str_new, :st_insert, :st_add_direct
    <<-END
      function rb_hash_aset(hash, key, val) {
      //rb_hash_modify(hash);
        if ((TYPE(key) != T_STRING) || st_lookup(hash.tbl, key, 0)[0]) {
          st_insert(hash.tbl, key, val);
        } else {
          key = rb_str_new(key.ptr);
          st_add_direct(hash.tbl, rb_str_new(key.ptr), val);
        }
        return val;
      }
    END
  end
  
  # verbatim
  def rb_hash_clear
    add_function :rb_hash_modify, :rb_hash_foreach, :clear_i
    <<-END
      function rb_hash_clear(hash) {
        rb_hash_modify(hash);
        if (hash.tbl.num_entries > 0) { rb_hash_foreach(hash, clear_i, 0); }
        return hash;
      }
    END
  end
  
  # expanded rb_scan_args
  def rb_hash_default
    add_function :rb_scan_args, :rb_funcall
    add_method :call
    <<-END
      function rb_hash_default(argc, argv, hash) {
        var tmp = rb_scan_args(argc, argv, "01");
        var key = tmp[1];
        if (FL_TEST(hash, HASH_PROC_DEFAULT)) {
          if (argc === 0) { return Qnil; }
          return rb_funcall(hash.ifnone, id_call, 2, hash, key);
        }
        return hash.ifnone;
      }
    END
  end
  
  # verbatim
  def rb_hash_equal
    add_function :hash_equal
    <<-END
      function rb_hash_equal(hash1, hash2) {
        return hash_equal(hash1, hash2, Qfalse);
      }
    END
  end
  
  # verbatim
  def rb_hash_foreach
    add_function :rb_ensure, :hash_foreach_call, :hash_foreach_ensure
    <<-END
      function rb_hash_foreach(hash, func, farg) {
        var arg = {};
        hash.iter_lev++;
        arg.hash = hash;
        arg.func = func;
        arg.arg  = farg;
        rb_ensure(hash_foreach_call, arg, hash_foreach_ensure, hash); // &arg
      }
    END
  end
  
  # CHECK
  def rb_hash_has_key
    <<-END
      function rb_hash_has_key(hash, key) {
        if (typeof(RHASH(hash).tbl[key]) == 'undefined') { return Qfalse; }
        return Qtrue;
      }
    END
  end
  
  # CHECK
  def rb_hash_has_value
    add_function :rb_hash_foreach, :rb_hash_search_value
    <<-END
      function rb_hash_has_value(hash, val) {
        var data = [Qfalse, val];
        rb_hash_foreach(hash, rb_hash_search_value, data);
        return data[0];
      }
    END
  end
  
  # verbatim
  def rb_hash_hash
    add_function :rb_exec_recursive, :recursive_hash
    <<-END
      function rb_hash_hash(hash) {
        return rb_exec_recursive(recursive_hash, hash, 0);
      }
    END
  end
  
  # expanded rb_scan_args
  def rb_hash_initialize
    add_function :rb_hash_modify, :rb_block_given_p, :rb_raise, :rb_block_proc, :rb_scan_args
    <<-END
      function rb_hash_initialize(argc, argv, hash) {
        var ifnone;
      //rb_hash_modify(hash);
        if (rb_block_given_p()) {
          if (argc > 0) { rb_raise(rb_eArgError, "wrong number of arguments"); }
          hash.ifnone = rb_block_proc();
          FL_SET(hash, HASH_PROC_DEFAULT);
        } else {
          var tmp = rb_scan_args(argc, argv, "01");
          ifnone = tmp[1];
          hash.ifnone = ifnone;
        }
        return hash;
      }
    END
  end
  
  # verbatim
  def rb_hash_inspect
    add_function :rb_str_new, :rb_inspecting_p, :rb_protect_inspect, :inspect_hash
    <<-END
      function rb_hash_inspect(hash) {
        if (((hash.tbl || 0) === 0) || (hash.tbl.num_entries === 0)) { return rb_str_new("{}"); }
        if (rb_inspecting_p(hash)) { return rb_str_new("{...}"); }
        return rb_protect_inspect(inspect_hash, hash, 0);
      }
    END
  end
  
  # verbatim
  def rb_hash_modify
    add_function :rb_raise, :rb_error_frozen
    <<-END
      function rb_hash_modify(hash) {
        if (!hash.tbl) { rb_raise(rb_eTypeError, "uninitialized Hash"); }
        if (OBJ_FROZEN(hash)) { rb_error_frozen("hash"); }
        if (!OBJ_TAINTED(hash) && (ruby_safe_level >= 4)) { rb_raise(rb_eSecurityError, "Insecure: can't modify hash"); }
      }
    END
  end
  
  # CHECK
  def rb_hash_new
    add_function :hash_alloc
    <<-END
      function rb_hash_new() {
        return hash_alloc(rb_cHash);
      }
    END
  end
  
  # verbatim
  def rb_hash_rehash
    add_function :rb_hash_modify, :st_init_table_with_size, :rb_hash_foreach, :rb_hash_rehash_i, :st_free_table
    <<-END
      function rb_hash_rehash(hash) {
        rb_hash_modify(hash);
        var tbl = st_init_table_with_size(objhash, hash.tbl.num_entries);
        rb_hash_foreach(hash, rb_hash_rehash_i, tbl);
        st_free_table(hash.tbl);
        hash.tbl = tbl;
        return hash;
      }
    END
  end
  
  # verbatim
  def rb_hash_rehash_i
    add_function :st_insert
    <<-END
      function rb_hash_rehash_i(key, value, tbl) {
        if (key != Qundef) { st_insert(tbl, key, value); }
        return ST_CONTINUE;
      }
    END
  end
  
  # verbatim
  def rb_hash_replace
    add_function :to_hash, :rb_hash_clear, :rb_hash_foreach, :replace_i
    <<-END
      function rb_hash_replace(hash, hash2) {
        hash2 = to_hash(hash2);
        if (hash == hash2) { return hash; }
        rb_hash_clear(hash);
        rb_hash_foreach(hash2, replace_i, hash);
        hash.ifnone = hash2.ifnone;
        if (FL_TEST(hash2, HASH_PROC_DEFAULT)) {
          FL_SET(hash, HASH_PROC_DEFAULT);
        } else {
          FL_UNSET(hash, HASH_PROC_DEFAULT);
        }
        return hash;
      }
    END
  end
  
  # CHECK
  def rb_hash_s_create
    add_function :rb_check_convert_type, :hash_alloc0, :rb_check_array_type, :hash_alloc,
                 :rb_hash_aset, :rb_raise
    <<-END
      function rb_hash_s_create(argc, argv, klass) {
        var hash;
        var tmp;
        var i;
        if (argc == 1) {
          tmp = rb_check_convert_type(argv[0], T_HASH, "Hash", "to_hash");
          if (!NIL_P(tmp)) {
            hash = hash_alloc0(klass);
            RHASH(hash).tbl = RHASH(tmp).tbl;
            return hash;
          }
          tmp = rb_check_array_type(argv[0]);
          if (!NIL_P(tmp)) {
            hash = hash_alloc(klass);
            for (i = 0; i < RARRAY_LEN(tmp); ++i) {
              var v = rb_check_array_type(RARRAY_PTR(tmp)[i]);
              if (NIL_P(v)) { continue; }
              if (RARRAY_LEN(v) < 1 || 2 < RARRAY_LEN(v)) { continue; }
              rb_hash_aset(hash, RARRAY_PTR(v)[0], RARRAY_PTR(v)[1]);
            }
            return hash;
          }
        }
        if (argc % 2 != 0) { rb_raise(rb_eArgError, "odd number of arguments for Hash"); }
        hash = hash_alloc(klass);
        for (i = 0; i < argc; i += 2) {
          rb_hash_aset(hash, argv[i], argv[i + 1]);
        }
        return hash;
      }
    END
  end
  
  # CHECK
  def rb_hash_to_a
    add_function :rb_hash_foreach, :to_a_i
    <<-END
      function rb_hash_to_a(hash) {
        var ary = rb_ary_new();
        rb_hash_foreach(hash, to_a_i, ary);
        if (OBJ_TAINTED(hash)) { OBJ_TAINT(ary); }
        return ary;
      }
    END
  end
  
  # verbatim
  def rb_hash_to_hash
    <<-END
      function rb_hash_to_hash(hash) {
        return hash;
      }
    END
  end
  
  # CHECK
  def rb_hash_to_s
    add_functions :rb_inspecting_p, :rb_str_new, :rb_protect_inspect, :to_s_hash
    <<-END
      function rb_hash_to_s(hash) {
        if (rb_inspecting_p(hash)) { return rb_str_new("{...}"); };
        return rb_protect_inspect(to_s_hash, hash, 0);
      }
    END
  end
  
  # modified hash_i so that it takes a one-item array
  def recursive_hash
    add_function :hash_i, :rb_hash_foreach
    <<-END
      function recursive_hash(hash, dummy, recur) {
        if (recur) { return LONG2FIX(0); }
        var hval = [hash.tbl.num_entries];
        rb_hash_foreach(hash, hash_i, hval);
        return INT2FIX(hval[0]);
      }
    END
  end
  
  # verbatim
  def replace_i
    add_function :rb_hash_aset
    <<-END
      function replace_i(key, val, hash) {
        if (key != Qundef) { rb_hash_aset(hash, key, val); }
        return ST_CONTINUE;
      }
    END
  end
  
  # CHECK THIS ST_CONTINUE STUFF
  def to_a_i
    add_function :rb_ary_push, :rb_assoc_new
    <<-END
      function to_a_i(key, value, ary) {
        if (key == Qundef) { return ST_CONTINUE; }
        rb_ary_push(ary, rb_assoc_new(key, value));
        return ST_CONTINUE;
      }
    END
  end
  
  # verbatim
  def to_hash
    add_function :rb_convert_type
    <<-END
      function to_hash(hash) {
        return rb_convert_type(hash, T_HASH, "Hash", "to_hash");
      }
    END
  end
  
  # verbatim
  def to_s_hash
    add_function :rb_ary_to_s, :rb_hash_to_a
    <<-END
      function to_s_hash(hash) {
        return rb_ary_to_s(rb_hash_to_a(hash));
      }
    END
  end
end
