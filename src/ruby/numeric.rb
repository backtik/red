class Red::MethodCompiler
  # verbatim
  def num_init_copy
    add_function :rb_raise, :rb_obj_classname
    <<-END
      function num_init_copy(x, y) {
        /* Numerics are immutable values, which should not be copied */
        rb_raise(rb_eTypeError, "can't copy %s", rb_obj_classname(x));
        return Qnil; /* not reached */
      }
    END
  end
  
  # verbatim
  def num_sadded
    add_function :rb_raise, :rb_id2name, :rb_to_id, :rb_obj_classname
    <<-END
      function num_sadded(x, name) {
        ruby_frame = ruby_frame.prev; /* pop frame for "singleton_method_added" */
        /* Numerics should be values; singleton_methods should not be added to them */
        rb_raise(rb_eTypeError, "can't define singleton method '%s' for %s", rb_id2name(rb_to_id(name)), rb_obj_classname(x));
        return Qnil; /* not reached */
      }
    END
  end
end
