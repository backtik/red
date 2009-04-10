class Red::MethodCompiler
  # verbatim
  def collect_all
    add_function :rb_ary_push
    <<-END
      function collect_all(i, ary) {
        rb_ary_push(ary, i);
        return Qnil;
      }
    END
  end
  
  # verbatim
  def collect_i
    add_function :rb_yield, :rb_ary_push
    <<-END
      function collect_i(i, ary) {
        rb_ary_push(ary, rb_yield(i));
        return Qnil;
      }
    END
  end
  
  # verbatim
  def enum_collect
    add_function :rb_iterate, :rb_each, :rb_ary_new, :rb_block_given_p, :collect_all, :collect_i
    <<-END
      function enum_collect(obj) {
        var ary = rb_ary_new();
        rb_iterate(rb_each, obj, rb_block_given_p() ? collect_i : collect_all, ary);
        return ary;
      }
    END
  end
  
  # EMPTY
  def enum_find
    <<-END
      function enum_find() {}
    END
  end
  
  # verbatim
  def enum_member
    add_function :rb_iterate, :rb_each, :member_i
    <<-END
      function enum_member(obj, val) {
        var memo = [val, Qfalse];
        rb_iterate(rb_each, obj, member_i, memo);
        return memo[1];
      }
    END
  end
  
  # verbatim
  def enum_to_a
    add_function :rb_block_call, :collect_all, :rb_ary_new
    <<-END
      function enum_to_a(argc, argv, obj) {
        var ary = rb_ary_new();
        rb_block_call(obj, id_each, argc, argv, collect_all, ary);
        return ary;
      }
    END
  end
  
  # verbatim
  def member_i
    add_function :rb_equal, :rb_iter_break
    <<-END
      function member_i(item, memo) {
        if (rb_equal(item, memo[0])) {
          memo[1] = Qtrue;
          rb_iter_break();
        }
        return Qnil;
      }
    END
  end
  
  # verbatim
  def rb_each
    add_function :rb_funcall
    add_method :each
    <<-END
      function rb_each(obj) {
        return rb_funcall(obj, id_each, 0, 0);
      }
    END
  end
end
