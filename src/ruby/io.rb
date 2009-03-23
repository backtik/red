class Red::MethodCompiler
  # CHECK
  def io_alloc
    <<-END
      function io_alloc(klass) {
        var io = NEWOBJ();
        OBJSETUP(io, klass, T_FILE);
        io.fptr = 0;
        return io;
      }
    END
  end
  
  def io_puts_ary
    add_function :rb_io_puts, :rb_inspecting_p
    <<-END
      function io_puts_ary(ary, out) {
        for (var i = 0, p = ary.ptr, l = p.length; i < l; ++i) {
          var tmp = p[i];
          if (rb_inspecting_p(tmp)) { tmp = rb_str_new("[...]"); }
          rb_io_puts(1, [tmp], out);
        }
        return Qnil;
      }
    END
  end
  
  # CHECK
  def io_write
    add_function :rb_obj_as_string
    <<-END
      function io_write(io, str) {
        var n;
        if (TYPE(str) != T_STRING) { str = rb_obj_as_string(str); }
        if (str.ptr.length === 0) { return INT2FIX(0); }
        n = str.ptr.length;
        CONSOLE_LOG_BUFFER += str.ptr;
      //return LONG2FIX(n);
      }
    END
  end
  
  # CHECK
  def lineno_setter
    <<-END
      function lineno_setter(val, id, variable) {
        gets_lineno = NUM2INT(val);
        return INT2FIX(gets_lineno)
      }
    END
  end
  
  # CHECK
  def prep_stdio
    add_function :io_alloc
    <<-END
      function prep_stdio(f, mode, klass) {
        var io = io_alloc(klass);
        return io;
      }
    END
  end
  
  # CHECK
  def rb_f_puts
    add_function :rb_io_puts
    <<-END
      function rb_f_puts(argc, argv) {
        rb_io_puts(argc, argv, rb_stdout);
        return Qnil;
      }
    END
  end
  
  # CHECK
  def rb_io_initialize
    <<-END
      function rb_io_initialize(argc, argv, io) {
        return io;
      }
    END
  end
  
  # CHECK
  def rb_io_puts
    add_functions :rb_io_write, :rb_str_new, :rb_check_array_type, :rb_protect_inspect,
                  :rb_obj_as_string, :rb_io_write, :io_puts_ary
    <<-END
      function rb_io_puts(argc, argv, out) {
        var line;
        if (argc === 0) {
          rb_io_write(out, rb_default_rs);
          console.log(CONSOLE_LOG_BUFFER);
          CONSOLE_LOG_BUFFER = '';
          return Qnil;
        }
        for (var i = 0; i < argc; i++) {
          if (NIL_P(argv[i])) {
            line = rb_str_new("nil");
          } else {
            line = rb_check_array_type(argv[i]);
            if (!NIL_P(line)) {
              rb_protect_inspect(io_puts_ary, line, out);
              continue;
            }
            line = rb_obj_as_string(argv[i]);
          }
          rb_io_write(out, line);
          if (line.ptr === '' || line.ptr[line.ptr.length - 1] != '\\n') {
            rb_io_write(out, rb_default_rs);
          }
        }
        console.log(CONSOLE_LOG_BUFFER);
        CONSOLE_LOG_BUFFER = '';
        return Qnil;
      }
    END
  end
  
  # removed warning
  def rb_io_s_new
    add_function :rb_class_new_instance
    <<-END
      function rb_io_s_new(argc, argv, klass) {
        return rb_class_new_instance(argc, argv, klass);
      }
    END
  end
  
  # CHECK
  def rb_io_write
    add_function :rb_funcall
    add_method :write
    <<-END
      function rb_io_write(io, str) {
        return rb_funcall(io, id_write, 1, str);
      }
    END
  end
  
  # merged rb_write_error and rb_write_error2 to eliminate 'len', changed stderr to stdout
  def rb_write_error
    add_function :rb_io_write, :rb_str_new
    <<-END
      function rb_write_error(mesg) {
        rb_io_write(rb_stdout, rb_str_new(mesg));
      }
    END
  end
end
