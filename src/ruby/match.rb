class Red::MethodCompiler
  # verbatim
  def match_alloc
    <<-END
      function match_alloc(klass) {
        NEWOBJ(match);
        OBJSETUP(match, klass, T_MATCH);
        match.str = 0;
        match.regs = {
          'allocated': 0,
          'num_regs': 0,
          'beg': 0,
          'end': 0
        };
        return match;
      }
    END
  end
  
  # verbatim
  def match_array
    add_function :rb_ary_new, :rb_ary_push, :rb_str_substr
    <<-END
      function match_array(match, start) {
        var regs = match.regs;
        var ary = rb_ary_new();
        var target = match.str;
        var taint = OBJ_TAINTED(match);
        for (var i = start, l = regs.num_regs; i < l; ++i) {
          if (regs.beg[i] == -1) {
            rb_ary_push(ary, Qnil);
          } else {
            var str = rb_str_new(target.ptr.slice(regs.beg[i], regs.end[i])); // rb_str_substr(target, regs.beg[i], regs.end[i] - regs.beg[i]);
            if (taint) { OBJ_TAINT(str); }
            rb_ary_push(ary, str);
          }
        }
        return ary;
      }
    END
  end
  
  # verbatim
  def match_size
    <<-END
      function match_size(match) {
        return INT2FIX(match.regs.num_regs);
      }
    END
  end
  
  # verbatim
  def match_to_a
    add_function :match_array
    <<-END
      function match_to_a(match) {
        return match_array(match, 0);
      }
    END
  end
  
  # verbatim
  def rb_match_busy
    <<-END
      function rb_match_busy(match) {
        FL_SET(match, MATCH_BUSY);
      }
    END
  end
end
