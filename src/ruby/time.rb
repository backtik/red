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
        var i;
        var s = '';
        var days_a = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
        var days_l = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];
        var months_a = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
        var months_l = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];
        var ampm = ["AM", "PM"];
        if (!format || !timeptr) { return ''; }
        if (format.indexOf('%') < 0) { return format; }
        for (fp = 0; format[fp]; fp++) {
          if (format[fp] != '%') {
            s += format[fp];
            continue;
          }
          switch (format[++fp]) {
            case 'undefined':
              s += '%';
              return s;
            case '%':
              s += '%';
              continue;
            case 'a': /* abbreviated weekday name */
              s += days_a[timeptr.tm_wday] || '?';
              break;
            case 'A': /* full weekday name */
              s += days_l[timeptr.tm_wday] || '?';
              break;
            case 'h': /* abbreviated month name */
            case 'b': /* abbreviated month name */
              s += months_a[timeptr.tm_mon] || '?';
              break;
            case 'B': /* full month name */
              s += months_l[timeptr.tm_mon] || '?';
              break;
            case 'c': /* appropriate date and time representation */
              s += jstrftime("%a %b %e %H:%M:%S %Y", timeptr);
              break;
            case 'd': /* day of the month, 01 - 31 */
              s += jsprintf("%02d", [range(1, timeptr.tm_mday, 31)]);
              break;
            case 'H': /* hour, 24-hour clock, 00 - 23 */
              s += jsprintf("%02d", [range(0, timeptr.tm_hour, 23)]);
              break;
            case 'I': /* hour, 12-hour clock, 01 - 12 */
              i = range(0, timeptr.tm_hour, 23);
              i = (i === 0) ? 12 : (i > 12) ? i - 12 : i;
              s += jsprintf("%02d", [i]);
              break;
            case 'j': /* day of the year, 001 - 366 */
              s += jsprintf("%03d", [timeptr.tm_yday + 1]);
              break;
            case 'm': /* month, 01 - 12 */
              i = range(0, timeptr.tm_mon, 11);
              s += jsprintf("%02d", [i + 1]);
              break;
            case 'M': /* minute, 00 - 59 */
              s += jsprintf("%02d", [range(0, timeptr.tm_min, 59)]);
              break;
            case 'p': /* am or pm based on 12-hour clock */
              i = range(0, timeptr.tm_hour, 23);
              s += ampm[(i < 12) ? 0 : 1];
              break;
            case 'S': /* second, 00 - 60 */
              s += jsprintf("%02d", [range(0, timeptr.tm_sec, 60)]);
              break;
            case 'U': /* week of year, Sunday is first day of week */
              s += jsprintf("%02d", [weeknumber(timeptr, 0)]);
              break;
            case 'w': /* weekday, Sunday == 0, 0 - 6 */
              s += jsprintf("%d", [range(0, timeptr.tm_wday, 6)]);
              break;
            case 'W': /* week of year, Monday is first day of week */
              s += jsprintf("%02d", [weeknumber(timeptr, 1)]);
              break;
            case 'x': /* appropriate date representation */
              s += jstrftime("%m/%d/%y", timeptr);
              break;
            case 'X': /* appropriate time representation */
              s += jstrftime("%H:%M:%S", timeptr);
              break;
            case 'y': /* year without a century, 00 - 99 */
              s += jsprintf("%02d", [timeptr.tm_year % 100]);
              break;
            case 'Y': /* year with century */
              s += jsprintf("%d", [1900 + timeptr.tm_year]);
              break;
            default:
              s += '%' + format[fp];
              break;
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
