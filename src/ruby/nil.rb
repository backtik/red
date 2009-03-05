class Red::MethodCompiler
  # changed rb_str_new2 to rb_str_new
  def nil_inspect
    add_function :rb_str_new
    <<-END
      function nil_inspect(obj) {
        return rb_str_new("nil");
      }
    END
  end
  
  # verbatim
  def nil_to_f
    add_function :rb_float_new
    <<-END
      function nil_to_f(obj) {
        return rb_float_new(0.0);
      }
    END
  end
  
  # verbatim
  def nil_to_i
    <<-END
      function nil_to_i(obj) {
        return INT2FIX(0);
      }
    END
  end
  
  # changed rb_str_new2 to rb_str_new
  def nil_to_s
    add_function :rb_str_new
    <<-END
      function nil_to_s(obj) {
        return rb_str_new("");
      }
    END
  end
  
  # changed rb_ary_new2 to rb_ary_new
  def nil_to_a
    add_function :rb_ary_new
    <<-END
      function nil_to_a(obj) {
        return rb_ary_new();
      }
    END
  end
end
