class Red::MethodCompiler
  # modified to use simple JS RegExp constructor
  def make_regexp
    <<-END
      function make_regexp(s, len, flags) {
        return RegExp(s);
      }
    END
  end
  
  # verbatim
  def rb_reg_check
    add_function :rb_raise
    <<-END
      function rb_reg_check(re) {
        if (!re.ptr || !re.str) { rb_raise(rb_eTypeError, "uninitialized Regexp"); }
      }
    END
  end
  
  # removed kcode flags
  def rb_reg_initialize
    add_function :rb_check_frozen, :rb_raise, :make_regexp
    <<-END
      function rb_reg_initialize(obj, s, len, options) {
        var re = obj;
        if (!OBJ_TAINTED(obj) && ruby_safe_level >= 4) { rb_raise(rb_eSecurityError, "Insecure: can't modify regexp"); }
        rb_check_frozen(obj);
      //if (FL_TEST(obj, REG_LITERAL)) { rb_raise(rb_eSecurityError, "can't modify literal regexp"); }
      //if (re->ptr) { re_free_pattern(re->ptr); }
      //if (re->str) { free(re->str); }
      //if (ruby_ignorecase) { options |= RE_OPTION_IGNORECASE; FL_SET(re, REG_CASESTATE); }
        re.ptr = make_regexp(s, len, options & 0xf);
        re.str = s; // was 'memcpy(re->str, s, len)'
        re.len = len;
      //if (ruby_in_compile) { FL_SET(obj, REG_LITERAL); }
      }
    END
  end
  
  # verbatim
  def rb_reg_match
    add_function :rb_backref_set, :rb_string_value, :rb_reg_search
    <<-END
      function rb_reg_match(re, str) {
        if (NIL_P(str)) {
          rb_backref_set(Qnil);
          return Qnil;
        }
        rb_string_value(str);
        var start = rb_reg_search(re, str, 0, 0);
        if (start < 0) { return Qnil; }
        return LONG2FIX(start);
      }
    END
  end
  
  # verbatim
  def rb_reg_match_m
    add_function :rb_reg_match, :rb_backref_get, :rb_match_busy
    <<-END
      function rb_reg_match_m(re, str) {
        var result = rb_reg_match(re, str);
        if (NIL_P(result)) { return Qnil; }
        result = rb_backref_get();
        rb_match_busy(result);
        return result;
      }
    END
  end
  
  # verbatim
  def rb_reg_new
    add_function :rb_reg_initialize, :rb_reg_s_alloc
    <<-END
      function rb_reg_new(s, len, options) {
        var re = rb_reg_s_alloc(rb_cRegexp);
        rb_reg_initialize(re, s, len, options);
        return re;
      }
    END
  end
  
  # verbatim
  def rb_reg_nth_match
    add_function :rb_str_substr
    <<-END
      function rb_reg_nth_match(nth, match)
      {
        if (NIL_P(match)) { return Qnil; }
        if (nth >= match.regs.num_regs) { return Qnil; }
        if (nth < 0) {
          nth += match.regs.num_regs;
          if (nth <= 0) { return Qnil; }
        }
        var start = match.regs.beg[nth];
        if (start == -1) { return Qnil; }
        var end = match.regs.end[nth];
        var len = end - start;
        var str = rb_str_substr(match.str, start, len);
        OBJ_INFECT(str, match);
        return str;
      }
    END
  end
  
  # verbatim
  def rb_reg_s_alloc
    <<-END
      function rb_reg_s_alloc(klass) {
        NEWOBJ(re);
        OBJSETUP(re, klass, T_REGEXP);
        re.ptr = 0;
        re.len = 0;
        re.str = 0;
        return re;
      }
    END
  end
  
  # removed kcode handling
  def rb_reg_search
    add_function :rb_backref_set, :rb_reg_check, :rb_backref_get, :match_alloc, :rb_str_new, :re_search, :re_copy_registers
    <<-END
      function rb_reg_search(re, str, pos, reverse) {
        var range;
        var regs = {
          'allocated': 0,
          'num_regs': 0,
          'beg': [],
          'end': []
        };
        if ((pos > str.ptr.length) || (pos < 0)) {
          rb_backref_set(Qnil);
          return -1;
        }
        rb_reg_check(re);
      //if (may_need_recompile) { rb_reg_prepare_re(re); }
        if (reverse) {
          range = -pos;
        } else {
          range = str.ptr.length - pos;
        }
      //MEMZERO(&regs, struct re_registers, 1);
        var result = re_search(re.ptr, str.ptr, str.ptr.length, pos, range, regs);
        if (result == -2) { rb_reg_raise(re.str, re.len, "Stack overflow in regexp matcher", re); }
        if (result < 0) {
        //re_free_registers(regs);
          rb_backref_set(Qnil);
          return result;
        }
        var match = rb_backref_get();
        if (NIL_P(match) || FL_TEST(match, MATCH_BUSY)) {
          match = match_alloc(rb_cMatch);
        } else {
          if (ruby_safe_level >= 3) {
            OBJ_TAINT(match);
          } else {
            FL_UNSET(match, FL_TAINT);
          }
        }
        re_copy_registers(match.regs, regs);
      //re_free_registers(regs);
        match.str = rb_str_new(str.ptr); // was 'rb_str_new4(str)'
        rb_backref_set(match);
        OBJ_INFECT(match, re);
        OBJ_INFECT(match, str);
        return result;
      }
    END
  end
  
  # modified allocation of 'beg' and 'end'
  def re_copy_registers
    <<-END
      function re_copy_registers(regs1, regs2) {
        if (regs1 == regs2) { return; }
        if (regs1.allocated === 0) {
          regs1.beg = [];
          regs1.end = [];
        }
        regs1.allocated = regs2.num_regs;
        for (var i = 0; i < regs2.num_regs; ++i) {
          regs1.beg[i] = regs2.beg[i];
          regs1.end[i] = regs2.end[i];
        }
        regs1.num_regs = regs2.num_regs;
      }
    END
  end
  
  # CHECK: this is hacked to try to recapture the beg/end information for each capture but fails when captures are nested e.g. /(a(.)d(.))/
  def re_search
    <<-END
      function re_search(regexp, string, len, pos, range, regs) {
        var match = match_alloc(rb_cMatch);
        var ary = string.match(regexp) || [];
        var match_string = ary[0] || 0;
        if (!match_string) { return -1; }
        var pos = string.search(regexp);
        regs.beg.push(pos);
        regs.end.push(pos + match_string.length);
        regs.num_regs = 1;
        for (var offset = pos, i = 1, l = ary.length; i < l; ++i) {
          var capture_string = ary[i];
          var capture_pos = match_string.search(capture_string);
          regs.beg.push(offset + capture_pos);
          regs.end.push(offset + capture_pos + capture_string.length);
          regs.num_regs++;
          match_string = match_string.slice(capture_string.length);
          offset += capture_string.length;
        }
        rb_backref_set(match);
        return pos;
      }
    END
  end
end
