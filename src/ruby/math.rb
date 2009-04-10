class Red::MethodCompiler
  # verbatim
  def math_log
    add_function :rb_Float, :domain_check, :rb_float_new
    <<-END
      function math_log(obj, x) {
        x = rb_Float(x);
        errno = 0;
        var d = Math.log(x.value);
        domain_check(d, "log");
        return rb_float_new(d);
      }
    END
  end
end
