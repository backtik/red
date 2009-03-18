class Red::MethodCompiler
  # changed rb_str_new2 to rb_str_new
  def false_to_s
    add_functions :rb_str_new
    <<-END
      function false_to_s(obj) {
        return rb_str_new("false");
      }
    END
  end
  
  # verbatim
  def false_and
    <<-END
      function false_and(obj1, obj2) {
        return Qfalse;
      }
    END
  end
  
  # verbatim
  def false_or
    <<-END
      function false_or(obj1, obj2) {
        return RTEST(obj2) ? Qtrue : Qfalse;
      }
    END
  end
  
  # verbatim
  def false_xor
    <<-END
      function false_xor(obj1, obj2) {
        return RTEST(obj2) ? Qtrue : Qfalse;
      }
    END
  end
end

