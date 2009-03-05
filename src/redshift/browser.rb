class Red::MethodCompiler
  # complete
  def browser_platform
    <<-END
      function browser_platform(browser) {
        return ruby_platform;
      }
    END
  end
  
  # complete
  def browser_engine
    add_function :rb_hash_s_create, :rb_intern
    <<-END
      function browser_engine(browser) {
        return rb_hash_s_create(4, [ID2SYM(rb_intern("name")), ruby_engine_name, ID2SYM(rb_intern("version")), ruby_engine_version], rb_cHash);
      }
    END
  end
  
  # complete
  def rb_f_air_p
    <<-END
      function rb_f_air_p() {
        return ruby_air;
      }
    END
  end
  
  # complete
  def rb_f_gecko_p
    add_function :rb_scan_args
    <<-END
      function rb_f_gecko_p(argc, argv) {
        var v = rb_scan_args(argc, argv, "01")[1];
        return (ruby_engine_name.ptr == 'gecko') ? (argc === 0 ? Qtrue : (ruby_engine_version == v ? Qtrue : Qfalse)) : Qfalse;
      }
    END
  end
  
  # complete
  def rb_f_presto_p
    add_function :rb_scan_args
    <<-END
      function rb_f_presto_p(argc, argv) {
        var v = rb_scan_args(argc, argv, "01")[0];
        return (ruby_engine_name.ptr == 'presto') ? (argc === 0 ? Qtrue : (ruby_engine_version == v ? Qtrue : Qfalse)) : Qfalse;
      }
    END
  end
  
  # complete
  def rb_f_query_p
    <<-END
      function rb_f_query_p() {
        return ruby_query;
      }
    END
  end
  
  # complete
  def rb_f_trident_p
    add_function :rb_scan_args
    <<-END
      function rb_f_trident_p(argc, argv) {
        var v = rb_scan_args(argc, argv, "01")[0];
        return (ruby_engine_name.ptr == 'trident') ? (argc === 0 ? Qtrue : (ruby_engine_version == v ? Qtrue : Qfalse)) : Qfalse;
      }
    END
  end
  
  # complete
  def rb_f_webkit_p
    add_function :rb_scan_args
    <<-END
      function rb_f_webkit_p(argc, argv) {
        var v = rb_scan_args(argc, argv, "01")[0];
        return (ruby_engine_name.ptr == 'webkit') ? (argc === 0 ? Qtrue : (ruby_engine_version == v ? Qtrue : Qfalse)) : Qfalse;
      }
    END
  end
  
  # complete
  def rb_f_xpath_p
    <<-END
      function rb_f_xpath_p() {
        return ruby_xpath;
      }
    END
  end
  
  # complete
  def rb_init_engine
      add_function :rb_str_new
      <<-END
        function rb_init_engine() {
          var n = 'unknown';
          var v = 0;
          if (window.opera) {
            n = 'presto';
            v = (arguments.callee.caller) ? 960 : (document.getElementsByClassName ? 950 : 925);
          }
          if (window.ActiveXObject) {
            n = 'trident';
            v = (window.XMLHttpRequest) ? 5 : 4;
          }
          if (!navigator.taintEnabled) {
            n = 'webkit';
            v = (ruby_xpath) ? (ruby_query ? 525 : 420) : 419;
          }
          if (typeof(document.getBoxObjectFor) != "undefined") {
            n = 'gecko';
            v = (document.getElementsByClassName) ? 19 : 18;
          }
          ruby_engine_name = rb_str_new(n);
          ruby_engine_version = INT2FIX(v);
        }
      END
    end
end
