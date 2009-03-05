class Red::MethodCompiler
  # CHECK
  def hash_alloc
    add_function :hash_alloc0
    <<-END
      function hash_alloc(klass) {
        var hash = hash_alloc0(klass);
        hash.tbl = {};
        return hash;
      }
    END
  end
  
  # CHECK
  def hash_alloc0
    <<-END
      function hash_alloc0(klass) {
        var hash = { ifnone: Qnil, val: last_value += 4 };
        OBJSETUP(hash, klass, T_HASH);
        return hash;
      }
    END
  end
  
  # CHECK
  def hash_foreach_ensure
    add_function :st_cleanup_safe
    <<-END
      function hash_foreach_ensure(hash) {
        RHASH(hash).iter_lev--;
        if (RHASH(hash).iter_lev === 0) {
          if (FL_TEST(hash, HASH_DELETED)) {
            st_cleanup_safe(RHASH(hash).tbl, Qundef);
            FL_UNSET(hash, HASH_DELETED);
          }
        }
        return 0;
      }
    END
  end
  
  # CHECK
  def hash_foreach_iter
    add_function :rb_raise, :st_delete_safe
    <<-END
      function hash_foreach_iter(key, value, arg) {
        var status;
        var tbl;
        tbl = RHASH(arg.hash).tbl;
        if (key == Qundef) { return ST_CONTINUE; }
        status = arg.func(key, value, arg.arg);
        if (RHASH(arg.hash).tbl != tbl) { rb_raise(rb_eRuntimeError, "rehash occurred during iteration"); }
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
  
  # CHECK
  def rb_hash_aref
    add_function :rb_funcall
    add_method :default
    <<-END
      function rb_hash_aref(hash, key) {
        var val;
        if (!(val = hash.tbl[key])) {
          return rb_funcall(hash, id_default, 1, key);
        }
        return val;
      }
    END
  end
  
  # CHECK
  def rb_hash_aset
    add_function :rb_hash_modify, :rb_str_new4
    <<-END
      function rb_hash_aset(hash, key, val) {
      //rb_hash_modify(hash);
        if (TYPE(key) != T_STRING || hash.tbl[key]) {
          hash.tbl[key] = val;
        } else {
          hash.tbl[rb_str_new4(key)] = val;
        }
        return val;
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
  
  # CHECK
  def rb_hash_foreach
    add_function :rb_ensure, :hash_foreach_call, :hash_foreach_ensure
    <<-END
      function rb_hash_foreach(hash, func, farg) {
        var arg = {};
        RHASH(hash).iter_lev++;
        arg.hash = hash;
        arg.func = func;
        arg.arg  = farg;
        rb_ensure(hash_foreach_call, arg, hash_foreach_ensure, hash);
      }
    END
  end
  
  # CHECK
  def rb_hash_foreach_call
    add_function :st_foreach, :hash_foreach_iter, :rb_raise
    <<-END
      function rb_hash_foreach_call(arg) {
        if (st_foreach(RHASH(arg.hash).tbl, hash_foreach_iter, arg)) { rb_raise(rb_eRuntimeError, "hash modified during iteration"); }
        return Qnil;
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
  
  # CHECK
  def rb_hash_inspect
    add_function :rb_str_new, :rb_inspecting_p, :rb_protect_inspect, :inspect_hash
    <<-END
      function rb_hash_inspect(hash) {
        if (hash.tbl === 0 || hash.tbl.length === 0) { return rb_str_new("{}"); }
        if (rb_inspecting_p(hash)) { return rb_str_new("{...}"); }
        return rb_protect_inspect(inspect_hash, hash, 0);
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
  
  # CHECK
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
