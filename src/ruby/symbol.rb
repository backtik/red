class Red::MethodCompiler
  # completely changed; incomplete (needs to handle, e.g., :"one and two")
  def sym_inspect
    add_function :rb_str_new, :rb_id2name
    <<-END
      function sym_inspect(sym) {
        return rb_str_new(':' + rb_id2name(SYM2ID(sym)));
      }
    END
  end
  
  # verbatim
  def sym_to_i
    <<-END
      function sym_to_i(sym) {
        return LONG2FIX(SYM2ID(sym));
      }
    END
  end
  
  # removed warning
  def sym_to_int
    add_function :sym_to_i
    <<-END
      function sym_to_int(sym) {
        return sym_to_i(sym);
      }
    END
  end
  
  # verbatim
  def sym_to_proc
    add_function :rb_proc_new
    <<-END
      function sym_to_proc(sym) {
        return rb_proc_new(sym_call, SYM2ID(sym));
      }
    END
  end
  
  # changed rb_str_new2 to rb_str_new
  def sym_to_s
    add_function :rb_str_new, :rb_id2name
    <<-END
      function sym_to_s(sym) {
        return rb_str_new(rb_id2name(SYM2ID(sym)));
      }
    END
  end
  
  # verbatim
  def sym_to_sym
    <<-END
      function sym_to_sym(sym) {
        return sym;
      }
    END
  end
end
