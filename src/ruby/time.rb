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
          'tm_wday': d.getUTCDay(),
          'tm_mday': d.getUTCDate(),
          'tm_mon': d.getUTCMonth(),
          'tm_yday': Math.floor((d - (new(Date)(y, 0, 1))) / 86400000),
          'tm_year': y - 1900,
          'tm_isdst': 0
        };
      }
    END
  end
  
  # modified string handling, CHECK: missing %Z format
  def jstrftime
    <<-END
      function jstrftime(format, timeptr) {
        if (!format || !timeptr) { return ''; }
        if (format.indexOf('%') < 0) { return format; }
        for (var s = '', fp = 0; format[fp]; fp++) {
          if (format[fp] != '%') {
            s += format[fp];
            continue;
          }
          switch (format[++fp]) {
            case 'undefined':
              s += '%'; return s;
            case '%':
              s += '%'; continue;
            case 'a': /* abbreviated weekday name */
              s += ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"][timeptr.tm_wday] || '?'; break;
            case 'A': /* full weekday name */
              s += ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"][timeptr.tm_wday] || '?'; break;
            case 'b': /* abbreviated month name */
              s += ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"][timeptr.tm_mon] || '?'; break;
            case 'B': /* full month name */
              s += ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"][timeptr.tm_mon] || '?'; break;
            case 'c': /* appropriate date and time representation */
              s += jstrftime("%a %b %e %H:%M:%S %Y", timeptr); break;
            case 'd': /* day of the month, 01 - 31 */
              s += jsprintf("%02d", [range(1, timeptr.tm_mday, 31)]); break;
            case 'e':	/* day of month, blank padded */
              s += jsprintf("%2d", [range(1, timeptr.tm_mday, 31)]); break;
            case 'H': /* hour, 24-hour clock, 00 - 23 */
              s += jsprintf("%02d", [range(0, timeptr.tm_hour, 23)]); break;
            case 'I': /* hour, 12-hour clock, 01 - 12 */
              var h = range(0, timeptr.tm_hour, 23);
              h = (h === 0) ? 12 : (h > 12) ? h - 12 : h;
              s += jsprintf("%02d", [h]);
              break;
            case 'j': /* day of the year, 001 - 366 */
              s += jsprintf("%03d", [timeptr.tm_yday + 1]); break;
            case 'm': /* month, 01 - 12 */
              s += jsprintf("%02d", [range(0, timeptr.tm_mon, 11) + 1]); break;
            case 'M': /* minute, 00 - 59 */
              s += jsprintf("%02d", [range(0, timeptr.tm_min, 59)]); break;
            case 'p': /* am or pm based on 12-hour clock */
              s += (range(0, timeptr.tm_hour, 23) < 12) ? "AM" : "PM"; break;
            case 'S': /* second, 00 - 60 */
              s += jsprintf("%02d", [range(0, timeptr.tm_sec, 60)]); break;
            case 'U': /* week of year, Sunday is first day of week */
              s += jsprintf("%02d", [weeknumber(timeptr, 0)]); break;
            case 'w': /* weekday, Sunday == 0, 0 - 6 */
              s += jsprintf("%d", [range(0, timeptr.tm_wday, 6)]); break;
            case 'W': /* week of year, Monday is first day of week */
              s += jsprintf("%02d", [weeknumber(timeptr, 1)]); break;
            case 'x': /* appropriate date representation */
              s += jstrftime("%m/%d/%y", timeptr); break;
            case 'X': /* appropriate time representation */
              s += jstrftime("%H:%M:%S", timeptr); break;
            case 'y': /* year without a century, 00 - 99 */
              s += jsprintf("%02d", [timeptr.tm_year % 100]); break;
            case 'Y': /* year with century */
              s += jsprintf("%d", [1900 + timeptr.tm_year]); break;
            default:
              s += '%' + format[fp]; break;
          }
        }
        return s;
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
          'tm_wday': d.getDay(),
          'tm_mday': d.getDate(),
          'tm_mon': d.getMonth(),
          'tm_yday': Math.floor((d - (new(Date)(y, 0, 1))) / 86400000),
          'tm_year': y - 1900,
          'tm_isdst': 1
        };
      }
    END
  end
  
  # added
  def rb_time_data
    add_function :time_get_tm
    <<-END
      function rb_time_data(time, name, offset) {
        GetTimeval(time, tobj);
        if (tobj.tm_got == 0) { time_get_tm(time, tobj.gmt); }
        return INT2FIX((tobj.tm['tm_' + name] || 0) + (offset || 0));
      }
    END
  end
  
  # verbatim
  def rb_time_new
    add_function :time_new_internal
    <<-END
      function rb_time_new(sec, usec) {
        return time_new_internal(rb_cTime, sec, usec);
      }
    END
  end
  
  # removed check against 'time_free' function
  def rb_time_timeval
    add_function :time_timeval
    <<-END
      function rb_time_timeval(time) {
        if (TYPE(time) == T_DATA) {
          GetTimeval(time, tobj);
          var t = tobj.tv;
          return t;
        }
        return time_timeval(time, Qfalse);
      }
    END
  end
  
  # verbatim
  def time_add
    add_function :modf, :rb_raise, :rb_time_new, :rb_num2dbl
    <<-END
      function time_add(tobj, offset, sign) {
        var sec;
        var v = NUM2DBL(offset);
        if (v < 0) {
          v = -v;
          sign = -sign;
        }
        var tmp = modf(v);
        var d = tmp[0];
        var sec_off = tmp[1];
        if (tmp[1] != /* (double) */ sec_off) { rb_raise(rb_eRangeError, "time %s %f out of Time range", sign < 0 ? "-" : "+", v); }
        var usec_off = (d * 1e6) + 0.5;
        if (sign < 0) {
          sec = tobj.tv.tv_sec - sec_off;
          usec = tobj.tv.tv_usec - usec_off;
          if (sec > tobj.tv.tv_sec) { rb_raise(rb_eRangeError, "time - %f out of Time range", v); }
        } else {
          sec = tobj.tv.tv_sec + sec_off;
          usec = tobj.tv.tv_usec + usec_off;
          if (sec < tobj.tv.tv_sec) { rb_raise(rb_eRangeError, "time + %f out of Time range", v); }
        }
        var result = rb_time_new(sec, usec);
        if (tobj.gmt) {
          GetTimeval(result, tobj);
          tobj.gmt = 1;
        }
        return result;
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
  def time_dup
    add_function :time_s_alloc, :time_init_copy
    <<-END
      function time_dup(time) {
        var dup = time_s_alloc(CLASS_OF(time));
        time_init_copy(dup, time);
        return dup;
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
  def time_getgmtime
    add_function :time_gmtime, :time_dup
    <<-END
      function time_getgmtime(time) {
        return time_gmtime(time_dup(time));
      }
    END
  end
  
  # verbatim
  def time_getlocaltime
    add_function :time_localtime, :time_dup
    <<-END
      function time_getlocaltime(time) {
        return time_localtime(time_dup(time));
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
  
  # modified to use 'rb_time_data'
  def time_hour
    add_function :rb_time_data
    <<-END
      function time_hour(time) {
        return rb_time_data(time, 'hour');
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
  
  # CHECK MEMCPY HERE
  def time_init_copy
    add_function :time_modify, :rb_raise
    <<-END
      function time_init_copy(copy, time) {
        if (copy == time) { return copy; }
        time_modify(copy);
        if ((TYPE(time) != T_DATA)) { rb_raise(rb_eTypeError, "wrong argument type"); }
        GetTimeval(time, tobj);
        GetTimeval(copy, tcopy);
        MEMCPY(tcopy, tobj, 1);
        return copy;
      }
    END
  end
  
  # verbatim
  def time_isdst
    add_function :time_get_tm
    <<-END
      function time_isdst(time) {
        GetTimeval(time, tobj);
        if (tobj.tm_got === 0) { time_get_tm(time, tobj.gmt); }
        return tobj.tm.tm_isdst ? Qtrue : Qfalse;
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
  
  # modified to use 'rb_time_data'
  def time_mday
    add_function :rb_time_data
    <<-END
      function time_mday(time) {
        return rb_time_data(time, 'mday');
      }
    END
  end
  
  # modified to use 'rb_time_data'
  def time_min
    add_function :rb_time_data
    <<-END
      function time_min(time) {
        return rb_time_data(time, 'min');
      }
    END
  end
  
  # verbatim
  def time_minus
    add_function :rb_float_new, :time_add
    <<-END
      function time_minus(time1, time2) {
        GetTimeval(time1, tobj);
        if (TYPE(time2) == T_DATA) {
          GetTimeval(time2, tobj2);
          var f = tobj.tv.tv_sec - tobj2.tv.tv_sec;
          f += (tobj.tv.tv_usec - tobj2.tv.tv_usec) * 1e-6;
          return rb_float_new(f);
        }
        return time_add(tobj, time2, -1);
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
  
  # modified to use 'rb_time_data'
  def time_mon
    add_function :rb_time_data
    <<-END
      function time_mon(time) {
        return rb_time_data(time, 'mon', 1);
      }
    END
  end
  
  # verbatim
  def time_new_internal
    add_function :time_overflow_p
    <<-END
      function time_new_internal(klass, sec, usec) {
        var time = time_s_alloc(klass);
        GetTimeval(time, tobj);
        var tmp = [sec, usec];
        time_overflow_p(tmp);
        tobj.tv.tv_sec = tmp[0];
        tobj.tv.tv_usec = tmp[1];
        return time;
      }
    END
  end
  
  # verbatim
  def time_overflow_p
    <<-END
      function time_overflow_p(ary)
      {
        var tmp;
        var sec = ary[0];
        var usec = ary[1];
        if (usec >= 1000000) { /* usec positive overflow */
          tmp = sec + usec / 1000000;
          usec %= 1000000;
          if (sec > 0 && tmp < 0) { rb_raise(rb_eRangeError, "out of Time range"); }
          sec = tmp;
        }
        if (usec < 0) { /* usec negative overflow */
          tmp = sec + (-(-(usec + 1) / 1000000) - 1); /* negative div */
          usec = (1000000 - (-(usec + 1) % 1000000) - 1); /* negative mod */
          if (sec < 0 && tmp > 0) { rb_raise(rb_eRangeError, "out of Time range"); }
          sec = tmp;
        }
        ary[0] = sec;
        ary[1] = usec;
      }
    END
  end
  
  # verbatim
  def time_plus
    add_function :time_add, :rb_raise
    <<-END
      function time_plus(time1, time2) {
        GetTimeval(time1, tobj);
        if (TYPE(time2) == T_DATA) { rb_raise(rb_eTypeError, "time + time?"); }
        return time_add(tobj, time2, 1);
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
  
  # removed check against 'time_free' function
  def time_s_at
    add_function :rb_time_timeval, :time_new_internal, :rb_scan_args
    <<-END
      function time_s_at(argc, argv, klass) {
        var tv = {};
        var tmp = rb_scan_args(argc, argv, '11');
        var time = tmp[1];
        var t = tmp[2];
        if (tmp[0] == 2) {
          tv.tv_sec = NUM2LONG(time);
          tv.tv_usec = NUM2LONG(t);
        } else {
          tv = rb_time_timeval(time);
        }
        t = time_new_internal(klass, tv.tv_sec, tv.tv_usec);
        if (TYPE(time) == T_DATA) {
          GetTimeval(time, tobj);
          GetTimeval(t, tobj2);
          tobj2.gmt = tobj.gmt;
        }
        return t;
      }
    END
  end
  
  # verbatim
  def time_s_mktime
    add_function :time_utc_or_local
    <<-END
      function time_s_mktime(argc, argv, klass) {
        return time_utc_or_local(argc, argv, Qfalse, klass);
      }
    END
  end
  
  # verbatim
  def time_s_mkutc
    add_function :time_utc_or_local
    <<-END
      function time_s_mkutc(argc, argv, klass) {
        return time_utc_or_local(argc, argv, Qtrue, klass);
      }
    END
  end
  
  # modified to use 'rb_time_data'
  def time_sec
    add_function :rb_time_data
    <<-END
      function time_sec(time) {
        return rb_time_data(time, 'sec');
      }
    END
  end
  
  # modified string handling, using jstrftime instead of rb_strftime
  def time_strftime
    <<-END
      function time_strftime(time, format) {
        GetTimeval(time, tobj);
        if (tobj.tm_got === 0) { time_get_tm(time, tobj.gmt); }
        rb_string_value(format);
      //removed rb_str_new4
        return rb_str_new(jstrftime(format.ptr, tobj.tm));
      }
    END
  end
  
  # verbatim
  def time_succ
    add_function :rb_time_new
    <<-END
      function time_succ(time) {
        GetTimeval(time, tobj);
        var gmt = tobj.gmt;
        time = rb_time_new(tobj.tv.tv_sec + 1, tobj.tv.tv_usec);
        GetTimeval(time, tobj);
        tobj.gmt = gmt;
        return time;
      }
    END
  end
  
  # expanded modf
  def time_timeval
    add_function :rb_raise, :modf, :rb_obj_classname
    <<-END
      function time_timeval(time, interval) {
        var t = {};
        var tstr = interval ? "time interval" : "time";
        switch (TYPE(time)) {
          case T_FIXNUM:
            t.tv_sec = FIX2LONG(time);
            if (interval && (t.tv_sec < 0)) { rb_raise(rb_eArgError, "%s must be positive", tstr); }
            t.tv_usec = 0;
            break;
          case T_FLOAT:
            if (interval && (time.value < 0.0)) {
              rb_raise(rb_eArgError, "%s must be positive", tstr);
            } else {
              var tmp = modf(time.value);
              var d = tmp[0];
              var f = tmp[1];
              if (d < 0) {
                d += 1;
                f -= 1;
              }
              t.tv_sec = f;
              if (f != t.tv_sec) { rb_raise(rb_eRangeError, "%f out of Time range", time.value); }
              t.tv_usec = d * 1e6 + 0.5;
            }
            break;
          case T_BIGNUM:
            t.tv_sec = NUM2LONG(time);
            if (interval && (t.tv_sec < 0)) { rb_raise(rb_eArgError, "%s must be positive", tstr); }
            t.tv_usec = 0;
            break;
          default:
            rb_raise(rb_eTypeError, "can't convert %s into %s", rb_obj_classname(time), tstr);
            break;
        }
        return t;
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
  
  # modified string handling, changed to use jsprintf and jstrftime
  def time_to_s
    add_function :time_get_tm, :time_utc_offset, :jstrftime
    <<-END
      function time_to_s(time) {
        var str;
        GetTimeval(time, tobj);
        if (tobj.tm_got === 0) { time_get_tm(time, tobj.gmt); }
        if (tobj.gmt == 1) {
          str = jstrftime("%a %b %d %H:%M:%S UTC %Y", tobj.tm);
        } else {
          var sign = '+';
          var tmp = time_utc_offset(time);
          var off = NUM2INT(tmp);
          if (off < 0) {
            sign = '-';
            off = -off;
          }
          var str2 = jsprintf("%%a %%b %%d %%H:%%M:%%S %s%02d%02d %%Y", [sign, off / 3600, off % 3600 / 60]);
          str = jstrftime(str2, tobj.tm);
        }
        return rb_str_new(str);
      }
    END
  end
  
  # verbatim
  def time_usec
    <<-END
      function time_usec(time) {
        GetTimeval(time, tobj);
        return LONG2NUM(tobj.tv.tv_usec);
      }
    END
  end
  
  # verbatim
  def time_utc_offset
    add_function :time_get_tm, :gmtime, :rb_raise
    <<-END
      function time_utc_offset(time) {
        GetTimeval(time, tobj);
        if (tobj.tm_got === 0) { time_get_tm(time, tobj.gmt); }
        if (tobj.gmt == 1) {
          return INT2FIX(0);
        } else {
          var off;
          var l = tobj.tm;
          var t = tobj.tv.tv_sec;
          var u = gmtime(t);
          if (!u) { rb_raise(rb_eArgError, "gmtime error"); }
          if (l.tm_year != u.tm_year) {
            off = (l.tm_year < u.tm_year) ? -1 : 1;
          } else if (l.tm_mon != u.tm_mon) {
            off = (l.tm_mon < u.tm_mon) ? -1 : 1;
          } else if (l.tm_mday != u.tm_mday) {
            off = (l.tm_mday < u.tm_mday) ? -1 : 1;
          } else {
            off = 0;
          }
          off = (off * 24) + l.tm_hour - u.tm_hour;
          off = (off * 60) + l.tm_min - u.tm_min;
          off = (off * 60) + l.tm_sec - u.tm_sec;
          return LONG2FIX(off);
        }
      }
    END
  end
  
  # verbatim
  def time_utc_p
    <<-END
      function time_utc_p(time) {
        GetTimeval(time, tobj);
        return (tobj.gmt) ? Qtrue : Qfalse;
      }
    END
  end
  
  # modified to use 'rb_time_data'
  def time_wday
    add_function :rb_time_data
    <<-END
      function time_wday(time) {
        return rb_time_data(time, 'wday');
      }
    END
  end
  
  # modified to use 'rb_time_data'
  def time_yday
    add_function :rb_time_data
    <<-END
      function time_yday(time) {
        return rb_time_data(time, 'yday', 1);
      }
    END
  end
  
  # modified to use 'rb_time_data'
  def time_year
    add_function :rb_time_data
    <<-END
      function time_year(time) {
        return rb_time_data(time, 'year', 1900);
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
  
  # verbatim
  def weeknumber
    <<-END
      function weeknumber(timeptr, firstweekday) {
        var wday = timeptr.tm_wday;
        if (firstweekday == 1) { wday = (wday === 0) ? 6 : wday - 1; }
        var ret = (timeptr.tm_yday + 7 - wday) / 7;
        return (ret < 0) ? 0 : ret;
      }
    END
  end
end
