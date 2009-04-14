class Red::MethodCompiler
  # verbatim
  def boot_defclass
    add_function :rb_class_boot, :rb_name_class, :rb_const_set
    <<-END
      function boot_defclass(name, superclass) {
        var obj = rb_class_boot(superclass);
        var id = rb_intern(name);
        rb_name_class(obj, id);
        rb_class_tbl[id] = obj; // was st_add_direct
        rb_const_set((rb_cObject ? rb_cObject : obj), id, obj);
        return obj;
      }
    END
  end
  
  def Init_accessors
    add_function :rb_define_class
    <<-END
      function Init_accessors() {
        rb_cClasses = rb_define_class('Classes', rb_cObject);
        rb_cProperties = rb_define_class('Properties', rb_cObject);
        rb_cStyles = rb_define_class('Styles', rb_cObject);
      }
    END
  end
  
  # verbatim
  def Init_Array
    $mc.add_function :rb_define_class, :rb_include_module,
                     :rb_define_alloc_func
    <<-END
      function Init_Array() {
        rb_cArray = rb_define_class('Array', rb_cObject);
        rb_include_module(rb_cArray, rb_mEnumerable);
        rb_define_alloc_func(rb_cArray, ary_alloc);
      }
    END
  end
  
  # verbatim
  def Init_Bignum
    add_function :rb_define_class
    <<-END
      function Init_Bignum() {
        rb_cBignum = rb_define_class('Bignum', rb_cInteger);
      }
    END
  end
  
  # verbatim
  def Init_Binding
    add_function :rb_define_class, :rb_undef_alloc_func, :rb_undef_method
    <<-END
      function Init_Binding() {
        rb_cBinding = rb_define_class('Binding', rb_cObject);
        rb_undef_alloc_func(rb_cBinding);
        rb_undef_method(CLASS_OF(rb_cBinding), 'new');
      }
    END
  end
  
  # pulled verbatim from Init_Object
  def Init_boot
    add_function :boot_defclass, :rb_make_metaclass, :rb_define_private_method
    <<-END
      function Init_boot() {
        var metaclass;
        rb_cObject = boot_defclass('Object', 0);
        rb_cModule = boot_defclass('Module', rb_cObject);
        rb_cClass  = boot_defclass('Class',  rb_cModule);
        metaclass = rb_make_metaclass(rb_cObject, rb_cClass);
        metaclass = rb_make_metaclass(rb_cModule, metaclass);
        metaclass = rb_make_metaclass(rb_cClass, metaclass);
        rb_define_private_method(rb_cClass, 'inherited', rb_obj_dummy, 1);
      }
    END
  end
  
  # 
  def Init_Browser
    add_function :rb_define_module, :rb_init_engine
    <<-END
      function Init_Browser() {
        rb_mBrowser = rb_define_module('Browser');
        ruby_air   = (window.runtime) ? Qtrue : Qfalse;
        ruby_platform = rb_str_new((typeof(window.orientation) == 'undefined') ? (navigator.platform.match(/mac|win|linux/i) || ['other'])[0].toLowerCase() : 'ipod');
        ruby_query = (document.querySelector) ? Qtrue : Qfalse;
        ruby_xpath = (document.evaluate) ? Qtrue : Qfalse;
        rb_init_engine();
      }
    END
  end
  
  # pulled from Init_Object
  def Init_Class
    add_function :rb_define_alloc_func, :rb_class_s_alloc, :rb_undef_method
    <<-END
      function Init_Class() {
        rb_define_alloc_func(rb_cClass, rb_class_s_alloc);
        rb_undef_method(rb_cClass, 'extend_object');
        rb_undef_method(rb_cClass, 'append_features');
      }
    END
  end
  
  # 
  def Init_CodeEvent
    <<-END
      function Init_CodeEvent() {
        rb_mCodeEvent = rb_define_module('CodeEvent');
      }
    END
  end
  
  # CHECK
  def Init_Comparable
    add_function :rb_define_module
    <<-END
      function Init_Comparable() {
        rb_mComparable = rb_define_module('Comparable');
      }
    END
  end
  
  # verbatim
  def Init_Data
    add_function :rb_define_class, :rb_undef_alloc_func
    <<-END
      function Init_Data() {
        rb_cData = rb_define_class('Data', rb_cObject);
        rb_undef_alloc_func(rb_cData);
      }
    END
  end
  
  # 
  def Init_Document
    add_function :rb_define_module
    <<-END
      function Init_Document() {
        rb_mDocument = rb_define_module('Document');
        rb_mWindow = rb_mDocument;
        rb_const_set(rb_cObject, rb_intern('Window'), rb_mDocument);
        document.head = document.getElementsByTagName('head')[0];
        document.html = document.getElementsByTagName('html')[0];
        document.window = document.defaultView || document.parentWindow;
      }
    END
  end
  
  # need to move method defs to class << Ruby
  def Init_Element
    add_function :rb_define_class, :rb_include_module
    <<-END
      function Init_Element() {
        rb_cElement = rb_define_class('Element', rb_cObject);
        rb_include_module(rb_cElement, rb_mUserEvent);
        rb_include_module(rb_cElement, rb_mCodeEvent);
      }
    END
  end
  
  # verbatim
  def Init_Enumerable
    add_function :rb_define_module
    <<-END
      function Init_Enumerable() {
        rb_mEnumerable = rb_define_module('Enumerable');
      }
    END
  end
  
  # removed 'rb_provide('enumerator.so')'
  def Init_Enumerator
    add_function :rb_define_class_under, :rb_include_module, :rb_define_alloc_func, :rb_define_class, :rb_intern, :enumerator_allocate
    <<-END
      function Init_Enumerator() {
        rb_cEnumerator = rb_define_class_under(rb_mEnumerable, 'Enumerator', rb_cObject);
        rb_include_module(rb_cEnumerator, rb_mEnumerable);
        rb_define_alloc_func(rb_cEnumerator, enumerator_allocate);
        rb_eStopIteration = rb_define_class('StopIteration', rb_eIndexError);
        sym_each = ID2SYM(rb_intern('each'));
      }
    END
  end
  
  # CHECK
  def Init_eval
    add_function :rb_define_virtual_variable, :rb_define_hooked_variable,
                 :rb_define_global_function, :rb_method_node,
                 :errinfo_setter, :errat_getter, :errat_setter,
                 :rb_undef_method#, :safe_getter, :safe_setter
    <<-END
      function Init_eval() {
        rb_define_virtual_variable('$@', errat_getter, errat_setter);
        rb_define_hooked_variable('$!', ruby_errinfo, 0, errinfo_setter);
        basic_respond_to = rb_method_node(rb_cObject, respond_to);
        rb_undef_method(rb_cClass, 'module_function');
      //rb_define_virtual_variable('$SAFE', safe_getter, safe_setter);
      }
    END
  end
  
  # 
  def Init_Event
    <<-END
      function Init_Event() {
        rb_cEvent = rb_define_class('Event', rb_cObject);
        rb_undef_method(CLASS_OF(rb_cEvent), 'new');
        sym_x = ID2SYM(rb_intern('x'));
        sym_y = ID2SYM(rb_intern('y'));
      }
    END
  end
  
  # verbatim
  def Init_Exception
    $mc.add_function :rb_define_class, :rb_define_module
    <<-END
      function Init_Exception() {
        rb_eException = rb_define_class('Exception', rb_cObject);
        rb_eSystemExit  = rb_define_class('SystemExit', rb_eException);
        rb_eFatal       = rb_define_class('fatal', rb_eException);
        rb_eSignal      = rb_define_class('SignalException', rb_eException);
        rb_eInterrupt   = rb_define_class('Interrupt', rb_eSignal);
        rb_eStandardError = rb_define_class('StandardError', rb_eException);
        rb_eTypeError     = rb_define_class('TypeError', rb_eStandardError);
        rb_eArgError      = rb_define_class('ArgumentError', rb_eStandardError);
        rb_eIndexError    = rb_define_class('IndexError', rb_eStandardError);
        rb_eRangeError    = rb_define_class('RangeError', rb_eStandardError);
        rb_eNameError     = rb_define_class('NameError', rb_eStandardError);
        rb_cNameErrorMesg = rb_define_class_under(rb_eNameError, 'message', rb_cData);
        rb_eNoMethodError = rb_define_class('NoMethodError', rb_eNameError);
        rb_eScriptError = rb_define_class('ScriptError', rb_eException);
        rb_eSyntaxError = rb_define_class('SyntaxError', rb_eScriptError);
        rb_eLoadError   = rb_define_class('LoadError', rb_eScriptError);
        rb_eNotImpError = rb_define_class('NotImplementedError', rb_eScriptError);
        rb_eRuntimeError = rb_define_class('RuntimeError', rb_eStandardError);
        rb_eSecurityError = rb_define_class('SecurityError', rb_eStandardError);
        rb_eNoMemError = rb_define_class('NoMemoryError', rb_eException);
        syserr_tbl = {}; // was st_init_numtable
        rb_eSystemCallError = rb_define_class('SystemCallError', rb_eStandardError);
        rb_mErrno = rb_define_module('Errno');
      }
    END
  end
  
  # pulled from Init_Object
  def Init_FalseClass
    add_function :rb_define_class, :rb_undef_alloc_func, :rb_undef_method, :rb_define_global_const
    <<-END
      function Init_FalseClass() {
        rb_cFalseClass = rb_define_class('FalseClass', rb_cObject);
        rb_undef_alloc_func(rb_cFalseClass);
        rb_undef_method(CLASS_OF(rb_cFalseClass), 'new');
        rb_define_global_const('FALSE', Qfalse);
      }
    END
  end
  
  # moved id definitions to init_ids, removed 'envtable' stuff
  def Init_Hash
    add_function :rb_define_class, :rb_include_module,
                 :rb_define_alloc_func,
                 :rb_define_global_const, :hash_alloc
    <<-END
      function Init_Hash() {
        rb_cHash = rb_define_class('Hash', rb_cObject);
        rb_include_module(rb_cHash, rb_mEnumerable);
        rb_define_alloc_func(rb_cHash, hash_alloc);
      }
    END
  end
  
  # pulled from various sources
  def Init_ids
    add_function :rb_intern
    <<-END
      function Init_ids() {
        autoload      = rb_intern('__autoload__');
        classpath     = rb_intern('__classpath__');
        tmp_classpath = rb_intern('__tmp_classpath__');
        inspect_key   = rb_intern('__inspect_key__');
        
        missing    = rb_intern('method_missing');
        respond_to = rb_intern('respond_to?');
        init       = rb_intern('initialize');
        bt         = rb_intern('backtrace');
        
        id_coerce    = rb_intern('coerce');
        id_to_s      = rb_intern('to_s');
        id_to_i      = rb_intern('to_i');
        id_eq        = rb_intern('==');
        id_eql       = rb_intern('eql?');
        id_eqq       = rb_intern('===');
        id_inspect   = rb_intern('inspect');
        id_init_copy = rb_intern('initialize_copy');
        id_hash      = rb_intern('hash');
        id_call      = rb_intern('call');
        id_default   = rb_intern('default');
        id_write     = rb_intern('write');
        id_read      = rb_intern('read');
        id_getc      = rb_intern('getc');
        id_top       = rb_intern('top');
        id_bottom    = rb_intern('bottom');
        id_inside    = rb_intern('inside');
        id_after     = rb_intern('after');
        id_before    = rb_intern('before');
        id_fire      = rb_intern('fire');
        
        each  = rb_intern('each');
        eqq   = rb_intern('===');
        aref  = rb_intern('[]');
        aset  = rb_intern('[]=');
        match = rb_intern('=~');
        cmp   = rb_intern('<=>');
        
        prc_pr = rb_intern('prec');
        prc_if = rb_intern('induced_from');
        
        id_cmp  = rb_intern('<=>');
        id_each = rb_intern('each');
        id_succ = rb_intern('succ');
        id_beg  = rb_intern('begin');
        id_end  = rb_intern('end');
        id_excl = rb_intern('excl');
        id_size = rb_intern('size');
        
        added               = rb_intern('method_added');
        singleton_added     = rb_intern('singleton_method_added');
        removed             = rb_intern('method_removed');
        singleton_removed   = rb_intern('singleton_method_removed');
        id_undefined        = rb_intern('method_undefined');
        singleton_undefined = rb_intern('singleton_method_undefined');
        
        __id__   = rb_intern('__id__');
        __send__ = rb_intern('__send__');
      }
    END
  end
  
  # need to decide which methods to implement and which to scrap
  def Init_IO
    add_function :rb_define_class, :rb_define_global_const,
                 :rb_include_module, :rb_f_puts, :io_alloc, :rb_io_s_new,
                 :rb_io_initialize, :rb_str_new, :rb_io_puts, :prep_stdio,
                 :rb_str_setter, :lineno_setter
    <<-END
      function Init_IO() {
        CONSOLE_LOG_BUFFER = '';
        
        rb_eIOError = rb_define_class('IOError', rb_eStandardError);
        rb_eEOFError = rb_define_class('EOFError', rb_eIOError);
        
      //rb_define_global_function('syscall', rb_f_syscall, -1);
      
      //rb_define_global_function('open', rb_f_open, -1);
      //rb_define_global_function('printf', rb_f_printf, -1);
      //rb_define_global_function('print', rb_f_print, -1);
      //rb_define_global_function('putc', rb_f_putc, 1);
        rb_define_global_function('puts', rb_f_puts, -1);
      //rb_define_global_function('gets', rb_f_gets, -1);
      //rb_define_global_function('readline', rb_f_readline, -1);
      //rb_define_global_function('getc', rb_f_getc, 0);
      //rb_define_global_function('select', rb_f_select, -1);
      
      //rb_define_global_function('readlines', rb_f_readlines, -1);
      
      //rb_define_global_function('`', rb_f_backquote, 1);
      
      //rb_define_global_function('p', rb_f_p, -1);
      //rb_define_method(rb_mKernel, 'display', rb_obj_display, -1);
      
        rb_cIO = rb_define_class('IO', rb_cObject);
        rb_include_module(rb_cIO, rb_mEnumerable);
        
        rb_define_alloc_func(rb_cIO, io_alloc);
      //rb_define_singleton_method(rb_cIO, 'open',  rb_io_s_open, -1);
      //rb_define_singleton_method(rb_cIO, 'sysopen',  rb_io_s_sysopen, -1);
      //rb_define_singleton_method(rb_cIO, 'for_fd', rb_io_s_for_fd, -1);
      //rb_define_singleton_method(rb_cIO, 'popen', rb_io_s_popen, -1);
      //rb_define_singleton_method(rb_cIO, 'foreach', rb_io_s_foreach, -1);
      //rb_define_singleton_method(rb_cIO, 'readlines', rb_io_s_readlines, -1);
      //rb_define_singleton_method(rb_cIO, 'read', rb_io_s_read, -1);
      //rb_define_singleton_method(rb_cIO, 'select', rb_f_select, -1);
      //rb_define_singleton_method(rb_cIO, 'pipe', rb_io_s_pipe, 0);
      
        rb_define_method(rb_cIO, 'initialize', rb_io_initialize, -1);
        
        rb_output_fs = Qnil;
        rb_define_hooked_variable('$,', rb_output_fs, 0, rb_str_setter);
      
      //rb_global_variable(&rb_default_rs);
        rb_rs = rb_default_rs = rb_str_new('\\n');
        rb_output_rs = Qnil;
      //OBJ_FREEZE(rb_default_rs);	/* avoid modifying RS_default */
        rb_define_hooked_variable('$/', rb_rs, 0, rb_str_setter);
        rb_define_hooked_variable('$-0', rb_rs, 0, rb_str_setter);
        rb_define_hooked_variable('$'+'\\\\'+'\\\\', rb_output_rs, 0, rb_str_setter);
        
        rb_define_hooked_variable('$.', lineno, 0, lineno_setter);
      //rb_define_virtual_variable('$_', rb_lastline_get, rb_lastline_set);
      
      //rb_define_method(rb_cIO, 'initialize_copy', rb_io_init_copy, 1);
      //rb_define_method(rb_cIO, 'reopen', rb_io_reopen, -1);
      
      //rb_define_method(rb_cIO, 'print', rb_io_print, -1);
      //rb_define_method(rb_cIO, 'putc', rb_io_putc, 1);
        rb_define_method(rb_cIO, 'puts', rb_io_puts, -1);
      //rb_define_method(rb_cIO, 'printf', rb_io_printf, -1);
      
      //rb_define_method(rb_cIO, 'each',  rb_io_each_line, -1);
      //rb_define_method(rb_cIO, 'each_line',  rb_io_each_line, -1);
      //rb_define_method(rb_cIO, 'each_byte',  rb_io_each_byte, 0);
      //rb_define_method(rb_cIO, 'each_char',  rb_io_each_char, 0);
      //rb_define_method(rb_cIO, 'lines',  rb_io_lines, -1);
      //rb_define_method(rb_cIO, 'bytes',  rb_io_bytes, 0);
      //rb_define_method(rb_cIO, 'chars',  rb_io_each_char, 0);
      
      //rb_define_method(rb_cIO, 'syswrite', rb_io_syswrite, 1);
      //rb_define_method(rb_cIO, 'sysread',  rb_io_sysread, -1);
      
      //rb_define_method(rb_cIO, 'fileno', rb_io_fileno, 0);
      //rb_define_alias(rb_cIO, 'to_i', 'fileno');
      //rb_define_method(rb_cIO, 'to_io', rb_io_to_io, 0);
      
      //rb_define_method(rb_cIO, 'fsync',   rb_io_fsync, 0);
      //rb_define_method(rb_cIO, 'sync',   rb_io_sync, 0);
      //rb_define_method(rb_cIO, 'sync=',  rb_io_set_sync, 1);
      
      //rb_define_method(rb_cIO, 'lineno',   rb_io_lineno, 0);
      //rb_define_method(rb_cIO, 'lineno=',  rb_io_set_lineno, 1);
      
      //rb_define_method(rb_cIO, 'readlines',  rb_io_readlines, -1);
      
      //rb_define_method(rb_cIO, 'read_nonblock',  io_read_nonblock, -1);
      //rb_define_method(rb_cIO, 'write_nonblock', rb_io_write_nonblock, 1);
      //rb_define_method(rb_cIO, 'readpartial',  io_readpartial, -1);
      //rb_define_method(rb_cIO, 'read',  io_read, -1);
      //rb_define_method(rb_cIO, 'gets',  rb_io_gets_m, -1);
      //rb_define_method(rb_cIO, 'readline',  rb_io_readline, -1);
      //rb_define_method(rb_cIO, 'getc',  rb_io_getc, 0);
      //rb_define_method(rb_cIO, 'getbyte',  rb_io_getc, 0);
      //rb_define_method(rb_cIO, 'readchar',  rb_io_readchar, 0);
      //rb_define_method(rb_cIO, 'readbyte',  rb_io_readchar, 0);
      //rb_define_method(rb_cIO, 'ungetc',rb_io_ungetc, 1);
      //rb_define_method(rb_cIO, '<<',    rb_io_addstr, 1);
      //rb_define_method(rb_cIO, 'flush', rb_io_flush, 0);
      //rb_define_method(rb_cIO, 'tell', rb_io_tell, 0);
      //rb_define_method(rb_cIO, 'seek', rb_io_seek_m, -1);
      //rb_define_const(rb_cIO, 'SEEK_SET', INT2FIX(SEEK_SET));
      //rb_define_const(rb_cIO, 'SEEK_CUR', INT2FIX(SEEK_CUR));
      //rb_define_const(rb_cIO, 'SEEK_END', INT2FIX(SEEK_END));
      //rb_define_method(rb_cIO, 'rewind', rb_io_rewind, 0);
      //rb_define_method(rb_cIO, 'pos', rb_io_tell, 0);
      //rb_define_method(rb_cIO, 'pos=', rb_io_set_pos, 1);
      //rb_define_method(rb_cIO, 'eof', rb_io_eof, 0);
      //rb_define_method(rb_cIO, 'eof?', rb_io_eof, 0);
      
      //rb_define_method(rb_cIO, 'close', rb_io_close_m, 0);
      //rb_define_method(rb_cIO, 'closed?', rb_io_closed, 0);
      //rb_define_method(rb_cIO, 'close_read', rb_io_close_read, 0);
      //rb_define_method(rb_cIO, 'close_write', rb_io_close_write, 0);
      
      //rb_define_method(rb_cIO, 'isatty', rb_io_isatty, 0);
      //rb_define_method(rb_cIO, 'tty?', rb_io_isatty, 0);
      //rb_define_method(rb_cIO, 'binmode',  rb_io_binmode, 0);
      //rb_define_method(rb_cIO, 'sysseek', rb_io_sysseek, -1);
      
      //rb_define_method(rb_cIO, 'ioctl', rb_io_ioctl, -1);
      //rb_define_method(rb_cIO, 'fcntl', rb_io_fcntl, -1);
      //rb_define_method(rb_cIO, 'pid', rb_io_pid, 0);
      //rb_define_method(rb_cIO, 'inspect',  rb_io_inspect, 0);
      
      //rb_define_variable('$stdin', &rb_stdin);
      //rb_stdin = prep_stdio(stdin, FMODE_READABLE, rb_cIO);
        rb_stdout = prep_stdio(console, 0, rb_cIO);
      //rb_define_hooked_variable('$stdout', rb_stdout, 0, stdout_setter);
      //rb_stderr = prep_stdio(stderr, FMODE_WRITABLE, rb_cIO);
      //rb_define_hooked_variable('$stderr', rb_stderr, 0, stdout_setter);
      //rb_define_hooked_variable('$>', rb_stdout, 0, stdout_setter);
        orig_stdout = rb_stdout;
      //rb_deferr = orig_stderr = rb_stderr;
      
      // /* constants to hold original stdin/stdout/stderr */
      //rb_define_global_const('STDIN', rb_stdin);
        rb_define_global_const('STDOUT', rb_stdout);
      //rb_define_global_const('STDERR', rb_stderr);
      
      //rb_define_readonly_variable('$<', &argf);
      //argf = rb_obj_alloc(rb_cObject);
      //rb_extend_object(argf, rb_mEnumerable);
      //rb_define_global_const('ARGF', argf);
      
      //rb_define_singleton_method(argf, 'to_s', argf_to_s, 0);
      
      //rb_define_singleton_method(argf, 'fileno', argf_fileno, 0);
      //rb_define_singleton_method(argf, 'to_i', argf_fileno, 0);
      //rb_define_singleton_method(argf, 'to_io', argf_to_io, 0);
      //rb_define_singleton_method(argf, 'each',  argf_each_line, -1);
      //rb_define_singleton_method(argf, 'each_line',  argf_each_line, -1);
      //rb_define_singleton_method(argf, 'each_byte',  argf_each_byte, 0);
      //rb_define_singleton_method(argf, 'each_char',  argf_each_char, 0);
      //rb_define_singleton_method(argf, 'lines',  argf_each_line, -1);
      //rb_define_singleton_method(argf, 'bytes',  argf_each_byte, 0);
      //rb_define_singleton_method(argf, 'chars',  argf_each_char, 0);
      
      //rb_define_singleton_method(argf, 'read',  argf_read, -1);
      //rb_define_singleton_method(argf, 'readlines', rb_f_readlines, -1);
      //rb_define_singleton_method(argf, 'to_a', rb_f_readlines, -1);
      //rb_define_singleton_method(argf, 'gets', rb_f_gets, -1);
      //rb_define_singleton_method(argf, 'readline', rb_f_readline, -1);
      //rb_define_singleton_method(argf, 'getc', argf_getc, 0);
      //rb_define_singleton_method(argf, 'getbyte', argf_getc, 0);
      //rb_define_singleton_method(argf, 'readchar', argf_readchar, 0);
      //rb_define_singleton_method(argf, 'readbyte', argf_readchar, 0);
      //rb_define_singleton_method(argf, 'tell', argf_tell, 0);
      //rb_define_singleton_method(argf, 'seek', argf_seek_m, -1);
      //rb_define_singleton_method(argf, 'rewind', argf_rewind, 0);
      //rb_define_singleton_method(argf, 'pos', argf_tell, 0);
      //rb_define_singleton_method(argf, 'pos=', argf_set_pos, 1);
      //rb_define_singleton_method(argf, 'eof', argf_eof, 0);
      //rb_define_singleton_method(argf, 'eof?', argf_eof, 0);
      //rb_define_singleton_method(argf, 'binmode', argf_binmode, 0);
      
      //rb_define_singleton_method(argf, 'filename', argf_filename, 0);
      //rb_define_singleton_method(argf, 'path', argf_filename, 0);
      //rb_define_singleton_method(argf, 'file', argf_file, 0);
      //rb_define_singleton_method(argf, 'skip', argf_skip, 0);
      //rb_define_singleton_method(argf, 'close', argf_close_m, 0);
      //rb_define_singleton_method(argf, 'closed?', argf_closed, 0);
      
      //rb_define_singleton_method(argf, 'lineno',   argf_lineno, 0);
      //rb_define_singleton_method(argf, 'lineno=',  argf_set_lineno, 1);
      
      //rb_global_variable(&current_file);
      //rb_define_readonly_variable('$FILENAME', &filename);
      //filename = rb_str_new2('-');
      
      //rb_define_virtual_variable('$-i', opt_i_get, opt_i_set);
      }
    END
  end
  
  # pulled from Init_Regexp
  def Init_MatchData
    add_function :rb_define_class, :rb_define_global_const, :rb_define_alloc_func, :match_alloc, :rb_undef_method
    <<-END
      function Init_MatchData() {
        rb_cMatch = rb_define_class("MatchData", rb_cObject);
        rb_define_global_const("MatchingData", rb_cMatch);
        rb_define_alloc_func(rb_cMatch, match_alloc);
        rb_undef_method(CLASS_OF(rb_cMatch), "new");
      }
    END
  end
  
  # verbatim
  def Init_Math
    add_function :rb_define_module, :rb_define_const, :rb_float_new
    <<-END
      function Init_Math() {
        rb_mMath = rb_define_module('Math');
        rb_define_const(rb_mMath, 'PI', rb_float_new(Math.PI));
        rb_define_const(rb_mMath, 'E', rb_float_new(Math.E));
      }
    END
  end
  
  # pulled from Init_Proc
  def Init_Method
    add_function :rb_define_class, :rb_undef_alloc_func, :rb_undef_method
    <<-END
      function Init_Method() {
        rb_cMethod = rb_define_class('Method', rb_cObject);
        rb_undef_alloc_func(rb_cMethod);
        rb_undef_method(CLASS_OF(rb_cMethod), 'new');
      }
    END
  end
  
  # CHECK
  def Init_Module
    add_function :rb_define_alloc_func, :rb_module_s_alloc
    <<-END
      function Init_Module() {
        rb_define_alloc_func(rb_cModule, rb_module_s_alloc);
      }
    END
  end
  
  # pulled from Init_Object
  def Init_NilClass
    add_function :rb_define_class, :rb_undef_alloc_func, :rb_undef_method, :rb_define_global_const
    <<-END
      function Init_NilClass() {
        rb_cNilClass = rb_define_class('NilClass', rb_cObject);
        rb_undef_alloc_func(rb_cNilClass);
        rb_undef_method(CLASS_OF(rb_cNilClass), 'new');
        rb_define_global_const('NIL', Qnil);
      }
    END
  end
  
  # CHECK
  def Init_Numeric
    add_functions :rb_define_class, :rb_include_module,
                  :rb_undef_alloc_func, :rb_undef_method, :rb_define_const,
                  :rb_float_new
    <<-END
      function Init_Numeric() {
        /* allow divide by zero -- Inf */
      //fpsetmask(fpgetmask() & ~(FP_X_DZ|FP_X_INV|FP_X_OFL));
        rb_eZeroDivError = rb_define_class('ZeroDivisionError', rb_eStandardError);
        rb_eFloatDomainError = rb_define_class('FloatDomainError', rb_eRangeError);
        rb_cNumeric = rb_define_class('Numeric', rb_cObject);
        rb_include_module(rb_cNumeric, rb_mComparable);
        rb_cInteger = rb_define_class('Integer', rb_cNumeric);
        rb_undef_alloc_func(rb_cInteger);
        rb_undef_method(CLASS_OF(rb_cInteger), 'new');
        rb_include_module(rb_cInteger, rb_mPrecision);
        rb_cFixnum = rb_define_class('Fixnum', rb_cInteger);
        rb_include_module(rb_cFixnum, rb_mPrecision);
        rb_cFloat = rb_define_class('Float', rb_cNumeric);
        rb_undef_alloc_func(rb_cFloat);
        rb_undef_method(CLASS_OF(rb_cFloat), 'new');
        rb_include_module(rb_cFloat, rb_mPrecision);
        rb_define_const(rb_cFloat, 'ROUNDS', INT2FIX(FLT_ROUNDS));
        rb_define_const(rb_cFloat, 'RADIX', INT2FIX(FLT_RADIX));
        rb_define_const(rb_cFloat, 'MANT_DIG', INT2FIX(DBL_MANT_DIG));
        rb_define_const(rb_cFloat, 'DIG', INT2FIX(DBL_DIG));
        rb_define_const(rb_cFloat, 'MIN_EXP', INT2FIX(DBL_MIN_EXP));
        rb_define_const(rb_cFloat, 'MAX_EXP', INT2FIX(DBL_MAX_EXP));
        rb_define_const(rb_cFloat, 'MIN_10_EXP', INT2FIX(DBL_MIN_10_EXP));
        rb_define_const(rb_cFloat, 'MAX_10_EXP', INT2FIX(DBL_MAX_10_EXP));
      //rb_define_const(rb_cFloat, 'MIN', rb_float_new(DBL_MIN));
      //rb_define_const(rb_cFloat, 'MAX', rb_float_new(DBL_MAX));
      //rb_define_const(rb_cFloat, 'EPSILON', rb_float_new(DBL_EPSILON));
      }
    END
  end
  
  # CHECK
  def Init_Object
    add_function :rb_define_module, :rb_include_module,
                 :rb_define_alloc_func, :rb_class_allocate_instance,
                 :rb_obj_alloc, :rb_define_singleton_method, :main_to_s
    <<-END
    function Init_Object() {
      rb_mKernel = rb_define_module('Kernel');
      rb_include_module(rb_cObject, rb_mKernel);
      rb_define_alloc_func(rb_cObject, rb_class_allocate_instance);
      ruby_top_self = rb_obj_alloc(rb_cObject);
      rb_define_singleton_method(ruby_top_self, 'to_s', main_to_s, 0);
    }
    END
  end
  
  # verbatim
  def Init_Precision
    add_function :rb_define_module
    <<-END
      function Init_Precision() {
        rb_mPrecision = rb_define_module('Precision');
      }
    END
  end
  
  # changed rb_str_new2 to rb_str_new, CHECK
  def Init_Proc
    add_function :rb_define_class, :rb_exc_new3, :rb_obj_freeze, :rb_str_new, :rb_undef_alloc_func
    <<-END
      function Init_Proc() {
        rb_eLocalJumpError = rb_define_class('LocalJumpError', rb_eStandardError);
      //exception_error = rb_exc_new3(rb_eFatal, rb_obj_freeze(rb_str_new("exception reentered")));
      //OBJ_TAINT(exception_error);
      //OBJ_FREEZE(exception_error);
        
        rb_eSysStackError = rb_define_class('SystemStackError', rb_eStandardError);
      //sysstack_error = rb_exc_new3(rb_eSysStackError, rb_obj_freeze(rb_str_new("stack level too deep")));
      //OBJ_TAINT(sysstack_error);
      //OBJ_FREEZE(sysstack_error);
        
        rb_cProc = rb_define_class('Proc', rb_cObject);
        rb_undef_alloc_func(rb_cProc);
      }
    END
  end
  
  # verbatim
  def Init_Range
    $mc.add_function :rb_define_class, :rb_include_module
    <<-END
      function Init_Range() {
        rb_cRange = rb_define_class('Range', rb_cObject);
        rb_include_module(rb_cRange, rb_mEnumerable);
      }
    END
  end
  
  # 
  def Init_Request
    add_function :rb_define_class, :rb_include_module
    <<-END
      function Init_Request() {
        rb_cRequest = rb_define_class('Request', rb_cObject);
        rb_include_module(rb_cRequest, rb_mCodeEvent);
        sym_response = ID2SYM(rb_intern('response'));
        sym_success  = ID2SYM(rb_intern('success'));
        sym_failure  = ID2SYM(rb_intern('failure'));
        sym_request  = ID2SYM(rb_intern('request'));
        sym_cancel   = ID2SYM(rb_intern('cancel'));
      }
    END
  end
  
  # 
  def Init_Response
    add_function :rb_define_class
    <<-END
      function Init_Response() {
        rb_cResponse = rb_define_class('Response', rb_cObject);
        rb_undef_method(CLASS_OF(rb_cResponse), 'new');
      }
    END
  end
  
  # INCOMPLETE
  def Init_Regexp
    add_function :rb_reg_new, :rb_define_class
    <<-END
      function Init_Regexp() {
        rb_eRegexpError = rb_define_class('RegexpError', rb_eStandardError);
        rb_cRegexp = rb_define_class("Regexp", rb_cObject);
        
      }
    END
  end
  
  # verbatim
  def Init_String
    add_functions :rb_define_class, :rb_include_module,
                  :rb_define_alloc_func, :rb_define_variable
    <<-END
      function Init_String() {
        rb_cString = rb_define_class('String', rb_cObject);
        rb_include_module(rb_cString, rb_mComparable);
        rb_include_module(rb_cString, rb_mEnumerable);
        rb_define_alloc_func(rb_cString, str_alloc);
        rb_fs = Qnil;
        rb_define_variable('$;', rb_fs);
        rb_define_variable('$-F', rb_fs);
      }
    END
  end
  
  # added 'rb_struct_ref' function definitions
  def Init_Struct
    add_function :rb_define_class, :rb_include_module, :rb_undef_alloc_func
    <<-END
      function Init_Struct() {
        rb_cStruct = rb_define_class('Struct', rb_cObject);
        rb_include_module(rb_cStruct, rb_mEnumerable);
        rb_undef_alloc_func(rb_cStruct);
        ref_func = [
          function rb_struct_ref0(obj){ return obj.ptr[0]; },
          function rb_struct_ref1(obj){ return obj.ptr[1]; },
          function rb_struct_ref2(obj){ return obj.ptr[2]; },
          function rb_struct_ref3(obj){ return obj.ptr[3]; },
          function rb_struct_ref4(obj){ return obj.ptr[4]; },
          function rb_struct_ref5(obj){ return obj.ptr[5]; },
          function rb_struct_ref6(obj){ return obj.ptr[6]; },
          function rb_struct_ref7(obj){ return obj.ptr[7]; },
          function rb_struct_ref8(obj){ return obj.ptr[8]; },
          function rb_struct_ref9(obj){ return obj.ptr[9]; }
        ];
      }
    END
  end
  
  # changed st tables
  def Init_sym
    <<-END
      function Init_sym() {
        sym_tbl     = {}; // was st_init_numtable
        sym_rev_tbl = {}; // was st_init_numtable
      }
    END
  end
  
  # pulled from Init_Object
  def Init_Symbol
    add_function :rb_define_class, :rb_undef_alloc_func, :rb_undef_method
    <<-END
      function Init_Symbol() {
        rb_cSymbol = rb_define_class('Symbol', rb_cObject);
        rb_undef_alloc_func(rb_cSymbol);
        rb_undef_method(CLASS_OF(rb_cSymbol), 'new');
      }
    END
  end
  
  def Init_Time
    add_function :time_s_alloc, :rb_define_class, :rb_include_module
    <<-END
      function Init_Time() {
        rb_cTime = rb_define_class('Time', rb_cObject);
        rb_include_module(rb_cTime, rb_mComparable);
        rb_define_alloc_func(rb_cTime, time_s_alloc);
      }
    END
  end
  
  # pulled from Init_Object
  def Init_TrueClass
    add_function :rb_define_class, :rb_undef_alloc_func, :rb_undef_method, :rb_define_global_const
    <<-END
      function Init_TrueClass() {
        rb_cTrueClass = rb_define_class('TrueClass', rb_cObject);
        rb_undef_alloc_func(rb_cTrueClass);
        rb_undef_method(CLASS_OF(rb_cTrueClass), 'new');
        rb_define_global_const('TRUE', Qtrue);
      }
    END
  end
  
  # pulled from Init_Proc
  def Init_UnboundMethod
    add_functions :rb_define_class, :rb_undef_alloc_func, :rb_undef_method
    <<-END
      function Init_UnboundMethod() {
        rb_cUnboundMethod = rb_define_class('UnboundMethod', rb_cObject);
        rb_undef_alloc_func(rb_cUnboundMethod);
        rb_undef_method(CLASS_OF(rb_cUnboundMethod), 'new');
      }
    END
  end
  
  # need to move method defs to class << Ruby
  def Init_UserEvent
    add_function :rb_define_module, :init_custom_events, :rb_intern
    <<-END
      function Init_UserEvent() {
        rb_mUserEvent = rb_define_module('UserEvent');
        sym_base       = ID2SYM(rb_intern('base'));
        sym_condition  = ID2SYM(rb_intern('condition'));
        sym_onlisten   = ID2SYM(rb_intern('on_listen'));
        sym_onunlisten = ID2SYM(rb_intern('on_unlisten'));
        init_custom_events();
      }
    END
  end
  
  # moved id definitions to Init_ids and changed st tables
  def Init_var_tables
    <<-END
      function Init_var_tables() {
        rb_global_tbl = st_init_numtable();
        rb_class_tbl  = {}; // was st_init_numtable
      }
    END
  end
  
  # expanded Init_Object into multiple inits, added Redshift inits
  def rb_call_inits
    add_functions :Init_sym, :Init_ids, :Init_var_tables, :Init_boot,
                  :Init_Object, :Init_NilClass, :Init_Symbol, :Init_Module,
                  :Init_Class, :Init_Data, :Init_TrueClass,
                  :Init_FalseClass, :Init_Comparable, :Init_Enumerable,
                  :Init_Precision, :Init_eval, :Init_String,
                  :Init_Exception, :Init_Numeric, :Init_Bignum,
                  :Init_Array, :Init_Hash, :Init_Struct,
                  :Init_Regexp, :Init_Range, :Init_IO, :Init_Time,
                  :Init_Proc, :Init_Binding, :Init_Math,
                  :Init_Enumerator, :Init_UserEvent,
                  :Init_Document, :Init_Element, :Init_Method,
                  :Init_UnboundMethod, :Init_MatchData, :Init_Event,
                  :Init_Browser, :Init_CodeEvent, :Init_Request,
                  :Init_Response, :Init_accessors, :Init_st
    <<-END
      function rb_call_inits() {
        Init_st();
        Init_sym();
        Init_ids();
        Init_var_tables();
        Init_boot();
        Init_Object();
        Init_NilClass();
        Init_Symbol();
        Init_Module();
        Init_Class();
        Init_Data();
        Init_TrueClass();
        Init_FalseClass();
        Init_Comparable();
        Init_Enumerable();
        Init_Precision();
        Init_eval();
        Init_String();
        Init_Exception();
        Init_Numeric();
        Init_Bignum();
      //Init_syserr();
        Init_Array();
        Init_Hash();
        Init_Struct();
        Init_Regexp();
        Init_MatchData();
        Init_Range();
        Init_IO();
        Init_Time();
        Init_Proc();
        Init_Method();
        Init_UnboundMethod();
        Init_Binding();
        Init_Math();
        Init_Enumerator();
      //Init_version();
        
        Init_CodeEvent();
        Init_Browser();
        Init_UserEvent();
        Init_Document();
        Init_Element();
        Init_Event();
        Init_Request();
        Init_Response();
        Init_accessors();
      }
    END
  end
  
  # CHECK CHECK CHECK
  def ruby_init
    add_functions :rb_call_inits, :rb_define_global_const, :rb_node_newnode,
                  :top_local_init, :local_cnt, :error_print#, :rb_f_binding
    <<-END
      function ruby_init() {
        red_init_bullshit();
        var frame = { this_is_the_top_frame: true, prev: 0 };
        var iter = { iter: ITER_NOT, prev: 0 };
        var state = 0;
        
        if (initialized) { return; }
        initialized = 1;
        
        ruby_frame = top_frame = frame;
        ruby_iter = iter;
      //rb_origenviron = 0;
      //Init_stack();
      //Init_heap();
        PUSH_SCOPE();
        ruby_scope.local_vars = [];
        ruby_scope.local_tbl = 0;
        top_scope = ruby_scope;
        SCOPE_SET(SCOPE_PRIVATE);
        PUSH_TAG(PROT_NONE);
        try { // was EXEC_TAG
          rb_call_inits();
          define_methods(); // added
          ruby_class = rb_cObject;
          ruby_frame.self = ruby_top_self;
          ruby_top_cref = rb_node_newnode(NODE_CREF, rb_cObject, 0, 0);
          ruby_cref = ruby_top_cref;
        //rb_define_global_const('TOPLEVEL_BINDING', rb_f_binding(ruby_top_self));
        //ruby_prog_init();
        //ALLOW_INTS();
        } catch (x) {
          if (typeof(state = x) != 'number') { throw(state); }
          prot_tag = _tag.prev; // added
          error_print();
          exit(EXIT_FAILURE);
        }
        POP_TAG();
        POP_SCOPE();
        ruby_scope = top_scope;
        top_scope.flags &= ~SCOPE_NOSTACK;
        ruby_running = 1;
        
        top_local_init(); // added
      }
    END
  end
end
