class Red::MethodCompiler
  # removed bug warning
  def rb_struct_equal
    <<-END
      function rb_struct_equal(s, s2) {
        if (s == s2) { return Qtrue; }
        if (TYPE(s2) != T_STRUCT) { return Qfalse; }
        if (rb_obj_class(s) != rb_obj_class(s2)) { return Qfalse; }
        for (var i = 0, p = s.ptr, p2 = s2.ptr, l = s.ptr.length; i < l; ++i) {
          if (!rb_equal(p[i], p2[i])) return Qfalse;
        }
        return Qtrue;
      }
    END
  end
  
  # EMPTY
  def rb_struct_init_copy
    <<-END
      function rb_struct_init_copy() {}
    END
  end
  
  # EMPTY
  def rb_struct_initialize
    <<-END
      function rb_struct_initialize() {}
    END
  end
  
  # EMPTY
  def rb_struct_inspect
    <<-END
      function rb_struct_inspect() {}
    END
  end
  
  # EMPTY
  def rb_struct_s_def
    <<-END
      function rb_struct_s_def() {}
    END
  end
  
  # EMPTY
  def rb_struct_to_a
    <<-END
      function rb_struct_to_a() {}
    END
  end
end
