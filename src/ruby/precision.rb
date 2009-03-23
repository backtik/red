class Red::MethodCompiler
  # verbatim
  def prec_included
    add_function :rb_define_singleton_method, :prec_induced_from, :rb_check_type
    <<-END
      function prec_included(module, include) {
        switch (TYPE(include)) {
          case T_CLASS:
          case T_MODULE:
            break;
          default:
            Check_Type(include, T_CLASS);
            break;
        }
        rb_define_singleton_method(include, "induced_from", prec_induced_from, 1);
        return module;
      }
    END
  end
  
  # verbatim
  def prec_induced_from
    add_function :rb_obj_classname, :rb_class2name, :rb_raise
    <<-END
      function prec_induced_from(module, x) {
        rb_raise(rb_eTypeError, "undefined conversion from %s into %s", rb_obj_classname(x), rb_class2name(module));
        return Qnil; /* not reached */
      }
    END
  end
end
