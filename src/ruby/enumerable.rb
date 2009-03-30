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
        rb_iterate(rb_each, obj, member_i, [val, Qfalse]);
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
end
