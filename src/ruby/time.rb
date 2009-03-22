class Red::MethodCompiler
  # added
  def gettimeofday
    <<-END
      function gettimeofday(tv) {
        var usec = +new(Date)();
        tv.tv_sec = Math.floor(usec / 1000);
        tv.tv_usec = (usec % 1000) * 1000;
      }
    END
  end
  
  # added
  def gmtime
    <<-END
      function gmtime(sec) {
        var d = new(Date)(sec * 1000);
        var y = d.getUTCFullYear();
        return {
          'tm_sec': d.getUTCSeconds(),
          'tm_min': d.getUTCMinutes(),
          'tm_hour': d.getUTCHours(),
          'tm_mday': d.getUTCDate(),
          'tm_mon': d.getUTCMonth(),
          'tm_year': y - 1900,
          'tm_wday': d.getUTCDay(),
          'tm_yday': Math.floor((d - (new(Date)(y, 0, 1))) / 86400000),
          'tm_isdst': 0
        };
      }
    END
  end
  
  # added, CHECK how to figure out isdst
  def localtime
    <<-END
      function localtime(sec) {
        var d = new(Date)(sec * 1000);
        var y = d.getFullYear();
        return {
          'tm_sec': d.getSeconds(),
          'tm_min': d.getMinutes(),
          'tm_hour': d.getHours(),
          'tm_mday': d.getDate(),
          'tm_mon': d.getMonth(),
          'tm_year': y - 1900,
          'tm_wday': d.getDay(),
          'tm_yday': Math.floor((d - (new(Date)(y, 0, 1))) / 86400000),
          'tm_isdst': 1
        };
      }
    END
  end
  
  # verbatim
  def time_cmp
    <<-END
      function time_cmp(time1, time2) {
        GetTimeval(time1, tobj1);
        if (TYPE(time2) == T_DATA) {
          GetTimeval(time2, tobj2);
          if (tobj1.tv.tv_sec == tobj2.tv.tv_sec) {
            if (tobj1.tv.tv_usec == tobj2.tv.tv_usec) { return INT2FIX(0); }
            if (tobj1.tv.tv_usec > tobj2.tv.tv_usec) { return INT2FIX(1); }
            return INT2FIX(-1);
          }
          if (tobj1.tv.tv_sec > tobj2.tv.tv_sec) { return INT2FIX(1); }
          return INT2FIX(-1);
        }
        return Qnil;
      }
    END
  end
  
  # verbatim
  def time_eql
    <<-END
      function time_eql(time1, time2) {
        GetTimeval(time1, tobj1);
        if (TYPE(time2) == T_DATA) {
          GetTimeval(time2, tobj2);
          if (tobj1.tv.tv_sec == tobj2.tv.tv_sec) {
            if (tobj1.tv.tv_usec == tobj2.tv.tv_usec) { return Qtrue; }
          }
        }
        return Qfalse;
      }
    END
  end
  
  # verbatim
  def time_get_tm
    add_function :time_gmtime, :time_localtime
    <<-END
      function time_get_tm(time, gmt) {
        if (gmt) { return time_gmtime(time); }
        return time_localtime(time);
      }
    END
  end
  
  # verbatim
  def time_gmtime
    add_function :gmtime
    <<-END
      function time_gmtime(time) {
        GetTimeval(time, tobj);
        if (tobj.gmt) {
          if (tobj.tm_got) { return time; }
        } else {
          time_modify(time);
        }
        var t = tobj.tv.tv_sec;
        var tm_tmp = gmtime(t);
        if (!tm_tmp) { rb_raise(rb_eArgError, "gmtime error"); }
        tobj.tm = tm_tmp;
        tobj.tm_got = 1;
        tobj.gmt = 1;
        return time;
      }
    END
  end
  
  # verbatim
  def time_hash
    <<-END
      function time_hash(time) {
        GetTimeval(time, tobj);
        var hash = tobj.tv.tv_sec ^ tobj.tv.tv_usec;
        return LONG2FIX(hash);
      }
    END
  end
  
  # removed 'rb_sys_fail' error check
  def time_init
    add_function :time_modify, :gettimeofday
    <<-END
      function time_init(time) {
        time_modify(time);
        GetTimeval(time, tobj);
        tobj.tm_got = 0;
        gettimeofday(tobj.tv);
        return time;
      }
    END
  end
  
  # verbatim
  def time_localtime
    add_function :time_modify, :rb_raise, :localtime
    <<-END
      function time_localtime(time) {
        GetTimeval(time, tobj);
        if (!tobj.gmt) {
          if (tobj.tm_got) { return time; }
        } else {
          time_modify(time);
        }
        var t = tobj.tv.tv_sec;
        var tm_tmp = localtime(t);
        if (!tm_tmp) { rb_raise(rb_eArgError, "localtime error"); }
        tobj.tm = tm_tmp;
        tobj.tm_got = 1;
        tobj.gmt = 0;
        return time;
      }
    END
  end
  
  # verbatim
  def time_modify
    add_function :rb_check_frozen, :rb_raise
    <<-END
      function time_modify(time) {
        rb_check_frozen(time);
        if (!OBJ_TAINTED(time) && ruby_safe_level >= 4) { rb_raise(rb_eSecurityError, "Insecure: can't modify Time"); }
      }
    END
  end
  
  # expanded "Data_Make_Struct"
  def time_s_alloc
    <<-END
      function time_s_alloc(klass) {
        var tobj = {'tm':{},'tv':{},'gmt':0};
        var obj = rb_data_object_alloc(klass, tobj);
        tobj.tm_got = 0;
        tobj.tv.tv_sec = 0;
        tobj.tv.tv_usec = 0;
        return obj;
      }
    END
  end
  
  # verbatim
  def time_to_a
    add_function :time_get_tm, :rb_ary_new3, :time_zone
    <<-END
      function time_to_a(time) {
        GetTimeval(time, tobj);
        if (tobj.tm_got === 0) { time_get_tm(time, tobj.gmt); }
        return rb_ary_new3(10, INT2FIX(tobj.tm.tm_sec), INT2FIX(tobj.tm.tm_min), INT2FIX(tobj.tm.tm_hour), INT2FIX(tobj.tm.tm_mday), INT2FIX(tobj.tm.tm_mon+1), LONG2NUM(tobj.tm.tm_year + 1900), INT2FIX(tobj.tm.tm_wday), INT2FIX(tobj.tm.tm_yday + 1), tobj.tm.tm_isdst ? Qtrue : Qfalse, time_zone(time));
      }
    END
  end
  
  # verbatim
  def time_to_f
    add_function :rb_float_new
    <<-END
      function time_to_f(time) {
        GetTimeval(time, tobj);
        return rb_float_new(tobj.tv.tv_sec + (tobj.tv.tv_usec / 1e6));
      }
    END
  end
  
  # verbatim
  def time_to_i
    <<-END
      function time_to_i(time) {
        GetTimeval(time, tobj);
        return LONG2NUM(tobj.tv.tv_sec);
      }
    END
  end
  
  # CHECK; WRONG
  def time_zone
    <<-END
      function time_zone(time) {
        GetTimeval(time, tobj);
        if (tobj.tm_got === 0) { time_get_tm(time, tobj.gmt); }
        if (tobj.gmt == 1) { return rb_str_new("UTC"); }
        return rb_str_new("XXX");
      }
    END
  end
end
