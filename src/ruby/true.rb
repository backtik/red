class Red::MethodCompiler
  # verbatim
  def true_and
    <<-END
      function true_and(obj1, obj2) {
        return RTEST(obj2) ? Qtrue : Qfalse;
      }
    END
  end
  
  # verbatim
  def true_or
    <<-END
      function true_or(obj1, obj2) {
        return Qtrue;
      }
    END
  end
  
  # changed rb_str_new2 to rb_str_new
  def true_to_s
    add_function :rb_str_new
    <<-END
      function true_to_s(obj) {
        return rb_str_new("true");
      }
    END
  end
  
  # verbatim
  def true_xor
    <<-END
      function true_xor(obj1, obj2) {
        return RTEST(obj2) ? Qfalse : Qtrue;
      }
    END
  end
end
