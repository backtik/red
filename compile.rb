require 'src/ruby/array'
require 'src/ruby/bignum'
require 'src/ruby/class'
require 'src/ruby/comparable'
require 'src/ruby/data'
require 'src/ruby/enumerable'
require 'src/ruby/enumerator'
require 'src/ruby/exception'
require 'src/ruby/false'
require 'src/ruby/fixnum'
require 'src/ruby/float'
require 'src/ruby/hash'
require 'src/ruby/integer'
require 'src/ruby/io'
require 'src/ruby/method'
require 'src/ruby/module'
require 'src/ruby/nil'
require 'src/ruby/numeric'
require 'src/ruby/object'
require 'src/ruby/parse'
require 'src/ruby/precision'
require 'src/ruby/proc'
require 'src/ruby/range'
require 'src/ruby/st'
require 'src/ruby/string'
require 'src/ruby/struct'
require 'src/ruby/symbol'
require 'src/ruby/time'
require 'src/ruby/true'
require 'src/ruby/variable'
require 'src/redshift/accessors'
require 'src/redshift/browser'
require 'src/redshift/classes'
require 'src/redshift/code_event'
require 'src/redshift/document'
require 'src/redshift/element'
require 'src/redshift/event'
require 'src/redshift/properties'
require 'src/redshift/request'
require 'src/redshift/response'
require 'src/redshift/styles'
require 'src/redshift/user_event'
class Red::MethodCompiler
  attr_reader :functions
  attr_accessor :compiled_functions
  
  Ruby = Object.new
  
  def initialize
    @compiled_functions = {}
    @missing_functions  = []
    @functions          = ""
    @function_stub      = 'a0a'
    
    @compiled_methods = []
    @missing_methods  = []
    @methods          = ""
  end
  
  def methods
    "      function define_methods() {\n%s}\n" % @methods
  end
  
  def add_functions(*functions_to_compile)
    functions_to_compile.each do |function|
      next if @compiled_functions.keys.include?(function)
      @compiled_functions[function] = @function_stub.succ!.dup
      result = 
    begin
      self.send(function)
    rescue NoMethodError
      "        console.log(\"%s\");\n" % function
    end
      @functions += result
    end
  end
  
  def add_methods(*methods_to_compile)
    methods_to_compile.each do |method|
      next if @compiled_methods.include?(method)
      @compiled_methods |= [method]
      result =
    begin
      Ruby.rubysend(method)
    rescue NoMethodError
      "        console.log(\"undefined Ruby method '%s'\");\n" % method
    end
      @methods += result
    end
  end
  
  alias add_method add_methods
  alias add_function add_functions
  
  class << Ruby
    alias rubysend send
    
    def _!
      $mc.add_function :name_err_mesg_new, :rb_define_singleton_method
      <<-END
        rb_define_singleton_method(rb_cNameErrorMesg, '!', name_err_mesg_new, 3);
      END
    end
    
    def ^
      $mc.add_functions :false_xor, :true_xor, :fix_xor
      <<-END
        rb_define_method(rb_cFalseClass, '^', false_xor, 1);
        rb_define_method(rb_cNilClass, '^', false_xor, 1);
        rb_define_method(rb_cFixnum, '^', fix_xor, 1);
        rb_define_method(rb_cTrueClass, '^', true_xor, 1);
      END
    end
    
    def %
      $mc.add_function :rb_str_format_m, :fix_mod, :flo_mod
      <<-END
        rb_define_method(rb_cString, '%', rb_str_format_m, 1);
        rb_define_method(rb_cFixnum, '%', fix_mod, 1);
        rb_define_method(rb_cFloat, '%', flo_mod, 1);
      END
    end
    
    def &
      $mc.add_functions :false_and, :true_and, :rb_ary_and, :fix_and
      <<-END
        rb_define_method(rb_cFalseClass, '&', false_and, 1);
        rb_define_method(rb_cNilClass, '&', false_and, 1);
        rb_define_method(rb_cArray, '&', rb_ary_and, 1);
        rb_define_method(rb_cTrueClass, '&', true_and, 1);
        rb_define_method(rb_cFixnum, '&', fix_and, 1);
      END
    end
    
    def *
      $mc.add_function :rb_str_times, :rb_ary_times, :fix_mul, :flo_mul
      <<-END
        rb_define_method(rb_cString, '*', rb_str_times, 1);
        rb_define_method(rb_cFloat, '*', flo_mul, 1);
        rb_define_method(rb_cArray, '*', rb_ary_times, 1);
        rb_define_method(rb_cFixnum, '*', fix_mul, 1);
      END
    end
    
    def **
      $mc.add_function :fix_pow, :flo_pow
      <<-END
        rb_define_method(rb_cFixnum, '**', fix_pow, 1);
        rb_define_method(rb_cFloat, '**', flo_pow, 1);
      END
    end
    
    def +
      $mc.add_function :rb_str_plus, :rb_ary_plus, :fix_plus, :flo_plus, :time_plus
      <<-END
        rb_define_method(rb_cTime, '+', time_plus, 1);
        rb_define_method(rb_cString, '+', rb_str_plus, 1);
        rb_define_method(rb_cArray, '+', rb_ary_plus, 1);
        rb_define_method(rb_cFloat, '+', flo_plus, 1);
        rb_define_method(rb_cFixnum, '+', fix_plus, 1);
      END
    end
    
    def +@
      $mc.add_function :num_uplus
      <<-END
        rb_define_method(rb_cNumeric, '+@', num_uplus, 0);
      END
    end
    
    def -
      $mc.add_function :rb_ary_diff, :fix_minus, :flo_minus, :time_minus, :rb_big_minus
      <<-END
        rb_define_method(rb_cBignum, '-', rb_big_minus, 1);
        rb_define_method(rb_cTime, '-', time_minus, 1);
        rb_define_method(rb_cArray, '-', rb_ary_diff, 1);
        rb_define_method(rb_cFloat, '-', flo_minus, 1);
        rb_define_method(rb_cFixnum, '-', fix_minus, 1);
      END
    end
    
    def -@
      $mc.add_function :num_uminus, :fix_uminus, :flo_uminus
      <<-END
        rb_define_method(rb_cNumeric, '-@', num_uminus, 0);
        rb_define_method(rb_cFloat, '-@', flo_uminus, 0);
        rb_define_method(rb_cFixnum, '-@', fix_uminus, 0);
      END
    end
    
    def /
      $mc.add_function :fix_div, :flo_div
      <<-END
        rb_define_method(rb_cFixnum, '/', fix_div, 1);
        rb_define_method(rb_cFloat, '/', flo_div, 1);
      END
    end
    
    def <
      $mc.add_function :cmp_lt, :rb_mod_lt, :fix_lt, :flo_lt
      <<-END
        rb_define_method(rb_cModule, '<',  rb_mod_lt, 1);
        rb_define_method(rb_cFixnum, '<',  fix_lt, 1);
        rb_define_method(rb_cFloat, '<', flo_lt, 1);
        rb_define_method(rb_mComparable, '<', cmp_lt, 1);
      END
    end
    
    def <<
      $mc.add_function :rb_str_concat, :rb_ary_push, :rb_fix_lshift, :classes_append
      <<-END
        rb_define_method(rb_cClasses, '<<', classes_append, 1);
        rb_define_method(rb_cString, '<<', rb_str_concat, 1);
        rb_define_method(rb_cArray, '<<', rb_ary_push, 1);
        rb_define_method(rb_cFixnum, '<<', rb_fix_lshift, 1);
      END
    end
    
    def <=
      $mc.add_function :cmp_le, :rb_class_inherited_p, :fix_le, :flo_le
      <<-END
        rb_define_method(rb_cModule, '<=', rb_class_inherited_p, 1);
        rb_define_method(rb_cFloat, '<=', flo_le, 1);
        rb_define_method(rb_mComparable, '<=', cmp_le, 1);
        rb_define_method(rb_cFixnum, '<=', fix_le, 1);
      END
    end
    
    def <=>
      $mc.add_functions :rb_mod_cmp, :rb_str_cmp_m, :rb_ary_cmp, :num_cmp,
                        :fix_cmp, :flo_cmp, :time_cmp
      <<-END
        rb_define_method(rb_cTime, "<=>", time_cmp, 1);
        rb_define_method(rb_cModule, '<=>',  rb_mod_cmp, 1);
        rb_define_method(rb_cFloat, '<=>', flo_cmp, 1);
        rb_define_method(rb_cNumeric, '<=>', num_cmp, 1);
        rb_define_method(rb_cString, '<=>', rb_str_cmp_m, 1);
        rb_define_method(rb_cArray, '<=>', rb_ary_cmp, 1);
        rb_define_method(rb_cFixnum, '<=>', fix_cmp, 1);
     END
    end
    
    def ==
      $mc.add_function :rb_obj_equal, :cmp_equal, :method_eq, :proc_eq,
                       :range_eq, :rb_hash_equal, :rb_str_equal,
                       :rb_ary_equal, :fix_equal, :flo_eq, :rb_struct_equal,
                       :elem_eq
      <<-END
        rb_define_method(rb_cElement, '==', elem_eq, 1);
        rb_define_method(rb_cStruct, '==', rb_struct_equal, 1);
        rb_define_method(rb_cHash,'==', rb_hash_equal, 1);
        rb_define_method(rb_cRange, '==', range_eq, 1);
        rb_define_method(rb_cModule, '==', rb_obj_equal, 1);
        rb_define_method(rb_cMethod, '==', method_eq, 1);
        rb_define_method(rb_cFloat, '==', flo_eq, 1);
        rb_define_method(rb_mKernel, '==', rb_obj_equal, 1);
        rb_define_method(rb_mComparable, '==', cmp_equal, 1);
        rb_define_method(rb_cProc, '==', proc_eq, 1);
        rb_define_method(rb_cString, '==', rb_str_equal, 1);
        rb_define_method(rb_cArray, '==', rb_ary_equal, 1);
        rb_define_method(rb_cFixnum, '==', fix_equal, 1);
        rb_define_method(rb_cUnboundMethod, '==', method_eq, 1);
      END
    end
    
    def ===
      $mc.add_function :rb_equal, :rb_obj_equal, :rb_mod_eqq, :range_include,
                       :rb_define_singleton_method, :syserr_eqq
      <<-END
        rb_define_method(rb_cRange, '===', range_include, 1);
        rb_define_method(rb_cModule, '===', rb_mod_eqq, 1);
        rb_define_method(rb_mKernel, '===', rb_equal, 1);
        rb_define_method(rb_cSymbol, '===', rb_obj_equal, 1);
        rb_define_singleton_method(rb_eSystemCallError, '===', syserr_eqq, 1);
      END
    end
    
    def =~
      $mc.add_function :rb_obj_pattern_match, :rb_str_match
      <<-END
        rb_define_method(rb_mKernel, '=~', rb_obj_pattern_match, 1);
        rb_define_method(rb_cString, '=~', rb_str_match, 1);
      END
    end
    
    def >
      $mc.add_function :cmp_gt, :rb_mod_gt, :fix_gt, :flo_gt
      <<-END
        rb_define_method(rb_cModule, '>',  rb_mod_gt, 1);
        rb_define_method(rb_cFixnum, '>',  fix_gt, 1);
        rb_define_method(rb_cFloat, '>', flo_gt, 1);
        rb_define_method(rb_mComparable, '>', cmp_gt, 1);
      END
    end
    
    def >>
      $mc.add_function :rb_fix_rshift
      <<-END
        rb_define_method(rb_cFixnum, '>>', rb_fix_rshift, 1);
      END
    end
    
    def >=
      $mc.add_function :cmp_ge, :rb_mod_ge, :fix_ge, :flo_ge
      <<-END
        rb_define_method(rb_cModule, '>=', rb_mod_ge, 1);
        rb_define_method(rb_mComparable, '>=', cmp_ge, 1);
        rb_define_method(rb_cFloat, '>=', flo_ge, 1);
        rb_define_method(rb_cFixnum, '>=', fix_ge, 1);
      END
    end
    
    def []
      $mc.add_function :method_call, :rb_proc_call, :rb_hash_s_create,
                       :rb_hash_aref, :rb_define_singleton_method,
                       :rb_str_aref_m, :rb_ary_s_create, :rb_ary_aref,
                       :fix_aref, :rb_struct_aref, :elem_find,
                       :rb_define_module_function, :prop_aref,
                       :styles_aref
      <<-END
        rb_define_method(rb_cStyles, '[]', styles_aref, 1);
        rb_define_method(rb_cProperties, '[]', prop_aref, 1);
        rb_define_module_function(rb_mDocument, '[]', elem_find, 1);
        rb_define_method(rb_cStruct, '[]', rb_struct_aref, 1);
        rb_define_method(rb_cMethod, '[]', method_call, -1);
        rb_define_method(rb_cString, '[]', rb_str_aref_m, -1);
        rb_define_singleton_method(rb_cHash, '[]', rb_hash_s_create, -1);
        rb_define_method(rb_cHash, '[]', rb_hash_aref, 1);
        rb_define_singleton_method(rb_cArray, '[]', rb_ary_s_create, -1);
        rb_define_method(rb_cArray, '[]', rb_ary_aref, -1);
        rb_define_method(rb_cFixnum, '[]', fix_aref, 1);
        rb_define_method(rb_cProc, '[]', rb_proc_call, -2);
      END
    end
    
    def []=
      $mc.add_function :rb_hash_aset, :rb_str_aset_m, :rb_ary_aset, :rb_struct_aset,
                       :prop_aset, :styles_aset
      <<-END
        rb_define_method(rb_cStyles, '[]=', styles_aset, 2);
        rb_define_method(rb_cProperties, '[]=', prop_aset, 2);
        rb_define_method(rb_cStruct, '[]=', rb_struct_aset, 2);
        rb_define_method(rb_cHash,'[]=', rb_hash_aset, 2);
      //rb_define_method(rb_cString, '[]=', rb_str_aset_m, -1);
        rb_define_method(rb_cArray, '[]=', rb_ary_aset, -1);
      END
    end
    
    def |
      $mc.add_functions :false_or, :true_or, :rb_ary_or, :fix_or
      <<-END
        rb_define_method(rb_cFalseClass, '|', false_or, 1);
        rb_define_method(rb_cArray, '|', rb_ary_or, 1);
        rb_define_method(rb_cNilClass, '|', false_or, 1);
        rb_define_method(rb_cFixnum, '|', fix_or,  1);
        rb_define_method(rb_cTrueClass, '|', true_or, 1);
      END
    end
    
    def ~
      $mc.add_function :fix_rev
      <<-END
        rb_define_method(rb_cFixnum, '~', fix_rev, 0);
      END
    end
    
    def __id__
      $mc.add_function :rb_obj_id
      <<-END
        rb_define_method(rb_mKernel, '__id__', rb_obj_id, 0);
      END
    end
    
    def __method__
      $mc.add_function :rb_f_method_name, :rb_define_global_function
      <<-END
        rb_define_global_function('__method__', rb_f_method_name, 0);
      END
    end
    
    def __send__
      $mc.add_function :rb_f_send
      <<-END
        rb_define_method(rb_mKernel, '__send__', rb_f_send, -1);
      END
    end
    
    def _dump
      $mc.add_function :name_err_mesg_to_str
      <<-END
        rb_define_method(rb_cNameErrorMesg, '_dump', name_err_mesg_to_str, 1);
      END
    end
    
    def _load
      $mc.add_function :rb_define_singleton_method, :name_err_mesg_load
      <<-END
        rb_define_singleton_method(rb_cNameErrorMesg, '_load', name_err_mesg_load, 1);
      END
    end
    
    def abort
      $mc.add_function :rb_define_global_function, :rb_f_abort
      <<-END
        rb_define_global_function('abort', rb_f_abort, -1);
      END
    end
    
    def abs
      $mc.add_function :num_abs, :fix_abs, :flo_abs
      <<-END
        rb_define_method(rb_cNumeric, 'abs', num_abs, 0);
        rb_define_method(rb_cFixnum, 'abs', fix_abs, 0);
        rb_define_method(rb_cFloat, 'abs', flo_abs, 0);
      END
    end
    
    def add_class
      $mc.add_function :elem_add_class
      <<-END
        rb_define_method(rb_cElement, 'add_class', elem_add_class, 1);
      END
    end
    
    def add_classes
      $mc.add_function :elem_add_classes
      <<-END
        rb_define_method(rb_cElement, 'add_classes', elem_add_classes, -1);
      END
    end
    
    def add_listener
      $mc.add_function :uevent_add_listener
      <<-END
        rb_define_method(rb_mUserEvent, 'add_listener', uevent_add_listener, 1);
      END
    end
    
    def air?
      $mc.add_function :rb_define_global_function, :rb_f_air_p
      <<-END
        rb_define_global_function('air?', rb_f_air_p, 0);
      END
    end
    
    def alias_method
      $mc.add_function :rb_mod_alias_method, :rb_define_private_method
      <<-END
        rb_define_private_method(rb_cModule, 'alias_method', rb_mod_alias_method, 2);
      END
    end
    
    def all?
      $mc.add_function :enum_all
      <<-END
        rb_define_method(rb_mEnumerable, 'all?', enum_all, 0);
      END
    end
    
    def all_symbols
      $mc.add_function :rb_sym_all_symbols, :rb_define_singleton_method
      <<-END
        rb_define_singleton_method(rb_cSymbol, 'all_symbols', rb_sym_all_symbols, 0);
      END
    end
    
    def allocate
      $mc.add_function :rb_obj_alloc
      <<-END
        rb_define_method(rb_cClass, 'allocate', rb_obj_alloc, 0);
      END
    end
    
    def alt?
      $mc.add_function :event_alt
      <<-END
        rb_define_method(rb_cEvent, 'alt?', event_alt, 0);
      END
    end
    
    def ancestors
      $mc.add_function :rb_mod_ancestors
      <<-END
        rb_define_method(rb_cModule, 'ancestors', rb_mod_ancestors, 0);
      END
    end
    
    def any?
      $mc.add_function :enum_any
      <<-END
        rb_define_method(rb_mEnumerable, 'any?', enum_any, 0);
      END
    end
    
    def append_features
      $mc.add_function :rb_mod_append_features, :rb_define_private_method
      <<-END
        rb_define_private_method(rb_cModule, 'append_features', rb_mod_append_features, 1);
      END
    end
    
    def args
      $mc.add_function :nometh_err_args
      <<-END
        rb_define_method(rb_eNoMethodError, 'args', nometh_err_args, 0);
      END
    end
    
    def arity
      $mc.add_function :method_arity, :proc_arity
      <<-END
        rb_define_method(rb_cProc, 'arity', proc_arity, 0);
        rb_define_method(rb_cMethod, 'arity', method_arity, 0);
        rb_define_method(rb_cUnboundMethod, 'arity', method_arity, 0);
      END
    end
    
    def Array
      $mc.add_function :rb_f_array, :rb_define_global_function
      <<-END
        rb_define_global_function('Array', rb_f_array, 1);
      END
    end
    
    def asctime
      $mc.add_function :time_asctime
      <<-END
        rb_define_method(rb_cTime, "asctime", time_asctime, 0);
      END
    end
    
    def at
      $mc.add_function :rb_ary_at, :time_s_at
      <<-END
        rb_define_method(rb_cArray, 'at', rb_ary_at, 1);
        rb_define_singleton_method(rb_cTime, "at", time_s_at, -1);
      END
    end
    
    def attr
      $mc.add_function :rb_mod_attr, :rb_define_private_method
      <<-END
        rb_define_private_method(rb_cModule, 'attr', rb_mod_attr, -1);
      END
    end
    
    def attr_accessor
      $mc.add_function :rb_mod_attr_accessor, :rb_define_private_method
      <<-END
        rb_define_private_method(rb_cModule, 'attr_accessor', rb_mod_attr_accessor, -1);
      END
    end
    
    def attr_reader
      $mc.add_function :rb_mod_attr_reader, :rb_define_private_method
      <<-END
        rb_define_private_method(rb_cModule, 'attr_reader', rb_mod_attr_reader, -1);
      END
    end
    
    def attr_writer
      $mc.add_function :rb_mod_attr_writer, :rb_define_private_method
      <<-END
        rb_define_private_method(rb_cModule, 'attr_writer', rb_mod_attr_writer, -1);
      END
    end
    
    def backtrace
      $mc.add_function :exc_backtrace
      <<-END
        rb_define_method(rb_eException, 'backtrace', exc_backtrace, 0);
      END
    end
    
    def base_type
      $mc.add_function :event_base_type
      <<-END
        rb_define_method(rb_cEvent, 'base_type', event_base_type, 0);
      END
    end
    
    def begin
      $mc.add_function :range_first
      <<-END
        rb_define_method(rb_cRange, 'begin', range_first, 0);
      END
    end
    
    def between?
      $mc.add_function :cmp_between
      <<-END
        rb_define_method(rb_mComparable, 'between?', cmp_between, 2);
      END
    end
    
    def block_given?
      $mc.add_function :rb_define_global_function, :rb_f_block_given_p
      <<-END
        rb_define_global_function('block_given?', rb_f_block_given_p, 0);
      END
    end
    
    def bind
      $mc.add_function :umethod_bind
      <<-END
        rb_define_method(rb_cUnboundMethod, 'bind', umethod_bind, 1);
      END
    end
    
    def binding
      $mc.add_function :proc_binding, :rb_f_binding, :rb_define_global_function
      <<-END
        rb_define_global_function('binding', rb_f_binding, 0);
        rb_define_method(rb_cProc, 'binding', proc_binding, 0);
      END
    end
    
    def body
      $mc.add_function :doc_body
      <<-END
        rb_define_module_function(rb_mDocument, 'body', doc_body, 0);
      END
    end
    
    def bytes
      $mc.add_function :rb_str_each_byte
      <<-END
        rb_define_method(rb_cString, 'bytes', rb_str_each_byte, 0);
      END
    end
    
    def bytesize
      $mc.add_function :rb_str_length
      <<-END
        rb_define_method(rb_cString, 'bytesize', rb_str_length, 0);
      END
    end
    
    def call
      $mc.add_function :method_call, :rb_proc_call
      <<-END
        rb_define_method(rb_cMethod, 'call', method_call, -1);
        rb_define_method(rb_cProc, 'call', rb_proc_call, -2);
      END
    end
    
    def caller
      $mc.add_function :rb_define_global_function, :rb_f_caller
      <<-END
        rb_define_global_function('caller', rb_f_caller, -1);
      END
    end
    
    def cancel
      $mc.add_function :req_cancel
      <<-END
        rb_define_method(rb_cRequest, 'cancel', req_cancel, 0);
      END
    end
    
    def capitalize
      $mc.add_function :rb_str_capitalize
      <<-END
        rb_define_method(rb_cString, 'capitalize', rb_str_capitalize, 0);
      END
    end
    
    def capitalize!
      $mc.add_function :rb_str_capitalize_bang
      <<-END
        rb_define_method(rb_cString, 'capitalize!', rb_str_capitalize_bang, 0);
      END
    end
    
    def casecmp
      $mc.add_function :rb_str_casecmp
      <<-END
        rb_define_method(rb_cString, 'casecmp', rb_str_casecmp, 1);
      END
    end
    
    def catch
      add_function :rb_define_global_function, :rb_f_catch
      <<-END
        rb_define_global_function('catch', rb_f_catch, 1);
      END
    end
    
    def ceil
      $mc.add_function :num_ceil, :int_to_i, :flo_ceil
      <<-END
        rb_define_method(rb_cNumeric, 'ceil', num_ceil, 0);
        rb_define_method(rb_cFloat, 'ceil', flo_ceil, 0);
        rb_define_method(rb_cInteger, 'ceil', int_to_i, 0);
      END
    end
    
    def center
      $mc.add_function :rb_str_center
      <<-END
        rb_define_method(rb_cString, 'center', rb_str_center, -1);
      END
    end
    
    def chars
      $mc.add_function :rb_str_each_char
      <<-END
        rb_define_method(rb_cString, 'chars', rb_str_each_char, 0);
      END
    end
    
    def choice
      $mc.add_function :rb_ary_choice
      <<-END
        rb_define_method(rb_cArray, 'choice', rb_ary_choice, 0);
      END
    end
    
    def chomp
      $mc.add_function :rb_str_chomp, :rb_f_chomp, :rb_define_global_function
      <<-END
        rb_define_method(rb_cString, 'chomp', rb_str_chomp, -1);
        rb_define_global_function('chomp', rb_f_chomp, -1);
      END
    end
    
    def chomp!
      $mc.add_function :rb_str_chomp_bang, :rb_f_chomp_bang
      <<-END
        rb_define_method(rb_cString, 'chomp!', rb_str_chomp_bang, -1);
        rb_define_global_function('chomp!', rb_f_chomp_bang, -1);
      END
    end
    
    def chop
      $mc.add_function :rb_str_chop, :rb_f_chop
      <<-END
        rb_define_method(rb_cString, 'chop', rb_str_chop, 0);
        rb_define_global_function('chop', rb_f_chop, 0);
      END
    end
    
    def chop!
      $mc.add_function :rb_str_chop_bang, :rb_f_chop_bang,
                       :rb_define_global_function
      <<-END
        rb_define_method(rb_cString, 'chop!', rb_str_chop_bang, 0);
        rb_define_global_function('chop!', rb_f_chop_bang, 0);
      END
    end
    
    def chr
      $mc.add_function :int_chr
      <<-END
        rb_define_method(rb_cInteger, 'chr', int_chr, 0);
      END
    end
    
    def class
      $mc.add_function :rb_obj_class, :elem_class_get
      <<-END
        rb_define_method(rb_mKernel, 'class', rb_obj_class, 0);
        rb_define_method(rb_cElement, 'class', elem_class_get, 0);
      END
    end
    
    def class=
      $mc.add_function :elem_class_set
      <<-END
        rb_define_method(rb_cElement, 'class=', elem_class_set, 1);
      END
    end
    
    def class_eval
      $mc.add_function :rb_mod_module_eval
      <<-END
        rb_define_method(rb_cModule, 'class_eval', rb_mod_module_eval, -1);
      END
    end
    
    def class_exec
      $mc.add_function :rb_mod_module_exec
      <<-END
        rb_define_method(rb_cModule, 'class_exec', rb_mod_module_exec, -1);
      END
    end
    
    def class_variable_defined?
      $mc.add_function :rb_mod_cvar_defined
      <<-END
        rb_define_method(rb_cModule, 'class_variable_defined?', rb_mod_cvar_defined, 1);
      END
    end
    
    def class_variable_get
      $mc.add_function :rb_mod_cvar_get, :rb_define_private_method
      <<-END
        rb_define_private_method(rb_cModule, 'class_variable_get', rb_mod_cvar_get, 1);
      END
    end
    
    def class_variable_set
      $mc.add_function :rb_mod_cvar_set, :rb_define_private_method
      <<-END
        rb_define_private_method(rb_cModule, 'class_variable_set', rb_mod_cvar_set, 2);
      END
    end
    
    def class_variables
      $mc.add_function :rb_mod_class_variables
      <<-END
        rb_define_method(rb_cModule, 'class_variables', rb_mod_class_variables, 0);
      END
    end
    
    def classes
      $mc.add_function :elem_classes_get
      <<-END
        rb_define_method(rb_cElement, 'classes', elem_classes_get, 0);
      END
    end
    
    def classes=
      $mc.add_function :elem_classes_set
      <<-END
        rb_define_method(rb_cElement, 'classes=', elem_classes_set, 1);
      END
    end
    
    def clear
      $mc.add_function :rb_hash_clear, :rb_ary_clear, :styles_clear
      <<-END
        rb_define_method(rb_cHash, 'clear', rb_hash_clear, 0);
        rb_define_method(rb_cArray, 'clear', rb_ary_clear, 0);
        rb_define_method(rb_cStyles, 'clear', styles_clear, 0);
      END
    end
    
    def clear_styles
      $mc.add_function :elem_clear_styles
      <<-END
        rb_define_method(rb_cElement, 'clear_styles', elem_clear_styles, 0);
      END
    end
    
    def client
      $mc.add_function :event_client
      <<-END
        rb_define_method(rb_cEvent, 'client', event_client, 0);
      END
    end
    
    def clone
      $mc.add_function :rb_obj_clone, :method_clone, :proc_clone
      <<-END
        rb_define_method(rb_cBinding, 'clone', proc_clone, 0);
        rb_define_method(rb_cMethod, 'clone', method_clone, 0);
        rb_define_method(rb_mKernel, 'clone', rb_obj_clone, 0);
        rb_define_method(rb_cUnboundMethod, 'clone', method_clone, 0);
        rb_define_method(rb_cProc, 'clone', proc_clone, 0);
      END
    end
    
    def code
      $mc.add_function :event_code
      <<-END
        rb_define_method(rb_cEvent, 'code', event_code, 0);
      END
    end
    
    def coerce
      $mc.add_function :num_coerce, :flo_coerce
      <<-END
        rb_define_method(rb_cNumeric, 'coerce', num_coerce, 1);
        rb_define_method(rb_cFloat, 'coerce', flo_coerce, 1);
      END
    end
    
    def collect
      $mc.add_function :enum_collect, :rb_ary_collect
      <<-END
        rb_define_method(rb_mEnumerable, 'collect', enum_collect, 0);
        rb_define_method(rb_cArray, 'collect', rb_ary_collect, 0);
      END
    end
    
    def collect!
      $mc.add_function :rb_ary_collect_bang
      <<-END
        rb_define_method(rb_cArray, 'collect!', rb_ary_collect_bang, 0);
      END
    end
    
    def combination
      $mc.add_function :rb_ary_combination
      <<-END
        rb_define_method(rb_cArray, 'combination', rb_ary_combination, 1);
      END
    end
    
    def compact
      $mc.add_function :rb_ary_compact
      <<-END
        rb_define_method(rb_cArray, 'compact', rb_ary_compact, 0);
      END
    end
    
    def compact!
      $mc.add_function :rb_ary_cmopact_bang
      <<-END
        rb_define_method(rb_cArray, 'compact!', rb_ary_compact_bang, 0);
      END
    end
    
    def concat
      $mc.add_function :rb_str_concat, :rb_ary_concat
      <<-END
        rb_define_method(rb_cString, 'concat', rb_str_concat, 1);
        rb_define_method(rb_cArray, 'concat', rb_ary_concat, 1);
      END
    end
    
    def const_defined?
      $mc.add_function :rb_mod_const_defined
      <<-END
        rb_define_method(rb_cModule, 'const_defined?', rb_mod_const_defined, 1);
      END
    end
    
    def const_get
      $mc.add_function :rb_mod_const_get
      <<-END
        rb_define_method(rb_cModule, 'const_get', rb_mod_const_get, 1);
      END
    end
    
    def const_missing
      $mc.add_function :rb_mod_const_missing
      <<-END
        rb_define_method(rb_cModule, 'const_missing', rb_mod_const_missing, 1);
      END
    end
    
    def const_set
      $mc.add_function :rb_mod_const_set
      <<-END
        rb_define_method(rb_cModule, 'const_set', rb_mod_const_set, 2);
      END
    end
    
    def constants
      $mc.add_function :rb_mod_constants, :rb_mod_s_constants, :rb_define_singleton_method
      <<-END
        rb_define_method(rb_cModule, 'constants', rb_mod_constants, 0);
        rb_define_singleton_method(rb_cModule, 'constants', rb_mod_s_constants, 0);
      END
    end
    
    def count
      $mc.add_function :enum_count, :rb_str_count, :rb_ary_count
      <<-END
        rb_define_method(rb_mEnumerable, 'count', enum_count, -1);
        rb_define_method(rb_cString, 'count', rb_str_count, -1);
        rb_define_method(rb_cArray, 'count', rb_ary_count, -1);
      END
    end
    
    def crypt
      $mc.add_function :rb_str_crypt
      <<-END
        rb_define_method(rb_cString, 'crypt', rb_str_crypt, 1);
      END
    end
    
    def ctime
      $mc.add_function :time_asctime
      <<-END
        rb_define_method(rb_cTime, "ctime", time_asctime, 0);
      END
    end
    
    def ctrl?
      $mc.add_function :event_ctrl
      <<-END
        rb_define_method(rb_cEvent, 'ctrl?', event_ctrl, 0);
      END
    end
    
    def cycle
      $mc.add_function :enum_cycle, :rb_ary_cycle
      <<-END
        rb_define_method(rb_cArray, 'cycle', rb_ary_cycle, -1);
        rb_define_method(rb_mEnumerable, 'cycle', enum_cycle, -1);
      END
    end
    
    def day
      $mc.add_function :time_mday
      <<-END
        rb_define_method(rb_cTime, "day", time_mday, 0);
      END
    end
    
    def default
      $mc.add_function :rb_hash_default
      <<-END
        rb_define_method(rb_cHash,'default', rb_hash_default, -1);
      END
    end
    
    def default=
      $mc.add_function :rb_hash_set_default
      <<-END
        rb_define_method(rb_cHash,'default=', rb_hash_set_default, 1);
      END
    end
    
    def default_proc
      $mc.add_function :rb_hash_default_proc
      <<-END
        rb_define_method(rb_cHash,'default_proc', rb_hash_default_proc, 0);
      END
    end
    
    def define
      $mc.add_function :uevent_s_define, :rb_define_module_function
      <<-END
        rb_define_module_function(rb_mUserEvent, 'define', uevent_s_define, 2);
      END
    end
    
    def define_method
      $mc.add_function :rb_define_private_method, :rb_mod_define_method
      <<-END
        rb_define_private_method(rb_cModule, 'define_method', rb_mod_define_method, -1);
      END
    end
    
    def delete
      $mc.add_function :rb_hash_delete, :rb_str_delete, :rb_ary_delete,
                       :styles_delete, :prop_delete
      <<-END
        rb_define_method(rb_cStyles, 'delete', styles_delete, 1);
        rb_define_method(rb_cProperties, 'delete', prop_delete, 1);
        rb_define_method(rb_cHash, 'delete', rb_hash_delete, 1);
        rb_define_method(rb_cString, 'delete', rb_str_delete, -1);
        rb_define_method(rb_cArray, 'delete', rb_ary_delete, 1);
      END
    end
    
    def delete!
      $mc.add_function :rb_str_delete_bang
      <<-END
        rb_define_method(rb_cString, 'delete!', rb_str_delete_bang, -1);
      END
    end
    
    def delete_at
      $mc.add_function :rb_ary_delete_at_m
      <<-END
        rb_define_method(rb_cArray, 'delete_at', rb_ary_delete_at_m, 1);
      END
    end
    
    def delete_if
      $mc.add_function :rb_hash_delete_if, :rb_ary_delete_if
      <<-END
        rb_define_method(rb_cHash,'delete_if', rb_hash_delete_if, 0);
        rb_define_method(rb_cArray, 'delete_if', rb_ary_delete_if, 0);
      END
    end
    
    def detect
      $mc.add_function :enum_find
      <<-END
        rb_define_method(rb_mEnumerable, 'detect', enum_find, -1);
      END
    end
    
    def div
      $mc.add_function :num_div, :fix_div
      <<-END
        rb_define_method(rb_cNumeric, 'div', num_div, 1);
        rb_define_method(rb_cFixnum, 'div', fix_div, 1);
      END
    end
    
    def divmod
      $mc.add_function :num_divmod, :fix_divmod, :flo_divmod
      <<-END
        rb_define_method(rb_cNumeric, 'divmod', num_divmod, 1);
        rb_define_method(rb_cFixnum, 'divmod', fix_divmod, 1);
        rb_define_method(rb_cFloat, 'divmod', flo_divmod, 1);
      END
    end
    
    def document
      $mc.add_function :doc_document, :rb_define_module_function
      <<-END
        rb_define_module_function(rb_mDocument, 'document', doc_document, 0);
      END
    end
    
    def downcase
      $mc.add_function :rb_str_downcase
      <<-END
        rb_define_method(rb_cString, 'downcase', rb_str_downcase, 0);
      END
    end
    
    def downcase!
      $mc.add_function :rb_str_downcase_bang
      <<-END
        rb_define_method(rb_cString, 'downcase!', rb_str_downcase_bang, 0);
      END
    end
    
    def downto
      $mc.add_function :int_downto
      <<-END
        rb_define_method(rb_cInteger, 'downto', int_downto, 1);
      END
    end
    
    def drop
      $mc.add_function :enum_drop, :rb_ary_drop
      <<-END
        rb_define_method(rb_mEnumerable, 'drop', enum_drop, 1);
        rb_define_method(rb_cArray, 'drop', rb_ary_drop, 1);
      END
    end
    
    def drop_while
      $mc.add_function :enum_drop_while, :rb_ary_drop_while
      <<-END
        rb_define_method(rb_mEnumerable, 'drop_while', enum_drop_while, 0);
        rb_define_method(rb_cArray, 'drop_while', rb_ary_drop_while, 0);
      END
    end
    
    def dst?
      $mc.add_function :time_isdst
      <<-END
        rb_define_method(rb_cTime, "dst?", time_isdst, 0);
      END
    end
    
    def dump
      $mc.add_function :rb_str_dump
      <<-END
        rb_define_method(rb_cString, 'dump', rb_str_dump, 0);
      END
    end
    
    def dup
      $mc.add_function :rb_obj_dup, :proc_dup
      <<-END
        rb_define_method(rb_mKernel, 'dup', rb_obj_dup, 0);
        rb_define_method(rb_cBinding, 'dup', proc_dup, 0);
        rb_define_method(rb_cProc, 'dup', proc_dup, 0);
      END
    end
    
    def each
      $mc.add_function :range_each, :rb_hash_each, :rb_str_each_line,
                       :rb_ary_each, :rb_struct_each, :enumerator_each
      <<-END
        rb_define_method(rb_cRange, 'each', range_each, 0);
        rb_define_method(rb_cStruct, 'each', rb_struct_each, 0);
        rb_define_method(rb_cEnumerator, 'each', enumerator_each, 0);
        rb_define_method(rb_cHash,'each', rb_hash_each, 0);
        rb_define_method(rb_cArray, 'each', rb_ary_each, 0);
        rb_define_method(rb_cString, 'each', rb_str_each_line, -1);
      END
    end
    
    def each_byte
      $mc.add_function :rb_str_each_byte
      <<-END
        rb_define_method(rb_cString, 'each_byte', rb_str_each_byte, 0);
      END
    end
    
    def each_char
      $mc.add_function :rb_str_each_char
      <<-END
        rb_define_method(rb_cString, 'each_char', rb_str_each_char, 0);
      END
    end
    
    def each_cons
      $mc.add_function :enum_each_cons
      <<-END
        rb_define_method(rb_mEnumerable, 'each_cons', enum_each_cons, 1);
      END
    end
    
    def each_index
      $mc.add_function :rby_ary_each_index
      <<-END
        rb_define_method(rb_cArray, 'each_index', rb_ary_each_index, 0);
      END
    end
    
    def each_key
      $mc.add_function :rb_hash_each_key
      <<-END
        rb_define_method(rb_cHash,'each_key', rb_hash_each_key, 0);
      END
    end
    
    def each_line
      $mc.add_function :rb_str_each_line
      <<-END
        rb_define_method(rb_cString, 'each_line', rb_str_each_line, -1);
      END
    end
    
    def each_pair
      $mc.add_function :rb_hash_each_pair, :rb_struct_each_pair
      <<-END
        rb_define_method(rb_cHash,'each_pair', rb_hash_each_pair, 0);
        rb_define_method(rb_cStruct, 'each_pair', rb_struct_each_pair, 0);
      END
    end
    
    def each_slice
      $mc.add_function :enum_each_slice
      <<-END
        rb_define_method(rb_mEnumerable, 'each_slice', enum_each_slice, 1);
      END
    end
    
    def each_value
      $mc.add_function :rb_hash_each_value
      <<-END
        rb_define_method(rb_cHash,'each_value', rb_hash_each_value, 0);
      END
    end
    
    def each_with_index
      $mc.add_function :enum_each_with_index, :enumerator_with_index
      <<-END
        rb_define_method(rb_mEnumerable, 'each_with_index', enum_each_with_index, 0);
        rb_define_method(rb_cEnumerator, 'each_with_index', enumerator_with_index, 0);
      END
    end
    
    def element
      $mc.add_function :styles_element, :classes_element, :prop_element
      <<-END
        rb_define_method(rb_cStyles, 'element', styles_element, 0);
        rb_define_method(rb_cClasses, 'element', classes_element, 0);
        rb_define_method(rb_cProperties, 'element', prop_element, 0);
      END
    end
    
    def empty?
      $mc.add_function :rb_hash_empty_p, :rb_str_empty, :rb_ary_empty_p
      <<-END
        rb_define_method(rb_cHash,'empty?', rb_hash_empty_p, 0);
        rb_define_method(rb_cArray, 'empty?', rb_ary_empty_p, 0);
        rb_define_method(rb_cString, 'empty?', rb_str_empty, 0);
      END
    end
    
    def end
      $mc.add_function :range_last
      <<-END
        rb_define_method(rb_cRange, 'end', range_last, 0);
      END
    end
    
    def end_with?
      $mc.add_function :rb_str_end_with
      <<-END
        rb_define_method(rb_cString, 'end_with?', rb_str_end_with, -1);
      END
    end
    
    def engine
      $mc.add_function :browser_engine, :rb_define_module_function
      <<-END
        rb_define_module_function(rb_mBrowser, 'engine', browser_engine, 0);
      END
    end
    
    def entries
      $mc.add_function :enum_to_a
      <<-END
        rb_define_method(rb_mEnumerable, 'entries', enum_to_a, -1);
      END
    end
    
    def enum_cons
      $mc.add_function :enum_each_cons
      <<-END
        rb_define_method(rb_mEnumerable, 'enum_cons', enum_each_cons, 1);
      END
    end
    
    def enum_for
      $mc.add_function :obj_to_enum
      <<-END
        rb_define_method(rb_mKernel, 'enum_for', obj_to_enum, -1);
      END
    end
    
    def enum_slice
      $mc.add_function :enum_each_slice
      <<-END
        rb_define_method(rb_mEnumerable, 'enum_slice', enum_each_slice, 1);
      END
    end
    
    def enum_with_index
      $mc.add_function :enum_each_with_index
      <<-END
        rb_define_method(rb_mEnumerable, 'enum_with_index', enum_each_with_index, 0);
      END
    end
    
    def eql?
      $mc.add_function :rb_obj_equal, :range_eql, :rb_hash_eql, :rb_str_eql,
                       :rb_ary_eql, :num_eql, :flo_eql, :rb_struct_eql,
                       :elem_eql, :time_eql
      <<-END
        rb_define_method(rb_cTime, "eql?", time_eql, 1);
        rb_define_method(rb_cElement, 'eql?', elem_eql, 1);
        rb_define_method(rb_cNumeric, 'eql?', num_eql, 1);
        rb_define_method(rb_cStruct, 'eql?', rb_struct_eql, 1);
        rb_define_method(rb_cRange, 'eql?', range_eql, 1);
        rb_define_method(rb_cString, 'eql?', rb_str_eql, 1);
        rb_define_method(rb_cArray, 'eql?', rb_ary_eql, 1);
        rb_define_method(rb_cHash,'eql?', rb_hash_eql, 1);
        rb_define_method(rb_cFloat, 'eql?', flo_eql, 1);
        rb_define_method(rb_mKernel, 'eql?', rb_obj_equal, 1);
      END
    end
    
    def equal?
      $mc.add_function :rb_obj_equal
      <<-END
        rb_define_method(rb_mKernel, 'equal?', rb_obj_equal, 1);
      END
    end
    
    def errno
      $mc.add_function :syserr_errno
      <<-END
        rb_define_method(rb_eSystemCallError, 'errno', syserr_errno, 0);
      END
    end
    
    def eval
      $mc.add_function :bind_eval, :rb_define_global_function, :rb_f_eval
      <<-END
        rb_define_method(rb_cBinding, 'eval', bind_eval, -1);
        rb_define_global_function('eval', rb_f_eval, -1);
      END
    end
    
    def even?
      $mc.add_function :int_even_p, :fix_even_p
      <<-END
        rb_define_method(rb_cInteger, 'even?', int_even_p, 0);
        rb_define_method(rb_cFixnum, 'even?', fix_even_p, 0);
      END
    end
    
    def exception
      $mc.add_function :rb_class_new_instance, :exc_exception, :rb_define_singleton_method
      <<-END
        rb_define_singleton_method(rb_eException, 'exception', rb_class_new_instance, -1);
        rb_define_method(rb_eException, 'exception', exc_exception, -1);
      END
    end
    
    def exclude_end?
      $mc.add_function :range_exclude_end_p
      <<-END
        rb_define_method(rb_cRange, 'exclude_end?', range_exclude_end_p, 0);
      END
    end
    
    def execute
      $mc.add_function :req_execute
      <<-END
        rb_define_method(rb_cRequest, 'execute', req_execute, 0);
      END
    end
    
    def execute_js
      $mc.add_function :doc_execute_js
      <<-END
        rb_define_module_function(rb_mDocument, 'execute_js', doc_execute_js, 1);
      END
    end
    
    def exit
      $mc.add_function :rb_define_global_function, :rb_f_exit
      <<-END
        rb_define_global_function('exit', rb_f_exit, -1);
      END
    end
    
    def exit_value
      $mc.add_function :localjump_xvalue
      <<-END
        rb_define_method(rb_eLocalJumpError, 'exit_value', localjump_xvalue, 0);
      END
    end
    
    def extend
      $mc.add_function :rb_define_method, :rb_obj_extend
      <<-END
        rb_define_method(rb_mKernel, 'extend', rb_obj_extend, -1);
      END
    end
    
    def extend_object
      $mc.add_function :rb_mod_extend_object, :rb_define_private_method
      <<-END
        rb_define_private_method(rb_cModule, 'extend_object', rb_mod_extend_object, 1);
      END
    end
    
    def extended
      $mc.add_functions :rb_obj_dummy, :rb_define_private_method
      <<-END
        rb_define_private_method(rb_cModule, 'extended', rb_obj_dummy, 1);
      END
    end
    
    def fail
      $mc.add_function :rb_f_raise, :rb_define_global_function
      <<-END
        rb_define_global_function('fail', rb_f_raise, -1);
      END
    end
    
    def fdiv
      $mc.add_function :num_quo
      <<-END
        rb_define_method(rb_cNumeric, 'fdiv', num_quo, 1);
      END
    end
    
    def fetch
      $mc.add_function :rb_hash_fetch, :rb_ary_fetch
      <<-END
        rb_define_method(rb_cHash,'fetch', rb_hash_fetch, -1);
        rb_define_method(rb_cArray, 'fetch', rb_ary_fetch, -1);
      END
    end
    
    def fdiv
      $mc.add_function :fix_quo
      <<-END
        rb_define_method(rb_cFixnum, 'fdiv', fix_quo, 1);
      END
    end
    
    def fill
      $mc.add_function :rb_ary_fill
      <<-END
        rb_define_method(rb_cArray, 'fill', rb_ary_fill, -1);
      END
    end
    
    def find
      $mc.add_functions :enum_find, :elem_find, :rb_define_singleton_method
      <<-END
        rb_define_method(rb_mEnumerable, 'find', enum_find, -1);
        rb_define_singleton_method(rb_cElement, 'find', elem_find, 1);
      END
    end
    
    def find_all
      $mc.add_functions :enum_find_all
      <<-END
        rb_define_method(rb_mEnumerable, 'find_all', enum_find_all, 0);
      END
    end
    
    def find_index
      $mc.add_function :enum_find_index, :rb_ary_index
      <<-END
        rb_define_method(rb_mEnumerable, 'find_index', enum_find_index, -1);
        rb_define_method(rb_cArray, 'find_index', rb_ary_index, -1);
      END
    end
    
    def finite
      $mc.add_function :flo_is_finite_p
      <<-END
        rb_define_method(rb_cFloat, 'finite?', flo_is_finite_p, 0);
      END
    end
    
    def fire
      $mc.add_function :cevent_fire
      <<-END
        rb_define_method(rb_mCodeEvent, 'fire', cevent_fire, -1);
      END
    end
    
    def first
      $mc.add_function :enum_first, :range_first, :rb_ary_first
      <<-END
        rb_define_method(rb_cRange, 'first', range_first, 0);
        rb_define_method(rb_cArray, 'first', rb_ary_first, -1);
        rb_define_method(rb_mEnumerable, 'first', enum_first, -1);
      END
    end
    
    def flatten
      $mc.add_function :rb_ary_flatten
      <<-END
        rb_define_method(rb_cArray, 'flatten', rb_ary_flatten, -1);
      END
    end
    
    def flatten!
      $mc.add_function :rb_ary_flatten_bang
      <<-END
        rb_define_method(rb_cArray, 'flatten!', rb_ary_flatten_bang, -1);
      END
    end
    
    def Float
      $mc.add_function :rb_f_float, :rb_define_global_function
      <<-END
        rb_define_global_function('Float', rb_f_float, 1);
      END
    end
    
    def floor
      $mc.add_function :num_floor, :int_to_i, :flo_floor
      <<-END
        rb_define_method(rb_cNumeric, 'floor', num_floor, 0);
        rb_define_method(rb_cFloat, 'floor', flo_floor, 0);
        rb_define_method(rb_cInteger, 'floor', int_to_i, 0);
      END
    end
    
    def format
      $mc.add_function :rb_f_sprintf, :rb_define_global_function
      <<-END
        rb_define_global_function('format', rb_f_sprintf, -1);
      END
    end
    
    def freeze
      $mc.add_function :rb_obj_freeze, :rb_mod_freeze
      <<-END
        rb_define_method(rb_cModule, 'freeze', rb_mod_freeze, 0);
        rb_define_method(rb_mKernel, 'freeze', rb_obj_freeze, 0);
      END
    end
    
    def frozen?
      $mc.add_function :rb_obj_frozen_p, :rb_ary_frozen_p
      <<-END
        rb_define_method(rb_mKernel, 'frozen?', rb_obj_frozen_p, 0);
        rb_define_method(rb_cArray, 'frozen?',  rb_ary_frozen_p, 0);
      END
    end
    
    def gecko?
      $mc.add_function :rb_f_gecko_p, :rb_define_global_function
      <<-END
        rb_define_global_function('gecko?', rb_f_gecko_p, -1);
      END
    end
    
    def get_property
      $mc.add_function :elem_get_property
      <<-END
        rb_define_method(rb_cElement, 'get_property', elem_get_property, 1);
      END
    end
    
    def get_style
      $mc.add_function :elem_get_style
      <<-END
        rb_define_method(rb_cElement, 'get_style', elem_get_style, 1);
      END
    end
    
    def getgm
      $mc.add_function :time_getgmtime
      <<-END
        rb_define_method(rb_cTime, "getgm", time_getgmtime, 0);
      END
    end
    
    def getlocal
      $mc.add_function :time_getlocaltime
      <<-END
        rb_define_method(rb_cTime, "getlocal", time_getlocaltime, 0);
      END
    end
    
    def getutc
      $mc.add_function :time_getgmtime
      <<-END
        rb_define_method(rb_cTime, "getutc", time_getgmtime, 0);
      END
    end
    
    def global_variables
      $mc.add_function :rb_define_global_function, :rb_f_global_variables
      <<-END
        rb_define_global_function('global_variables', rb_f_global_variables, 0);
      END
    end
    
    def gm
      $mc.add_function :time_s_mkutc
      <<-END
        rb_define_singleton_method(rb_cTime, "gm", time_s_mkutc, -1);
      END
    end
    
    def gmt_offset
      $mc.add_function :time_utc_offset
      <<-END
        rb_define_method(rb_cTime, "gmt_offset", time_utc_offset, 0);
      END
    end
    
    def gmt?
      $mc.add_function :time_utc_p
      <<-END
        rb_define_method(rb_cTime, "gmt?", time_utc_p, 0);
      END
    end
    
    def gmtime
      $mc.add_function :time_gmtime
      <<-END
        rb_define_method(rb_cTime, "gmtime", time_gmtime, 0);
      END
    end
    
    def gm_offset
      $mc.add_function :time_utc_offset
      <<-END
        rb_define_method(rb_cTime, "gmtoff", time_utc_offset, 0);
      END
    end
    
    def grep
      $mc.add_function :enum_grep
      <<-END
        rb_define_method(rb_mEnumerable, 'grep', enum_grep, 1);
      END
    end
    
    def group_by
      $mc.add_function :enum_group_by
      <<-END
        rb_define_method(rb_mEnumerable, 'group_by', enum_group_by, 0);
      END
    end
    
    def gsub
      $mc.add_function :rb_str_gsub, :rb_f_gsub, :rb_define_global_function
      <<-END
        rb_define_method(rb_cString, 'gsub', rb_str_gsub, -1);
        rb_define_global_function('gsub', rb_f_gsub, -1);
      END
    end
    
    def gsub!
      $mc.add_function :rb_str_gsub_bang, :rb_f_gsub_bang, :rb_define_global_function
      <<-END
        rb_define_method(rb_cString, 'gsub!', rb_str_gsub_bang, -1);
        rb_define_global_function('gsub!', rb_f_gsub_bang, -1);
      END
    end
    
    def has_class?
      $mc.add_function :elem_has_class_p
      <<-END
        rb_define_method(rb_cElement, 'has_class?', elem_has_class_p, 1);
      END
    end
    
    def has_key?
      $mc.add_function :rb_hash_has_key
      <<-END
        rb_define_method(rb_cHash,'has_key?', rb_hash_has_key, 1);
      END
    end
    
    def has_value?
      $mc.add_function :rb_hash_has_value
      <<-END
        rb_define_method(rb_cHash,'has_value?', rb_hash_has_value, 1);
      END
    end
    
    def hash
      $mc.add_function :rb_obj_id, :range_hash, :rb_hash_hash, :rb_str_hash_m,
                       :rb_ary_hash, :flo_hash, :rb_struct_hash, :time_hash
      <<-END
        rb_define_method(rb_cRange, 'hash', range_hash, 0);
        rb_define_method(rb_cStruct, 'hash', rb_struct_hash, 0);
        rb_define_method(rb_cTime, "hash", time_hash, 0);
        rb_define_method(rb_cString, 'hash', rb_str_hash_m, 0);
        rb_define_method(rb_mKernel, 'hash', rb_obj_id, 0);
        rb_define_method(rb_cFloat, 'hash', flo_hash, 0);
        rb_define_method(rb_cHash,'hash', rb_hash_hash, 0);
        rb_define_method(rb_cArray, 'hash', rb_ary_hash, 0);
      END
    end
    
    def head
      $mc.add_function :doc_head
      <<-END
        rb_define_module_function(rb_mDocument, 'head', doc_head, 0);
      END
    end
    
    def height
      $mc.add_function :doc_height, :elem_height
      <<-END
        rb_define_module_function(rb_mDocument, 'height', doc_height, 0);
        rb_define_method(rb_cElement, 'height', elem_height, 0);
      END
    end
    
    def hex
      $mc.add_function :rb_str_hex
      <<-END
        rb_define_method(rb_cString, 'hex', rb_str_hex, 0);
      END
    end
    
    def hour
      $mc.add_function :time_hour
      <<-END
        rb_define_method(rb_cTime, "hour", time_hour, 0);
      END
    end
    
    def html
      $mc.add_function :doc_html, :elem_html_get, :rb_define_module_function
      <<-END
        rb_define_module_function(rb_mDocument, 'html', doc_html, 0);
        rb_define_method(rb_cElement, 'html', elem_html_get, 0);
      END
    end
    
    def html=
      $mc.add_function :elem_html_set
      <<-END
        rb_define_method(rb_cElement, 'html=', elem_html_set, 1);
      END
    end
    
    def id
      $mc.add_function :elem_id
      <<-END
        rb_define_method(rb_cElement, 'id', elem_id, 0);
      END
    end
    
    def id2name
      $mc.add_functions :sym_to_s, :fix_id2name
      <<-END
        rb_define_method(rb_cSymbol, 'id2name', sym_to_s, 0);
        rb_define_method(rb_cFixnum, 'id2name', fix_id2name, 0);
      END
    end
    
    def ignore
      $mc.add_function :cevent_ignore
      <<-END
        rb_define_method(rb_mCodeEvent, 'ignore', cevent_ignore, 1);
      END
    end
    
    def include
      $mc.add_function :rb_mod_include, :rb_define_private_method, :rb_define_singleton_method, :top_include
      <<-END
        rb_define_private_method(rb_cModule, 'include', rb_mod_include, -1);
        rb_define_singleton_method(ruby_top_self, 'include', top_include, -1);
      END
    end
    
    def include?
      $mc.add_function :enum_member, :rb_mod_include_p, :range_include,
                       :rb_hash_has_key, :rb_str_include, :rb_ary_includes,
                       :classes_include_p
      <<-END
        rb_define_method(rb_cRange, 'include?', range_include, 1);
        rb_define_method(rb_cClasses, 'include?', classes_include_p, 1);
        rb_define_method(rb_cHash,'include?', rb_hash_has_key, 1);
        rb_define_method(rb_cArray, 'include?', rb_ary_includes, 1);
        rb_define_method(rb_cModule, 'include?', rb_mod_include_p, 1);
        rb_define_method(rb_cString, 'include?', rb_str_include, 1);
        rb_define_method(rb_mEnumerable, 'include?', enum_member, 1);
      END
    end
    
    def included
      $mc.add_functions :rb_obj_dummy, :rb_define_private_method, :rb_define_singleton_method, :prec_included
      <<-END
        rb_define_private_method(rb_cModule, 'included', rb_obj_dummy, 1);
        rb_define_singleton_method(rb_mPrecision, 'included', prec_included, 1);
      END
    end
    
    def included_modules
      $mc.add_function :rb_mod_included_modules
      <<-END
        rb_define_method(rb_cModule, 'included_modules', rb_mod_included_modules, 0);
      END
    end
    
    def index
      $mc.add_function :rb_hash_index, :rb_str_index_m, :rb_ary_index
      <<-END
        rb_define_method(rb_cArray, 'index', rb_ary_index, -1);
        rb_define_method(rb_cHash,'index', rb_hash_index, 1);
        rb_define_method(rb_cString, 'index', rb_str_index_m, -1);
      END
    end
    
    def indexes
      $mc.add_function :rb_hash_indexes, :rb_ary_indexes
      <<-END
        rb_define_method(rb_cHash,'indexes', rb_hash_indexes, -1);
        rb_define_method(rb_cArray, 'indexes', rb_ary_indexes, -1);
      END
    end
    
    def indices
      $mc.add_function :rb_hash_indexes, :rb_ary_indexes
      <<-END
        rb_define_method(rb_cHash,'indices', rb_hash_indexes, -1);
        rb_define_method(rb_cArray, 'indices', rb_ary_indexes, -1);
      END
    end
    
    def induced_from
      $mc.add_function :rb_int_induced_from, :rb_define_singleton_method, :rb_fix_induced_from, :rb_flo_induced_from
      <<-END
        rb_define_singleton_method(rb_cInteger, 'induced_from', rb_int_induced_from, 1);
        rb_define_singleton_method(rb_cFixnum, 'induced_from', rb_fix_induced_from, 1);
        rb_define_singleton_method(rb_cFloat, 'induced_from', rb_flo_induced_from, 1);
      END
    end
    
    def infinite?
      $mc.add_function :flo_is_infinite_p
      <<-END
        rb_define_method(rb_cFloat, 'infinite?', flo_is_infinite_p, 0);
      END
    end
    
    def inherited
      $mc.add_functions :rb_obj_dummy, :rb_define_private_method
      <<-END
        rb_define_private_method(rb_cClass, 'inherited', rb_obj_dummy, 1);
      END
    end
    
    def initialize
      $mc.add_function :rb_class_initialize, :rb_obj_dummy,
                       :rb_define_private_method, :rb_mod_initialize,
                       :range_initialize, :rb_hash_initialize, :rb_str_init,
                       :nometh_err_initialize, :syserr_initialize,
                       :exc_initialize, :name_err_initialize, :time_init,
                       :exit_initialize, :rb_ary_initialize, :rb_struct_initialize,
                       :enumerator_initialize, :elem_initialize, :req_initialize
      <<-END
        rb_define_method(rb_cRequest, 'initialize', req_initialize, -1);
        rb_define_method(rb_cTime, "initialize", time_init, 0);
        rb_define_method(rb_cElement, 'initialize', elem_initialize, 1);
        rb_define_method(rb_cEnumerator, 'initialize', enumerator_initialize, -1);
        rb_define_method(rb_cStruct, 'initialize', rb_struct_initialize, -2);
        rb_define_method(rb_cArray, 'initialize', rb_ary_initialize, -1);
        rb_define_method(rb_cHash,'initialize', rb_hash_initialize, -1);
        rb_define_method(rb_cRange, 'initialize', range_initialize, -1);
        rb_define_method(rb_cModule, 'initialize', rb_mod_initialize, 0);
        rb_define_method(rb_cClass, 'initialize', rb_class_initialize, -1);
        rb_define_private_method(rb_cObject, 'initialize', rb_obj_dummy, 0);
        rb_define_method(rb_cString, 'initialize', rb_str_init, -1);
        rb_define_method(rb_eNoMethodError, 'initialize', nometh_err_initialize, -1);
        rb_define_method(rb_eSystemCallError, 'initialize', syserr_initialize, -1);
        rb_define_method(rb_eException, 'initialize', exc_initialize, -1);
        rb_define_method(rb_eNameError, 'initialize', name_err_initialize, -1);
        rb_define_method(rb_eSystemExit, 'initialize', exit_initialize, -1);
      END
    end
    
    def initialize_copy
      $mc.add_function :rb_obj_init_copy, :rb_class_init_copy,
                       :rb_mod_init_copy, :rb_hash_replace, :rb_str_replace,
                       :rb_ary_replace, :num_init_copy, :rb_struct_init_copy,
                       :enumerator_init_copy, :time_init_copy
      <<-END
        rb_define_method(rb_cTime, "initialize_copy", time_init_copy, 1);
        rb_define_method(rb_cEnumerator, 'initialize_copy', enumerator_init_copy, 1);
        rb_define_method(rb_cStruct, 'initialize_copy', rb_struct_init_copy, 1);
        rb_define_method(rb_cHash,'initialize_copy', rb_hash_replace, 1);
        rb_define_method(rb_cArray, 'initialize_copy', rb_ary_replace, 1);
        rb_define_method(rb_cModule, 'initialize_copy', rb_mod_init_copy, 1);
        rb_define_method(rb_cClass, 'initialize_copy', rb_class_init_copy, 1);
        rb_define_method(rb_cNumeric, 'initialize_copy', num_init_copy, 1);
        rb_define_method(rb_mKernel, 'initialize_copy', rb_obj_init_copy, 1);
        rb_define_method(rb_cString, 'initialize_copy', rb_str_replace, 1);
      END
    end
    
    def inject
      $mc.add_function :enum_inject
      <<-END
        rb_define_method(rb_mEnumerable, 'inject', enum_inject, -1);
      END
    end
    
    def insert
      $mc.add_function :rb_str_insert, :rb_ary_insert, :elem_insert
      <<-END
        rb_define_method(rb_cElement, 'insert', elem_insert, -1);
        rb_define_method(rb_cString, 'insert', rb_str_insert, 2);
        rb_define_method(rb_cArray, 'insert', rb_ary_insert, -1);
      END
    end
    
    def inspect
      $mc.add_function :nil_inspect, :rb_obj_inspect, :range_inspect,
                       :sym_inspect, :method_inspect, :rb_hash_inspect,
                       :rb_str_inspect, :exc_inspect, :rb_ary_inspect,
                       :rb_struct_inspect, :time_to_s
      <<-END
        rb_define_method(rb_cTime, "inspect", time_to_s, 0);
        rb_define_method(rb_cStruct, 'inspect', rb_struct_inspect, 0);
        rb_define_method(rb_cArray, 'inspect', rb_ary_inspect, 0);
        rb_define_method(rb_cRange, 'inspect', range_inspect, 0);
        rb_define_method(rb_cString, 'inspect', rb_str_inspect, 0);
        rb_define_method(rb_eException, 'inspect', exc_inspect, 0);
        rb_define_method(rb_cHash,'inspect', rb_hash_inspect, 0);
        rb_define_method(rb_mKernel, 'inspect', rb_obj_inspect, 0);
        rb_define_method(rb_cMethod, 'inspect', method_inspect, 0);
        rb_define_method(rb_cNilClass, 'inspect', nil_inspect, 0);
        rb_define_method(rb_cSymbol, 'inspect', sym_inspect, 0);
        rb_define_method(rb_cUnboundMethod, 'inspect', method_inspect, 0);
      END
    end
    
    def instance_eval
      $mc.add_function :rb_obj_instance_eval
      <<-END
        rb_define_method(rb_mKernel, 'instance_eval', rb_obj_instance_eval, -1);
      END
    end
    
    def instance_exec
      $mc.add_function :rb_obj_instance_exec
      <<-END
        rb_define_method(rb_mKernel, 'instance_exec', rb_obj_instance_exec, -1);
      END
    end
    
    def instance_method
      $mc.add_function :rb_mod_method
      <<-END
        rb_define_method(rb_cModule, 'instance_method', rb_mod_method, 1);
      END
    end
    
    def instance_methods
      $mc.add_function :rb_class_instance_methods
      <<-END
        rb_define_method(rb_cModule, 'instance_methods', rb_class_instance_methods, -1);
      END
    end
    
    def instance_of?
      $mc.add_function :rb_obj_is_instance_of
      <<-END
        rb_define_method(rb_mKernel, 'instance_of?', rb_obj_is_instance_of, 1);
      END
    end
    
    def instance_variables
      $mc.add_function :rb_obj_instance_variables
      <<-END
        rb_define_method(rb_mKernel, 'instance_variables', rb_obj_instance_variables, 0);
      END
    end
    
    def instance_variable_get
      $mc.add_function :rb_obj_ivar_get
      <<-END
        rb_define_method(rb_mKernel, 'instance_variable_get', rb_obj_ivar_get, 1);
      END
    end
    
    def instance_variable_set
      $mc.add_function :rb_obj_ivar_set
      <<-END
        rb_define_method(rb_mKernel, 'instance_variable_set', rb_obj_ivar_set, 2);
      END
    end
    
    def instance_variable_defined?
      $mc.add_function :rb_obj_ivar_defined
      <<-END
        rb_define_method(rb_mKernel, 'instance_variable_defined?', rb_obj_ivar_defined, 1);
      END
    end
    
    def Integer
      $mc.add_function :rb_f_integer, :rb_define_global_function
      <<-END
        rb_define_global_function('Integer', rb_f_integer, 1);
      END
    end
    
    def integer?
      $mc.add_function :num_int_p, :int_int_p
      <<-END
        rb_define_method(rb_cInteger, 'integer?', int_int_p, 0);
        rb_define_method(rb_cNumeric, 'integer?', num_int_p, 0);
      END
    end
    
    def intern
      $mc.add_function :rb_str_intern
      <<-END
        rb_define_method(rb_cString, 'intern', rb_str_intern, 0);
      END
    end
    
    def invert
      $mc.add_function :rb_hash_invert
      <<-END
        rb_define_method(rb_cHash,'invert', rb_hash_invert, 0);
      END
    end
    
    def is_a?
      $mc.add_function :rb_obj_is_kind_of
      <<-END
        rb_define_method(rb_mKernel, 'is_a?', rb_obj_is_kind_of, 1);
      END
    end
    
    def isdst
      $mc.add_function :time_isdst
      <<-END
        rb_define_method(rb_cTime, "isdst", time_isdst, 0);
      END
    end
    
    def iterator
      $mc.add_function :rb_define_global_function, :rb_f_block_given_p
      <<-END
        rb_define_global_function('iterator?', rb_f_block_given_p, 0);
      END
    end
    
    def join
      $mc.add_function :rb_ary_join_m
      <<-END
        rb_define_method(rb_cArray, 'join', rb_ary_join_m, -1);
      END
    end
    
    def key
      $mc.add_function :event_key
      <<-END
        rb_define_method(rb_cEvent, 'key', event_key, 0);
      END
    end
    
    def key?
      $mc.add_function :rb_hash_has_key
      <<-END
        rb_define_method(rb_cHash,'key?', rb_hash_has_key, 1);
      END
    end
    
    def keys
      $mc.add_function :rb_hash_keys
      <<-END
        rb_define_method(rb_cHash,'keys', rb_hash_keys, 0);
      END
    end
    
    def kill!
      $mc.add_function :event_kill
      <<-END
        rb_define_method(rb_cEvent, 'kill!', event_kill, 0);
      END
    end
    
    def kind_of?
      $mc.add_function :rb_obj_is_kind_of
      <<-END
        rb_define_method(rb_mKernel, 'kind_of?', rb_obj_is_kind_of, 1);
      END
    end
    
    def lambda
      $mc.add_function :proc_lambda
      <<-END
        rb_define_global_function('lambda', proc_lambda, 0);
      END
    end
    
    def last
      $mc.add_function :range_last, :rb_ary_last
      <<-END
        rb_define_method(rb_cRange, 'last', range_last, 0);
        rb_define_method(rb_cArray, 'last', rb_ary_last, -1);
      END
    end
    
    def left
      $mc.add_function :doc_left, :rb_define_module_function, :elem_left
      <<-END
        rb_define_module_function(rb_mDocument, 'left', doc_left, 0);
        rb_define_method(rb_cElement, 'left', elem_left, 0);
      END
    end
    
    def length
      $mc.add_function :rb_hash_size, :rb_str_length, :rb_ary_length, :rb_struct_size
      <<-END
        rb_define_method(rb_cString, 'length', rb_str_length, 0);
        rb_define_method(rb_cStruct, 'length', rb_struct_size, 0);
        rb_define_method(rb_cHash,'length', rb_hash_size, 0);
        rb_define_method(rb_cArray, 'length', rb_ary_length, 0);
      END
    end
    
    def lines
      $mc.add_function :rb_str_each_line
      <<-END
        rb_define_method(rb_cString, 'lines', rb_str_each_line, -1);
      END
    end
    
    def listen
      $mc.add_function :uevent_listen
      <<-END
        rb_define_method(rb_mUserEvent, 'listen', uevent_listen, -1);
      END
    end
    
    def ljust
      $mc.add_function :rb_str_ljust
      <<-END
        rb_define_method(rb_cString, 'ljust', rb_str_ljust, -1);
      END
    end
    
    def local
      $mc.add_function :time_s_mktime, :rb_define_singleton_method
      <<-END
        rb_define_singleton_method(rb_cTime, "local", time_s_mktime, -1);
      END
    end
    
    def local_variables
      $mc.add_function :rb_define_global_function, :rb_f_local_variables
      <<-END
        rb_define_global_function('local_variables', rb_f_local_variables, 0);
      END
    end
    
    def localtime
      $mc.add_function :time_localtime
      <<-END
        rb_define_method(rb_cTime, "localtime", time_localtime, 0);
      END
    end
    
    def log
      $mc.add_function :rb_f_log
      <<-END
        rb_define_global_function('log', rb_f_log, 1);
      END
    end
    
    def loop
      $mc.add_function :rb_define_global_function, :rb_f_loop
      <<-END
        rb_define_global_function('loop', rb_f_loop, 0);
      END
    end
    
    def lstrip
      $mc.add_function :rb_str_lstrip
      <<-END
        rb_define_method(rb_cString, 'lstrip', rb_str_lstrip, 0);
      END
    end
    
    def lstrip!
      $mc.add_function :rb_str_lstrip_bang
      <<-END
        rb_define_method(rb_cString, 'lstrip!', rb_str_lstrip_bang, 0);
      END
    end
    
    def map
      $mc.add_function :enum_collect, :rb_ary_collect
      <<-END
        rb_define_method(rb_mEnumerable, 'map', enum_collect, 0);
        rb_define_method(rb_cArray, 'map', rb_ary_collect, 0);
      END
    end
    
    def map!
      $mc.add_function :rb_ary_collect_bang
      <<-END
        rb_define_method(rb_cArray, 'map!', rb_ary_collect_bang, 0);
      END
    end
    
    def match
      $mc.add_function :rb_str_match_m
      <<-END
        rb_define_method(rb_cString, 'match', rb_str_match_m, 1);
      END
    end
    
    def max
      $mc.add_function :enum_max
      <<-END
        rb_define_method(rb_mEnumerable, 'max', enum_max, 0);
      END
    end
    
    def max_by
      $mc.add_function :enum_max_by
      <<-END
        rb_define_method(rb_mEnumerable, 'max_by', enum_max_by, 0);
      END
    end
    
    def mday
      $mc.add_function :time_mday
      <<-END
        rb_define_method(rb_cTime, "mday", time_mday, 0);
      END
    end
    
    def member?
      $mc.add_function :enum_member, :range_include, :rb_hash_has_key
      <<-END
        rb_define_method(rb_cHash,'member?', rb_hash_has_key, 1);
        rb_define_method(rb_cRange, 'member?', range_include, 1);
        rb_define_method(rb_mEnumerable, 'member?', enum_member, 1);
      END
    end
    
    def members
      $mc.add_function :rb_struct_members_m
      <<-END
        rb_define_method(rb_cStruct, 'members', rb_struct_members_m, 0);
      END
    end
    
    def merge
      $mc.add_function :rb_hash_merge
      <<-END
        rb_define_method(rb_cHash,'merge', rb_hash_merge, 1);
      END
    end
    
    def merge!
      $mc.add_function :rb_hash_update
      <<-END
        rb_define_method(rb_cHash,'merge!', rb_hash_update, 1);
      END
    end
    
    def message
      $mc.add_function :exc_to_str
      <<-END
        rb_define_method(rb_eException, 'message', exc_to_str, 0);
      END
    end
    
    def meta?
      $mc.add_function :event_meta
      <<-END
        rb_define_method(rb_cEvent, 'meta?', event_meta, 0);
      END
    end
    
    def method
      $mc.add_function :rb_obj_method
      <<-END
        rb_define_method(rb_mKernel, 'method', rb_obj_method, 1);
      END
    end
    
    def method_added
      $mc.add_function :rb_define_private_method, :rb_obj_dummy
      <<-END
        rb_define_private_method(rb_cModule, 'method_added', rb_obj_dummy, 1);
      END
    end
    
    def method_defined?
      $mc.add_function :rb_mod_method_defined
      <<-END
        rb_define_method(rb_cModule, 'method_defined?', rb_mod_method_defined, 1);
      END
    end
    
    def method_missing(*x)
      $mc.add_function :rb_method_missing, :rb_define_global_function
      <<-END
        rb_define_global_function('method_missing', rb_method_missing, -1);
      END
    end
    
    def method_removed
      $mc.add_function :rb_obj_dummy, :rb_define_private_method
      <<-END
        rb_define_private_method(rb_cModule, 'method_removed', rb_obj_dummy, 1);
      END
    end
    
    def method_undefined
      $mc.add_function :rb_obj_dummy, :rb_define_private_method
      <<-END
        rb_define_private_method(rb_cModule, 'method_undefined', rb_obj_dummy, 1);
      END
    end
    
    def methods
      $mc.add_function :rb_obj_methods
      <<-END
        rb_define_method(rb_mKernel, 'methods', rb_obj_methods, -1);
      END
    end
    
    def min
      $mc.add_function :enum_min, :time_min
      <<-END
        rb_define_method(rb_mEnumerable, 'min', enum_min, 0);
        rb_define_method(rb_cTime, "min", time_min, 0);
      END
    end
    
    def min_by
      $mc.add_function :enum_min_by
      <<-END
        rb_define_method(rb_mEnumerable, 'min_by', enum_min_by, 0);
      END
    end
    
    def minmax
      $mc.add_function :enum_minmax
      <<-END
        rb_define_method(rb_mEnumerable, 'minmax', enum_minmax, 0);
      END
    end
    
    def minmax_by
      $mc.add_function :enum_minmax_by
      <<-END
        rb_define_method(rb_mEnumerable, 'minmax_by', enum_minmax_by, 0);
      END
    end
    
    def mktime
      $mc.add_function :time_s_mktime, :rb_define_singleton_method
      <<-END
        rb_define_singleton_method(rb_cTime, "mktime", time_s_mktime, -1);
      END
    end
    
    def module_eval
      $mc.add_function :rb_mod_module_eval
      <<-END
        rb_define_method(rb_cModule, 'module_eval', rb_mod_module_eval, -1);
      END
    end
    
    def module_exec
      $mc.add_function :rb_mod_module_exec
      <<-END
        rb_define_method(rb_cModule, 'module_exec', rb_mod_module_exec, -1);
      END
    end
    
    def module_function
      $mc.add_function :rb_mod_modfunc, :rb_define_private_method
      <<-END
        rb_define_private_method(rb_cModule, 'module_function', rb_mod_modfunc, -1);
      END
    end
    
    def modulo
      $mc.add_function :num_modulo, :fix_mod, :flo_mod
      <<-END
        rb_define_method(rb_cNumeric, 'modulo', num_modulo, 1);
        rb_define_method(rb_cFixnum, 'modulo', fix_mod, 1);
        rb_define_method(rb_cFloat, 'modulo', flo_mod, 1);
      END
    end
    
    def mon
      $mc.add_function :time_mon
      <<-END
        rb_define_method(rb_cTime, "mon", time_mon, 0);
      END
    end
    
    def month
      $mc.add_function :time_mon
      <<-END
        rb_define_method(rb_cTime, "month", time_mon, 0);
      END
    end
    
    def name
      $mc.add_function :method_name, :rb_mod_name, :name_err_name
      <<-END
        rb_define_method(rb_cModule, 'name', rb_mod_name, 0);
        rb_define_method(rb_eNameError, 'name', name_err_name, 0);
        rb_define_method(rb_cMethod, 'name', method_name, 0);
        rb_define_method(rb_cUnboundMethod, 'name', method_name, 0);
      END
    end
    
    def nan?
      $mc.add_function :flo_is_nan_p
      <<-END
        rb_define_method(rb_cFloat, 'nan?', flo_is_nan_p, 0);
      END
    end
    
    def nesting
      $mc.add_function :rb_define_singleton_method, :rb_mod_nesting
      <<-END
        rb_define_singleton_method(rb_cModule, 'nesting', rb_mod_nesting, 0);
      END
    end
    
    def new
      $mc.add_function :rb_class_new_instance, :proc_s_new, :rb_define_singleton_method, :rb_struct_s_def, :rb_io_s_new
      <<-END
        rb_define_method(rb_cClass, 'new', rb_class_new_instance, -1);
        rb_define_singleton_method(rb_cProc, 'new', proc_s_new, -1);
        rb_define_singleton_method(rb_cStruct, 'new', rb_struct_s_def, -1);
        rb_define_singleton_method(rb_cIO, 'new', rb_io_s_new, -1);
      END
    end
    
    def next
      $mc.add_function :rb_str_succ, :int_succ, :enumerator_next
      <<-END
        rb_define_method(rb_cString, 'next', rb_str_succ, 0);
        rb_define_method(rb_cEnumerator, 'next', enumerator_next, 0);
        rb_define_method(rb_cInteger, 'next', int_succ, 0);
      END
    end
    
    def next!
      $mc.add_function :rb_str_succ_bang
      <<-END
        rb_define_method(rb_cString, 'next!', rb_str_succ_bang, 0);
      END
    end
    
    def nil?
      $mc.add_function :rb_true
      <<-END
        rb_define_method(rb_mKernel, 'nil?', rb_false, 0);
        rb_define_method(rb_cNilClass, 'nil?', rb_true, 0);
      END
    end
    
    def nitems
      $mc.add_function :rby_ary_nitems
      <<-END
        rb_define_method(rb_cArray, 'nitems', rb_ary_nitems, 0);
      END
    end
    
    def none?
      $mc.add_function :enum_none
      <<-END
        rb_define_method(rb_mEnumerable, 'none?', enum_none, 0);
      END
    end
    
    def nonzero?
      $mc.add_function :num_nonzero_p
      <<-END
        rb_define_method(rb_cNumeric, 'nonzero?', num_nonzero_p, 0);
      END
    end
    
    def now
      $mc.add_function :rb_class_new_instance, :rb_define_singleton_method
      <<-END
        rb_define_singleton_method(rb_cTime, "now", rb_class_new_instance, -1);
      END
    end
    
    def object_id
      $mc.add_function :rb_obj_id
      <<-END
        rb_define_method(rb_mKernel, 'object_id', rb_obj_id, 0);
      END
    end
    
    def oct
      $mc.add_function :rb_str_oct
      <<-END
        rb_define_method(rb_cString, 'oct', rb_str_oct, 0);
      END
    end
    
    def odd?
      $mc.add_function :int_odd_p, :fix_odd_p
      <<-END
        rb_define_method(rb_cInteger, 'odd?', int_odd_p, 0);
        rb_define_method(rb_cFixnum, 'odd?', fix_odd_p, 0);
      END
    end
    
    def one?
      $mc.add_function :enum_one
      <<-END
        rb_define_method(rb_mEnumerable, 'one?', enum_one, 0);
      END
    end
    
    def ord
      $mc.add_function :int_ord
      <<-END
        rb_define_method(rb_cInteger, 'ord', int_ord, 0);
      END
    end
    
    def owner
      $mc.add_function :method_owner
      <<-END
        rb_define_method(rb_cUnboundMethod, 'owner', method_owner, 0);
        rb_define_method(rb_cMethod, 'owner', method_owner, 0);
      END
    end
    
    def pack
      $mc.add_function :pack_pack
      <<-END
        rb_define_method(rb_cArray, 'pack', pack_pack, 1);
      END
    end
    
    def page
      $mc.add_function :event_page
      <<-END
        rb_define_method(rb_cEvent, 'page', event_page, 0);
      END
    end
    
    def partition
      $mc.add_function :enum_partition, :rb_str_partition
      <<-END
        rb_define_method(rb_mEnumerable, 'partition', enum_partition, 0);
        rb_define_method(rb_cString, 'partition', rb_str_partition, -1);
      END
    end
    
    def permutation
      $mc.add_function :rb_ary_permutation
      <<-END
        rb_define_method(rb_cArray, 'permutation', rb_ary_permutation, -1);
      END
    end
    
    def platform
      $mc.add_function :rb_define_module_function, :browser_platform
      <<-END
        rb_define_module_function(rb_mBrowser, 'platform', browser_platform, 0);
      END
    end
    
    def prec
      $mc.add_function :prec_prec
      <<-END
        rb_define_method(rb_mPrecision, 'prec', prec_prec, 1);
      END
    end
    
    def prec_f
      $mc.add_function :prec_prec_f
      <<-END
        rb_define_method(rb_mPrecision, 'prec_f', prec_prec_f, 0);
      END
    end
    
    def prec_i
      $mc.add_function :prec_prec_i
      <<-END
        rb_define_method(rb_mPrecision, 'prec_i', prec_prec_i, 0);
      END
    end
    
    def properties
      $mc.add_function :elem_properties
      <<-END
        rb_define_method(rb_cElement, 'properties', elem_properties, 0);
      END
    end
    
    def pop
      $mc.add_function :rb_ary_pop_m
      <<-END
        rb_define_method(rb_cArray, 'pop', rb_ary_pop_m, -1);
      END
    end
    
    def pred
      $mc.add_function :int_pred
      <<-END
        rb_define_method(rb_cInteger, 'pred', int_pred, 0);
      END
    end
    
    def presto?
      $mc.add_function :rb_f_presto_p, :rb_define_global_function
      <<-END
        rb_define_global_function('presto?', rb_f_presto_p, -1);
      END
    end
    
    def prevent_default
      $mc.add_function :event_prevent_default
      <<-END
        rb_define_method(rb_cEvent, 'prevent_default', event_prevent_default, 0);
      END
    end
    
    def private
      $mc.add_function :rb_mod_private, :rb_define_private_method, :rb_define_singleton_method, :top_private
      <<-END
        rb_define_private_method(rb_cModule, 'private', rb_mod_private, -1);
        rb_define_singleton_method(ruby_top_self, 'private', top_private, -1);
      END
    end
    
    def private_class_method
      $mc.add_function :rb_mod_private_method
      <<-END
        rb_define_method(rb_cModule, 'private_class_method', rb_mod_private_method, -1);
      END
    end
    
    def private_instance_methods
      $mc.add_function :rb_class_private_instance_methods
      <<-END
        rb_define_method(rb_cModule, 'private_instance_methods', rb_class_private_instance_methods, -1);
      END
    end
    
    def private_method_defined?
      $mc.add_function :rb_mod_private_method_defined
      <<-END
        rb_define_method(rb_cModule, 'private_method_defined?', rb_mod_private_method_defined, 1);
      END
    end
    
    def private_methods
      $mc.add_function :rb_obj_private_methods
      <<-END
        rb_define_method(rb_mKernel, 'private_methods', rb_obj_private_methods, -1);
      END
    end
    
    def proc
      $mc.add_functions :proc_lambda, :rb_define_global_function
      <<-END
        rb_define_global_function('proc', proc_lambda, 0);
      END
    end
    
    def product
      $mc.add_function :rb_ary_product
      <<-END
        rb_define_method(rb_cArray, 'product', rb_ary_product, -1);
      END
    end
    
    def protected
      $mc.add_function :rb_mod_protected, :rb_define_private_method
      <<-END
        rb_define_private_method(rb_cModule, 'protected', rb_mod_protected, -1);
      END
    end
    
    def protected_instance_methods
      $mc.add_function :rb_class_protected_instance_methods
      <<-END
        rb_define_method(rb_cModule, 'protected_instance_methods', rb_class_protected_instance_methods, -1);
      END
    end
    
    def protected_method_defined?
      $mc.add_function :rb_mod_protected_method_defined
      <<-END
        rb_define_method(rb_cModule, 'protected_method_defined?', rb_mod_protected_method_defined, 1);
      END
    end
    
    def protected_methods
      $mc.add_function :rb_obj_protected_methods
      <<-END
        rb_define_method(rb_mKernel, 'protected_methods', rb_obj_protected_methods, -1);
      END
    end
    
    def public
      $mc.add_function :rb_mod_public, :rb_define_private_method, :rb_define_singleton_method, :top_public
      <<-END
        rb_define_private_method(rb_cModule, 'public', rb_mod_public, -1);
        rb_define_singleton_method(ruby_top_self, 'public', top_public, -1);
      END
    end
    
    def public_class_method
      $mc.add_function :rb_mod_public_method
      <<-END
        rb_define_method(rb_cModule, 'public_class_method', rb_mod_public_method, -1);
      END
    end
    
    def public_instance_methods
      $mc.add_function :rb_class_public_instance_methods
      <<-END
        rb_define_method(rb_cModule, 'public_instance_methods', rb_class_public_instance_methods, -1);
      END
    end
    
    def public_method_defined?
      $mc.add_function :rb_mod_public_method_defined
      <<-END
        rb_define_method(rb_cModule, 'public_method_defined?', rb_mod_public_method_defined, 1);
      END
    end
    
    def public_methods
      $mc.add_function :rb_obj_public_methods
      <<-END
        rb_define_method(rb_mKernel, 'public_methods', rb_obj_public_methods, -1);
      END
    end
    
    def push
      $mc.add_function :rb_ary_push_m
      <<-END
        rb_define_method(rb_cArray, 'push', rb_ary_push_m, -1);
      END
    end
    
    def puts
      $mc.add_method :to_s
      <<-END
      END
    end
    
    def query?
      $mc.add_function :rb_define_global_function, :rb_f_query_p
      <<-END
        rb_define_global_function('query?', rb_f_query_p, 0);
      END
    end
    
    def quo
      $mc.add_function :num_quo, :fix_quo
      <<-END
        rb_define_method(rb_cNumeric, 'quo', num_quo, 1);
        rb_define_method(rb_cFixnum, 'quo', fix_quo, 1);
      END
    end
    
    def raise
      $mc.add_function :rb_f_raise, :rb_define_global_function
      <<-END
        rb_define_global_function('raise', rb_f_raise, -1);
      END
    end
    
    def rand
      add_function :rb_define_global_function, :rb_f_rand
      <<-END
        rb_define_global_function('rand', rb_f_rand, -1);
      END
    end
    
    def rassoc
      $mc.add_function :rb_ary_rassoc
      <<-END
        rb_define_method(rb_cArray, 'rassoc', rb_ary_rassoc, 1);
      END
    end
    
    def ready?
      $mc.add_function :doc_ready_p
      <<-END
        rb_define_module_function(rb_mDocument, 'ready?', doc_ready_p, 0);
      END
    end
    
    def reason
      $mc.add_function :localjump_reason
      <<-END
        rb_define_method(rb_eLocalJumpError, 'reason', localjump_reason, 0);
      END
    end
    
    def receiver
      $mc.add_function :method_receiver
      <<-END
        rb_define_method(rb_cMethod, 'receiver', method_receiver, 0);
      END
    end
    
    def reduce
      $mc.add_function :enum_inject
      <<-END
        rb_define_method(rb_mEnumerable, 'reduce', enum_inject, -1);
      END
    end
    
    def rehash
      $mc.add_function :rb_hash_rehash
      <<-END
        rb_define_method(rb_cHash,'rehash', rb_hash_rehash, 0);
      END
    end
    
    def reject
      $mc.add_function :enum_reject, :rb_hash_reject, :rb_ary_reject
      <<-END
        rb_define_method(rb_cArray, 'reject', rb_ary_reject, 0);
        rb_define_method(rb_mEnumerable, 'reject', enum_reject, 0);
        rb_define_method(rb_cHash,'reject', rb_hash_reject, 0);
      END
    end
    
    def reject!
      $mc.add_function :rb_hash_reject_bang, :rb_ary_reject_bang
      <<-END
        rb_define_method(rb_cHash,'reject!', rb_hash_reject_bang, 0);
        rb_define_method(rb_cArray, 'reject!', rb_ary_reject_bang, 0);
      END
    end
    
    def related_target
      $mc.add_function :event_related_target
      <<-END
        rb_define_method(rb_cEvent, 'related_target', event_related_target, 0);
      END
    end
    
    def remainder
      $mc.add_function :num_remainder
      <<-END
        rb_define_method(rb_cNumeric, 'remainder', num_remainder, 1);
      END
    end
    
    def remove_class
      $mc.add_function :elem_remove_class
      <<-END
        rb_define_method(rb_cElement, 'remove_class', elem_remove_class, 1);
      END
    end
    
    def remove_class_variable
      $mc.add_function :rb_mod_remove_cvar, :rb_define_private_method
      <<-END
        rb_define_private_method(rb_cModule, 'remove_class_variable', rb_mod_remove_cvar, 1);
      END
    end
    
    def remove_classes
      $mc.add_function :elem_remove_classes
      <<-END
        rb_define_method(rb_cElement, 'remove_classes', elem_remove_classes, -1);
      END
    end
    
    def remove_const
      $mc.add_function :rb_mod_remove_const, :rb_define_private_method
      <<-END
        rb_define_private_method(rb_cModule, 'remove_const', rb_mod_remove_const, 1);
      END
    end
    
    def remove_instance_variable
      $mc.add_function :rb_obj_remove_instance_variable, :rb_define_private_method
      <<-END
        rb_define_private_method(rb_mKernel, 'remove_instance_variable', rb_obj_remove_instance_variable, 1);
      END
    end
    
    def remove_method
      $mc.add_function :rb_define_private_method, :rb_mod_remove_method
      <<-END
        rb_define_private_method(rb_cModule, 'remove_method', rb_mod_remove_method, -1);
      END
    end
    
    def remove_property
      $mc.add_function :elem_remove_property
      <<-END
        rb_define_method(rb_cElement, 'remove_property', elem_remove_property, 1);
      END
    end
    
    def remove_properties
      $mc.add_function :elem_remove_properties
      <<-END
        rb_define_method(rb_cElement, 'remove_properties', elem_remove_properties, -1);
      END
    end
    
    def remove_style
      $mc.add_function :elem_remove_style
      <<-END
        rb_define_method(rb_cElement, 'remove_style', elem_remove_style, 1);
      END
    end
    
    def remove_styles
      $mc.add_function :elem_remove_styles
      <<-END
        rb_define_method(rb_cElement, 'remove_styles', elem_remove_styles, -1);
      END
    end
    
    def replace
      $mc.add_function :rb_hash_replace, :rb_str_replace, :rb_ary_replace
      <<-END
        rb_define_method(rb_cString, 'replace', rb_str_replace, 1);
        rb_define_method(rb_cHash,'replace', rb_hash_replace, 1);
        rb_define_method(rb_cArray, 'replace', rb_ary_replace, 1);
      END
    end
    
    def respond_to?
      $mc.add_function :obj_respond_to
      <<-END
        rb_define_method(rb_mKernel, 'respond_to?', obj_respond_to, -1);
      END
    end
    
    def response
      $mc.add_function :req_response
      <<-END
        rb_define_method(rb_cRequest, 'response', req_response, 0);
      END
    end
    
    def reverse
      $mc.add_function :rb_str_reverse, :rb_ary_reverse_m
      <<-END
        rb_define_method(rb_cArray, 'reverse', rb_ary_reverse_m, 0);
        rb_define_method(rb_cString, 'reverse', rb_str_reverse, 0);
      END
    end
    
    def reverse!
      $mc.add_function :rb_str_reverse_bang, :rb_ary_reverse_bang
      <<-END
        rb_define_method(rb_cString, 'reverse!', rb_str_reverse_bang, 0);
        rb_define_method(rb_cArray, 'reverse!', rb_ary_reverse_bang, 0);
      END
    end
    
    def reverse_each
      $mc.add_function :enum_reverse_each, :rb_ary_reverse_each
      <<-END
        rb_define_method(rb_mEnumerable, 'reverse_each', enum_reverse_each, -1);
        rb_define_method(rb_cArray, 'reverse_each', rb_ary_reverse_each, 0);
      END
    end
    
    def rewind
      $mc.add_function :enumerator_rewind
      <<-END
        rb_define_method(rb_cEnumerator, 'rewind', enumerator_rewind, 0);
      END
    end
    
    def right_click?
      $mc.add_function :event_right_click
      <<-END
        rb_define_method(rb_cEvent, 'right_click?', event_right_click, 0);
      END
    end
    
    def rindex
      $mc.add_function :rb_str_rindex_m, :rb_ary_index
      <<-END
        rb_define_method(rb_cString, 'rindex', rb_str_rindex_m, -1);
        rb_define_method(rb_cArray, 'rindex', rb_ary_rindex, -1);
      END
    end
    
    def rjust
      $mc.add_function :rb_str_rjust
      <<-END
        rb_define_method(rb_cString, 'rjust', rb_str_rjust, -1);
      END
    end
    
    def round
      $mc.add_function :num_round, :int_to_i, :flo_round
      <<-END
        rb_define_method(rb_cNumeric, 'round', num_round, 0);
        rb_define_method(rb_cFloat, 'round', flo_round, 0);
        rb_define_method(rb_cInteger, 'round', int_to_i, 0);
      END
    end
    
    def rpartition
      $mc.add_function :rb_str_rpartition
      <<-END
        rb_define_method(rb_cString, 'rpartition', rb_str_rpartition, 1);
      END
    end
    
    def rstrip
      $mc.add_function :rb_rstrip
      <<-END
        rb_define_method(rb_cString, 'rstrip', rb_str_rstrip, 0);
      END
    end
    
    def rstrip!
      $mc.add_function :rb_rstrip_bang
      <<-END
        rb_define_method(rb_cString, 'rstrip!', rb_str_rstrip_bang, 0);
      END
    end
    
    def scan
      $mc.add_function :rb_str_scan, :rb_f_scan
      <<-END
        rb_define_method(rb_cString, 'scan', rb_str_scan, 1);
        rb_define_global_function('scan', rb_f_scan, 1);
      END
    end
    
    def scroll_height
      $mc.add_function :doc_scroll_height, :rb_define_module_function, :elem_scroll_height
      <<-END
        rb_define_module_function(rb_mDocument, 'scroll_height', doc_scroll_height, 0);
        rb_define_method(rb_cElement, 'scroll_height', elem_scroll_height, 0);
      END
    end
    
    def scroll_left
      $mc.add_function :doc_scroll_left, :rb_define_module_function, :elem_scroll_left
      <<-END
        rb_define_module_function(rb_mDocument, 'scroll_left', doc_scroll_left, 0);
        rb_define_method(rb_cElement, 'scroll_left', elem_scroll_left, 0);
      END
    end
    
    def scroll_to
      $mc.add_function :doc_scroll_to, :rb_define_module_function, :elem_scroll_to
      <<-END
        rb_define_module_function(rb_mDocument, 'scroll_to', doc_scroll_to, 2);
        rb_define_method(rb_cElement, 'scroll_to', elem_scroll_to, 2);
      END
    end
    
    def scroll_top
      $mc.add_function :doc_scroll_top, :rb_define_module_function, :elem_scroll_top
      <<-END
        rb_define_module_function(rb_mDocument, 'scroll_top', doc_scroll_top, 0);
        rb_define_method(rb_cElement, 'scroll_top', elem_scroll_top, 0);
      END
    end
    
    def scroll_width
      $mc.add_function :doc_scroll_width, :rb_define_module_function, :elem_scroll_width
      <<-END
        rb_define_module_function(rb_mDocument, 'scroll_width', doc_scroll_width, 0);
        rb_define_method(rb_cElement, 'scroll_width', elem_scroll_width, 0);
      END
    end
    
    def sec
      $mc.add_function :time_sec
      <<-END
        rb_define_method(rb_cTime, "sec", time_sec, 0);
      END
    end
    
    def send
      $mc.add_function :rb_f_send
      <<-END
        rb_define_method(rb_mKernel, 'send', rb_f_send, -1);
      END
    end
    
    def select
      $mc.add_function :enum_find_all, :rb_hash_select, :rb_ary_select, :rb_struct_select
      <<-END
        rb_define_method(rb_cStruct, 'select', rb_struct_select, -1);
        rb_define_method(rb_mEnumerable, 'select', enum_find_all, 0);
        rb_define_method(rb_cHash,'select', rb_hash_select, 0);
        rb_define_method(rb_cArray, 'select', rb_ary_select, 0);
      END
    end
    
    def set?
      $mc.add_function :styles_set_p, :prop_set_p
      <<-END
        rb_define_method(rb_cStyles, 'set?', styles_set_p, 1);
        rb_define_method(rb_cProperties, 'set?', prop_set_p, 1);
      END
    end
    
    def set_backtrace
      $mc.add_function :exc_set_backtrace
      <<-END
        rb_define_method(rb_eException, 'set_backtrace', exc_set_backtrace, 1);
      END
    end
    
    def set_opacity
      $mc.add_function :elem_set_opacity
      <<-END
        rb_define_method(rb_cElement, 'set_opacity', elem_set_opacity, -1);
      END
    end
    
    def set_property
      $mc.add_function :elem_set_property
      <<-END
        rb_define_method(rb_cElement, 'set_property', elem_set_property, 2);
      END
    end
    
    def set_properties
      $mc.add_function :elem_set_properties
      <<-END
        rb_define_method(rb_cElement, 'set_properties', elem_set_properties, 1);
      END
    end
    
    def set_style
      $mc.add_function :elem_set_style
      <<-END
        rb_define_method(rb_cElement, 'set_style', elem_set_style, 2);
      END
    end
    
    def set_styles
      $mc.add_function :elem_set_styles
      <<-END
        rb_define_method(rb_cElement, 'set_styles', elem_set_styles, 1);
      END
    end
    
    def shift
      $mc.add_function :rb_hash_shift, :rb_ary_shift_m
      <<-END
        rb_define_method(rb_cHash,'shift', rb_hash_shift, 0);
        rb_define_method(rb_cArray, 'shift', rb_ary_shift_m, -1);
      END
    end
    
    def shift?
      $mc.add_function :event_shift
      <<-END
        rb_define_method(rb_cEvent, 'shift?', event_shift, 0);
      END
    end
    
    def shuffle
      $mc.add_function :rb_ary_shuffle
      <<-END
        rb_define_method(rb_cArray, 'shuffle', rb_ary_shuffle, 0);
      END
    end
    
    def shuffle!
      $mc.add_function :rb_ary_shuffle_bang
      <<-END
        rb_define_method(rb_cArray, 'shuffle!', rb_ary_shuffle_bang, 0);
      END
    end
    
    def singleton_method_added(*x)
      return unless $mc
      $mc.add_function :rb_obj_dummy, :rb_define_private_method, :num_sadded
      <<-END
        rb_define_private_method(rb_mKernel, 'singleton_method_added', rb_obj_dummy, 1);
        rb_define_method(rb_cNumeric, 'singleton_method_added', num_sadded, 1);
      END
    end
    
    def singleton_method_removed
      $mc.add_function :rb_obj_dummy, :rb_define_private_method
      <<-END
        rb_define_private_method(rb_mKernel, 'singleton_method_removed', rb_obj_dummy, 1);
      END
    end
    
    def singleton_method_undefined
      $mc.add_function :rb_obj_dummy, :rb_define_private_method
      <<-END
        rb_define_private_method(rb_mKernel, 'singleton_method_undefined', rb_obj_dummy, 1);
      END
    end
    
    def singleton_methods
      $mc.add_function :rb_obj_singleton_methods
      <<-END
        rb_define_method(rb_mKernel, 'singleton_methods', rb_obj_singleton_methods, -1);
      END
    end
    
    def size
      $mc.add_function :rb_hash_size, :rb_str_length, :fix_size, :rb_struct_size
      $mc.add_method :rb_ary_length
      <<-END
        rb_define_method(rb_cStruct, 'size', rb_struct_size, 0);
        rb_define_method(rb_cHash,'size', rb_hash_size, 0);
        rb_define_method(rb_cString, 'size', rb_str_length, 0);
        rb_define_alias(rb_cArray,  'size', 'length');
        rb_define_method(rb_cFixnum, 'size', fix_size, 0);
      END
    end
    
    def slice
      $mc.add_function :rb_str_aref_m, :rb_ary_aref
      <<-END
        rb_define_method(rb_cString, 'slice', rb_str_aref_m, -1);
        rb_define_method(rb_cArray, 'slice', rb_ary_aref, -1);
      END
    end
    
    def slice!
      $mc.add_function :rb_str_slice_bang, :rb_ary_slice_bang
      <<-END
        rb_define_method(rb_cString, 'slice!', rb_str_slice_bang, -1);
        rb_define_method(rb_cArray, 'slice!', rb_ary_slice_bang, -1);
      END
    end
    
    def sort
      $mc.add_function :enum_sort, :rb_hash_sort, :rb_ary_sort
      <<-END
        rb_define_method(rb_mEnumerable, 'sort', enum_sort, 0);
        rb_define_method(rb_cHash,'sort', rb_hash_sort, 0);  
        rb_define_method(rb_cArray, 'sort', rb_ary_sort, 0);
      END
    end
    
    def sort!
      $mc.add_function :rb_ary_sort_bang
      <<-END
        rb_define_method(rb_cArray, 'sort!', rb_ary_sort_bang, 0);
      END
    end
    
    def sort_by
      $mc.add_function :enum_sort_by
      <<-END
        rb_define_method(rb_mEnumerable, 'sort_by', enum_sort_by, 0);
      END
    end
    
    def split
      $mc.add_function :rb_str_split_m, :rb_define_global_function
      <<-END
        rb_define_method(rb_cString, 'split', rb_str_split_m, -1);
        rb_define_global_function('split', rb_f_split, -1);
      END
    end
    
    def sprintf
      $mc.add_function :rb_f_sprintf, :rb_define_global_function
      <<-END
        rb_define_global_function('sprintf', rb_f_sprintf, -1);
      END
    end
    
    def squeeze
      $mc.add_function :rb_str_squeeze
      <<-END
        rb_define_method(rb_cString, 'squeeze', rb_str_squeeze, -1);
      END
    end
    
    def squeeze!
      $mc.add_function :rb_str_squeeze_bang
      <<-END
        rb_define_method(rb_cString, 'squeeze!', rb_str_squeeze_bang, -1);
      END
    end
    
    def srand
      add_function :rb_define_global_function, :rb_f_srand
      <<-END
        rb_define_global_function('srand', rb_f_srand, -1);
      END
    end
    
    def start_with?
      $mc.add_function :rb_str_start_with
      <<-END
        rb_define_method(rb_cString, 'start_with?', rb_str_start_with, -1);
      END
    end
    
    def status
      $mc.add_function :exit_status
      <<-END
        rb_define_method(rb_eSystemExit, 'status', exit_status, 0);
      END
    end
    
    def step
      $mc.add_function :range_step, :num_step
      <<-END
        rb_define_method(rb_cRange, 'step', range_step, -1);
        rb_define_method(rb_cNumeric, 'step', num_step, -1);
      END
    end
    
    def stop_propagation
      $mc.add_function :event_stop_propagation
      <<-END
        rb_define_method(rb_cEvent, 'stop_propagation', event_stop_propagation, 0);
      END
    end
    
    def store
      $mc.add_function :rb_hash_aset
      <<-END
        rb_define_method(rb_cHash,'store', rb_hash_aset, 2);
      END
    end
    
    def strftime
      $mc.add_function :time_strftime
      <<-END
        rb_define_method(rb_cTime, "strftime", time_strftime, 1);
      END
    end
    
    def String
      $mc.add_function :rb_f_string, :rb_define_global_function
      <<-END
        rb_define_global_function('String', rb_f_string, 1);
      END
    end
    
    def strip
      $mc.add_function :rb_str_strip
      <<-END
        rb_define_method(rb_cString, 'strip', rb_str_strip, 0);
      END
    end
    
    def strip!
      $mc.add_function :rb_str_strip_bang
      <<-END
        rb_define_method(rb_cString, 'strip!', rb_str_strip_bang, 0);
      END
    end
    
    def style
      $mc.add_function :elem_style_get
      <<-END
        rb_define_method(rb_cElement, 'style', elem_style_get, 0);
      END
    end
    
    def style=
      $mc.add_function :elem_style_set
      <<-END
        rb_define_method(rb_cElement, 'style=', elem_style_set, 1);
      END
    end
    
    def styles
      $mc.add_function :elem_styles
      <<-END
        rb_define_method(rb_cElement, 'styles', elem_styles, 0);
      END
    end
    
    def sub
      $mc.add_function :rb_str_sub, :rb_f_sub, :rb_define_global_function
      <<-END
        rb_define_method(rb_cString, 'sub', rb_str_sub, -1);
        rb_define_global_function('sub', rb_f_sub, -1);
      END
    end
    
    def sub!
      $mc.add_function :rb_str_sub_bang, :rb_f_sub_bang,
                       :rb_define_global_function
      <<-END
        rb_define_method(rb_cString, 'sub!', rb_str_sub_bang, -1);
        rb_define_global_function('sub!', rb_f_sub_bang, -1);
      END
    end
    
    def succ
      $mc.add_function :rb_str_succ, :int_succ, :time_succ
      <<-END
        rb_define_method(rb_cTime, "succ", time_succ, 0);
        rb_define_method(rb_cString, 'succ', rb_str_succ, 0);
        rb_define_method(rb_cInteger, 'succ', int_succ, 0);
      END
    end
    
    def succ!
      $mc.add_function :rb_str_succ_bang
      <<-END
        rb_define_method(rb_cString, 'succ!', rb_str_succ_bang, 0);
      END
    end
    
    def success?
      $mc.add_function :exit_success_p
      <<-END
        rb_define_method(rb_eSystemExit, 'success?', exit_success_p, 0);
      END
    end
    
    def sum
      $mc.add_function :rb_str_sum
      <<-END
        rb_define_method(rb_cString, 'sum', rb_str_sum, -1);
      END
    end
    
    def superclass
      $mc.add_function :rb_class_superclass
      <<-END
        rb_define_method(rb_cClass, 'superclass', rb_class_superclass, 0);
      END
    end
    
    def swapcase
      $mc.add_function :rb_str_swapcase
      <<-END
        rb_define_method(rb_cString, 'swapcase', rb_str_swapcase, 0);
      END
    end
    
    def swapcase!
      $mc.add_function :rb_str_swapcase_bang
      <<-END
        rb_define_method(rb_cString, 'swapcase!', rb_str_swapcase_bang, 0);
      END
    end
    
    def taint
      $mc.add_function :rb_obj_taint
      <<-END
        rb_define_method(rb_mKernel, 'taint', rb_obj_taint, 0);
      END
    end
    
    def tainted?
      $mc.add_function :rb_obj_tainted
      <<-END
        rb_define_method(rb_mKernel, 'tainted?', rb_obj_tainted, 0);
      END
    end
    
    def take
      $mc.add_function :enum_take, :rb_ary_take
      <<-END
        rb_define_method(rb_mEnumerable, 'take', enum_take, 1);
        rb_define_method(rb_cArray, 'take', rb_ary_take, 1);
      END
    end
    
    def take_while
      $mc.add_function :enum_take_while, :rb_ary_take_while
      <<-END
        rb_define_method(rb_mEnumerable, 'take_while', enum_take_while, 0);
        rb_define_method(rb_cArray, 'take_while', rb_ary_take_while, 0);
      END
    end
    
    def tap
      $mc.add_function :rb_obj_tap
      <<-END
        rb_define_method(rb_mKernel, 'tap', rb_obj_tap, 0);
      END
    end
    
    def target
      $mc.add_function :event_target
      <<-END
        rb_define_method(rb_cEvent, 'target', event_target, 0);
      END
    end
    
    def text
      $mc.add_function :resp_text, :elem_text_get
      <<-END
        rb_define_method(rb_cElement, 'text', elem_text_get, 0);
        rb_define_method(rb_cResponse, 'text', resp_text, 0);
      END
    end
    
    def text=
      $mc.add_function :elem_text_set
      <<-END
        rb_define_method(rb_cElement, 'text=', elem_text_set, 1);
      END
    end
    
    def throw
      $mc.add_function :rb_define_global_function, :rb_f_throw
      <<-END
        rb_define_global_function('throw', rb_f_throw, -1);
      END
    end
    
    def times
      $mc.add_function :int_dotimes
      <<-END
        rb_define_method(rb_cInteger, 'times', int_dotimes, 0);
      END
    end
    
    def title
      $mc.add_function :doc_title
      <<-END
        rb_define_module_function(rb_mDocument, 'title', doc_title, 0);
      END
    end
    
    def to_a
      $mc.add_function :nil_to_a, :enum_to_a, :rb_hash_to_a, :rb_ary_to_a,
                       :rb_struct_to_a, :time_to_a
      <<-END
        rb_define_method(rb_cStruct, 'to_a', rb_struct_to_a, 0);
        rb_define_method(rb_cTime, "to_a", time_to_a, 0);
        rb_define_method(rb_mEnumerable, 'to_a', enum_to_a, -1);
        rb_define_method(rb_cHash,'to_a', rb_hash_to_a, 0);
        rb_define_method(rb_cNilClass, 'to_a', nil_to_a, 0);
        rb_define_method(rb_cArray, 'to_a', rb_ary_to_a, 0);
      END
    end
    
    def to_ary
      $mc.add_function :rb_ary_to_ary_m
      <<-END
        rb_define_method(rb_cArray, 'to_ary', rb_ary_to_ary_m, 0);
      END
    end
    
    def to_enum
      $mc.add_function :obj_to_enum
      <<-END
        rb_define_method(rb_mKernel, 'to_enum', obj_to_enum, -1);
      END
    end
    
    def to_f
      $mc.add_function :nil_to_f, :rb_str_to_f, :fix_to_f, :flo_to_f, :time_to_f
      <<-END
        rb_define_method(rb_cNilClass, 'to_f', nil_to_f, 0);
        rb_define_method(rb_cFixnum, 'to_f', fix_to_f, 0);
        rb_define_method(rb_cFloat, 'to_f', flo_to_f, 0);
        rb_define_method(rb_cTime, "to_f", time_to_f, 0);
        rb_define_method(rb_cString, 'to_f', rb_str_to_f, 0);
      END
    end
    
    def to_hash
      $mc.add_function :rb_hash_to_hash
      <<-END
        rb_define_method(rb_cHash,'to_hash', rb_hash_to_hash, 0);
      END
    end
    
    def to_i
      $mc.add_function :nil_to_i, :sym_to_i, :rb_str_to_i, :int_to_i,
                       :flo_truncate, :time_to_i
      <<-END
        rb_define_method(rb_cNilClass, 'to_i', nil_to_i, 0);
        rb_define_method(rb_cFloat, 'to_i', flo_truncate, 0);
        rb_define_method(rb_cTime, "to_i", time_to_i, 0);
        rb_define_method(rb_cInteger, 'to_i', int_to_i, 0);
        rb_define_method(rb_cString, 'to_i', rb_str_to_i, -1);
        rb_define_method(rb_cSymbol, 'to_i', sym_to_i, 0);
      END
    end
    
    def to_int
      $mc.add_function :sym_to_int, :num_to_int, :int_to_i, :flo_truncate
      <<-END
        rb_define_method(rb_cSymbol, 'to_int', sym_to_int, 0);
        rb_define_method(rb_cInteger, 'to_int', int_to_i, 0);
        rb_define_method(rb_cFloat, 'to_int', flo_truncate, 0);
        rb_define_method(rb_cNumeric, 'to_int', num_to_int, 0);
      END
    end
    
    def to_proc
      $mc.add_function :sym_to_proc, :method_proc, :proc_to_self
      <<-END
        rb_define_method(rb_cSymbol, 'to_proc', sym_to_proc, 0);
        rb_define_method(rb_cMethod, 'to_proc', method_proc, 0);
        rb_define_method(rb_cProc, 'to_proc', proc_to_self, 0);
      END
    end
    
    def to_s
      $mc.add_functions :rb_ary_to_s, :exc_to_s, :false_to_s, :rb_hash_to_s,
                        :rb_mod_to_s, :nil_to_s, :fix_to_s, :rb_any_to_s,
                        :sym_to_s, :true_to_s, :method_inspect, :proc_to_s,
                        :range_to_s, :rb_str_to_s, :name_err_to_s, :flo_to_s,
                        :rb_struct_inspect, :elem_to_s, :time_to_s,
                        :rb_big_to_s
      <<-END
        rb_define_method(rb_cElement, 'to_s', elem_to_s, 0);
        rb_define_method(rb_cArray, 'to_s', rb_ary_to_s, 0);
        rb_define_method(rb_cStruct, 'to_s', rb_struct_inspect, 0);
        rb_define_method(rb_eException, 'to_s', exc_to_s, 0);
        rb_define_method(rb_cTime, "to_s", time_to_s, 0);
        rb_define_method(rb_cBignum, "to_s", rb_big_to_s, -1);
        rb_define_method(rb_cFloat, 'to_s', flo_to_s, 0);
        rb_define_method(rb_cFalseClass, 'to_s', false_to_s, 0);
        rb_define_method(rb_cHash,'to_s', rb_hash_to_s, 0);
        rb_define_method(rb_cMethod, 'to_s', method_inspect, 0);
        rb_define_method(rb_cModule, 'to_s', rb_mod_to_s, 0);
        rb_define_method(rb_cNilClass, 'to_s', nil_to_s, 0);
        rb_define_method(rb_cFixnum, 'to_s', fix_to_s, -1);
        rb_define_method(rb_mKernel, 'to_s', rb_any_to_s, 0);
        rb_define_method(rb_cRange, 'to_s', range_to_s, 0);
        rb_define_method(rb_cString, 'to_s', rb_str_to_s, 0);
        rb_define_method(rb_cSymbol, 'to_s', sym_to_s, 0);
        rb_define_method(rb_cTrueClass, 'to_s', true_to_s, 0);
        rb_define_method(rb_cUnboundMethod, 'to_s', method_inspect, 0);
        rb_define_method(rb_eNameError, 'to_s', name_err_to_s, 0);
      END
    end
    
    def to_str
      $mc.add_function :rb_str_to_s, :name_err_mesg_to_str, :exc_to_str
      <<-END
        rb_define_method(rb_cString, 'to_str', rb_str_to_s, 0);
        rb_define_method(rb_cNameErrorMesg, 'to_str', name_err_mesg_to_str, 0);
        rb_define_method(rb_eException, 'to_str', exc_to_str, 0);
      END
    end
    
    def to_sym
      $mc.add_function :sym_to_sym, :rb_str_intern, :fix_to_sym
      <<-END
        rb_define_method(rb_cSymbol, 'to_sym', sym_to_sym, 0);
        rb_define_method(rb_cString, 'to_sym', rb_str_intern, 0);
        rb_define_method(rb_cFixnum, 'to_sym', fix_to_sym, 0);
      END
    end
    
    def toggle
      $mc.add_function :classes_toggle
      <<-END
        rb_define_method(rb_cClasses, 'toggle', classes_toggle, 1);
      END
    end
    
    def toggle_class
      $mc.add_function :elem_toggle_class
      <<-END
        rb_define_method(rb_cElement, 'toggle_class', elem_toggle_class, 1);
      END
    end
    
    def top
      $mc.add_function :doc_top, :rb_define_module_function, :elem_top
      <<-END
        rb_define_module_function(rb_mDocument, 'top', doc_top, 0);
        rb_define_method(rb_cElement, 'top', elem_top, 0);
      END
    end
    
    def tr
      $mc.add_function :rb_str_tr
      <<-END
        rb_define_method(rb_cString, 'tr', rb_str_tr, 2);
      END
    end
    
    def tr!
      $mc.add_function :rb_str_tr_bang
      <<-END
        rb_define_method(rb_cString, 'tr!', rb_str_tr_bang, 2);
      END
    end
    
    def tr_s
      $mc.add_function :rb_str_tr_s
      <<-END
        rb_define_method(rb_cString, 'tr_s', rb_str_tr_s, 2);
      END
    end
    
    def tr_s!
      $mc.add_function :rb_str_t_s_bang
      <<-END
        rb_define_method(rb_cString, 'tr_s!', rb_str_tr_s_bang, 2);
      END
    end
    
    def transpose
      $mc.add_function :rb_ary_transpose
      <<-END
        rb_define_method(rb_cArray, 'transpose', rb_ary_transpose, 0);
      END
    end
    
    def trident?
      $mc.add_function :rb_f_trident_p, :rb_define_global_function
      <<-END
        rb_define_global_function('trident?', rb_f_trident_p, -1);
      END
    end
    
    def truncate
      $mc.add_function :num_truncate, :int_to_i, :flo_truncate
      <<-END
        rb_define_method(rb_cFloat, 'truncate', flo_truncate, 0);
        rb_define_method(rb_cNumeric, 'truncate', num_truncate, 0);
        rb_define_method(rb_cInteger, 'truncate', int_to_i, 0);
      END
    end
    
    def tv_sec
      $mc.add_function :time_to_i
      <<-END
        rb_define_method(rb_cTime, "tv_sec", time_to_i, 0);
      END
    end
    
    def tv_usec
      $mc.add_function :time_usec
      <<-END
        rb_define_method(rb_cTime, "tv_usec", time_usec, 0);
      END
    end
    
    def unbind
      $mc.add_function :method_unbind
      <<-END
        rb_define_method(rb_cMethod, 'unbind', method_unbind, 0);
      END
    end
    
    def undef_method
      $mc.add_function :rb_define_private_method, :rb_mod_undef_method
      <<-END
        rb_define_private_method(rb_cModule, 'undef_method', rb_mod_undef_method, -1);
      END
    end
    
    def uniq
      $mc.add_function :rb_ary_uniq
      <<-END
        rb_define_method(rb_cArray, 'uniq', rb_ary_uniq, 0);
      END
    end
    
    def uniq!
      $mc.add_function :rb_ary_uniq_bang
      <<-END
        rb_define_method(rb_cArray, 'uniq!', rb_ary_uniq_bang, 0);
      END
    end
    
    def unpack
      $mc.add_function :pack_unpack
      <<-END
        rb_define_method(rb_cString, 'unpack', pack_unpack, 1);
      END
    end
    
    def unshift
      $mc.add_function :rb_ary_unshift_m
      <<-END
        rb_define_method(rb_cArray, 'unshift', rb_ary_unshift_m, -1);
      END
    end
    
    def untaint
      $mc.add_function :rb_obj_untaint
      <<-END
        rb_define_method(rb_mKernel, 'untaint', rb_obj_untaint, 0);
      END
    end
    
    def upcase
      $mc.add_function :rb_str_upcase
      <<-END
        rb_define_method(rb_cString, 'upcase', rb_str_upcase, 0);
      END
    end
    
    def upcase!
      $mc.add_function :rb_str_upcase_bang
      <<-END
        rb_define_method(rb_cString, 'upcase!', rb_str_upcase_bang, 0);
      END
    end
    
    def update
      $mc.add_function :rb_hash_update, :prop_update, :styles_update
      <<-END
        rb_define_method(rb_cHash,'update', rb_hash_update, 1);
        rb_define_method(rb_cStyles,'update', styles_update, 1);
        rb_define_method(rb_cProperties,'update', prop_update, 1);
      END
    end
    
    def upon
      $mc.add_function :cevent_upon
      <<-END
        rb_define_method(rb_mCodeEvent, 'upon', cevent_upon, -1);
      END
    end
    
    def upto
      $mc.add_function :rb_str_upto_m, :int_upto
      <<-END
        rb_define_method(rb_cString, 'upto', rb_str_upto_m, -1);
        rb_define_method(rb_cInteger, 'upto', int_upto, 1);
      END
    end
    
    def usec
      $mc.add_function :time_usec
      <<-END
        rb_define_method(rb_cTime, "usec", time_usec, 0);
      END
    end
    
    def utc
      $mc.add_function :time_s_mkutc, :rb_define_singleton_method, :time_gmtime
      <<-END
        rb_define_singleton_method(rb_cTime, "utc", time_s_mkutc, -1);
        rb_define_method(rb_cTime, "utc", time_gmtime, 0);
      END
    end
    
    def utc_offset
      $mc.add_function :time_utc_offset
      <<-END
        rb_define_method(rb_cTime, "utc_offset", time_utc_offset, 0);
      END
    end
    
    def utc?
      $mc.add_function :time_utc_p
      <<-END
        rb_define_method(rb_cTime, "utc?", time_utc_p, 0);
      END
    end
    
    def value
      $mc.add_function :rb_hash_has_value
      <<-END
        rb_define_method(rb_cHash,'value?', rb_hash_has_value, 1);
      END
    end
    
    def values
      $mc.add_function :rb_hash_values, :rb_struct_to_a
      <<-END
        rb_define_method(rb_cHash,'values', rb_hash_values, 0);
        rb_define_method(rb_cStruct, 'values', rb_struct_to_a, 0);
      END
    end
    
    def values_at
      $mc.add_function :rb_hash_values_at, :rb_ary_values_at, :rb_struct_values_at
      <<-END
        rb_define_method(rb_cStruct, 'values_at', rb_struct_values_at, -1);
        rb_define_method(rb_cHash,'values_at', rb_hash_values_at, -1);
        rb_define_method(rb_cArray, 'values_at', rb_ary_values_at, -1);
      END
    end
    
    def warn
      $mc.add_function :rb_warn_m
      <<-END
        rb_define_global_function('warn', rb_warn_m, 1);
      END
    end
    
    def wday
      $mc.add_function :time_wday
      <<-END
        rb_define_method(rb_cTime, "wday", time_wday, 0);
      END
    end
    
    def webkit?
      $mc.add_function :rb_f_webkit_p, :rb_define_global_function
      <<-END
        rb_define_global_function('webkit?', rb_f_webkit_p, -1);
      END
    end
    
    def wheel
      $mc.add_function :event_wheel
      <<-END
        rb_define_method(rb_cEvent, 'wheel', event_wheel, 0);
      END
    end
    
    def width
      $mc.add_function :doc_width, :rb_define_module_function, :elem_width
      <<-END
        rb_define_module_function(rb_mDocument, 'width', doc_width, 0);
        rb_define_method(rb_cElement, 'width', elem_width, 0);
      END
    end
    
    def window
      $mc.add_function :doc_window, :rb_define_module_function
      <<-END
        rb_define_module_function(rb_mDocument, 'window', doc_window, 0);
      END
    end
    
    def with_index
      $mc.add_function :enumerator_with_index
      <<-END
        rb_define_method(rb_cEnumerator, 'with_index', enumerator_with_index, 0);
      END
    end
    
    def write
      $mc.add_function :io_write
      <<-END
        rb_define_method(rb_cIO, 'write', io_write, 1);
      END
    end
    
    def xml
      $mc.add_function :resp_xml
      <<-END
        rb_define_method(rb_cResponse, 'xml', resp_xml, 0);
      END
    end
    
    def xpath?
      $mc.add_function :rb_define_global_function, :rb_f_xpath_p
      <<-END
        rb_define_global_function('xpath?', rb_f_xpath_p, 0);
      END
    end
    
    def yday
      $mc.add_function :time_yday
      <<-END
        rb_define_method(rb_cTime, "yday", time_yday, 0);
      END
    end
    
    def year
      $mc.add_function :time_year
      <<-END
        rb_define_method(rb_cTime, "year", time_year, 0);
      END
    end
    
    def zero?
      $mc.add_function :num_zero_p, :fix_zero_p, :flo_zero_p
      <<-END
        rb_define_method(rb_cNumeric, 'zero?', num_zero_p, 0);
        rb_define_method(rb_cFixnum, 'zero?', fix_zero_p, 0);
        rb_define_method(rb_cFloat, 'zero?', flo_zero_p, 0);
      END
    end
    
    def zip
      $mc.add_function :enum_zip, :rb_ary_zip
      <<-END
        rb_define_method(rb_mEnumerable, 'zip', enum_zip, -1);
        rb_define_method(rb_cArray, 'zip', rb_ary_zip, -1);
      END
    end
    
    def zone
      $mc.add_function :time_zone
      <<-END
        rb_define_method(rb_cTime, "zone", time_zone, 0);
      END
    end
  end
  
  module Boot
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
    
    # pulled from Init_Regexp, EMPTY
    def Init_MatchData
      <<-END
        function Init_MatchData() {}
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
    
    # EMPTY
    def Init_Regexp
      <<-END
        function Init_Regexp() {}
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
  
  module Eval
    # left some node types unimplemented
    def assign
      add_function :dvar_asgn, :dvar_asgn_curr
      <<-END
        function assign(self, lhs, val, pcall) {
          ruby_current_node = lhs;
          if (val == Qundef) { val = Qnil; } // removed warning
          switch (nd_type(lhs)) {
            case NODE_DASGN:
              dvar_asgn(lhs.nd_vid, val);
              break;
            case NODE_DASGN_CURR:
              dvar_asgn_curr(lhs.nd_vid, val);
              break;
            case NODE_LASGN:
              // removed bug warning
              ruby_scope.local_vars[lhs.nd_cnt] = val;
              break;
            default:
              console.log('unimplemented node type in rb_assign: 0x%s', nd_type(lhs).toString(16));
          }
        }
      END
    end
    
    # verbatim
    def avalue_to_svalue
      add_function :rb_check_array_type
      <<-END
        function avalue_to_svalue(v) {
          var top;
          var tmp = rb_check_array_type(v);
          if (NIL_P(tmp)) { return v; }
          if (tmp.ptr.length === 0) { return Qundef; }
          if (tmp.ptr.length == 1) {
            top = rb_check_array_type(tmp.ptr[0]);
            if (NIL_P(top)) { return tmp.ptr[0]; }
            if (top.ptr.length > 1) { return v; }
            return top;
          }
          return tmp;
        }
      END
    end
    
    # changed rb_str_new2 to rb_str_new, modified to use jsprintf instead of snprintf
    def backtrace
      add_function :ruby_set_current_source, :rb_id2name,
                   :rb_ary_push, :rb_str_new
      <<-END
        function backtrace(lev) {
          var frame = ruby_frame;
          var buf;
          var n;
          var ary = rb_ary_new();
          if (frame.last_func == ID_ALLOCATOR) { frame = frame.prev; }
          if (lev < 0) {
            ruby_set_current_source();
            if (frame.last_func) {
              buf = jsprintf("%s:%d:in '%s'", [ruby_sourcefile, ruby_sourceline, rb_id2name(frame.last_func)]);
            } else if (ruby_sourceline === 0) {
              buf = jsprintf("%s", [ruby_sourcefile]);
            } else {
              buf = jsprintf("%s:%d", [ruby_sourcefile, ruby_sourceline]);
            }
            rb_ary_push(ary, rb_str_new(buf));
            if (lev < -1) { return ary; }
          } else {
            while (lev-- > 0) {
              frame = frame.prev;
              if (!frame) {
                ary = Qnil;
                break;
              }
            }
          }
          for (; frame && (n = frame.node); frame = frame.prev) {
            if (frame.prev && frame.prev.last_func) {
              if (frame.prev.node == n) {
                if (frame.prev.last_func == frame.last_func) { continue; }
              }
              buf = jsprintf("%s:%d:in %s", [n.nd_file, nd_line(n), rb_id2name(frame.prev.last_func)]);
            } else {
              jsprintf("%s:%d", [n.nd_file, nd_line(n)]);
            }
            rb_ary_push(ary, rb_str_new(buf));
          }
          return ary;
        }
      END
    end
    
    # CHECK ON THIS
    def blk_copy_prev
      add_function :scope_dup, :frame_dup
      <<-END
        function blk_copy_prev(block) {
          var tmp;
          var vars;
          while (block.prev) {
            tmp = []; // was 'ALLOC_N(struct BLOCK, 1)'
            console.log('check blk_copy_prev');
            MEMCPY(tmp, block.prev, 1); // SHOULD THIS BE '[block.prev]' OR IS block.prev ALREADY AN ARRAY
            scope_dup(tmp.scope);
            frame_dup(tmp.frame);
            for (vars = tmp.dyna_vars; vars; vars = vars.next) {
              if (FL_TEST(vars, DVAR_DONT_RECYCLE)) { break; }
              FL_SET(vars, DVAR_DONT_RECYCLE);
            }
            block.prev = tmp;
            block = tmp;
          }
        }
      END
    end
    
    # verbatim
    def block_orphan
      <<-END
        function block_orphan(data) {
          // removed thread check
          return (data.scope.flags & SCOPE_NOSTACK) ? 1 : 0;
        }
      END
    end
    
    # CHECK
    def block_pass
      add_function :rb_eval, :rb_obj_is_proc, :rb_check_convert_type, :rb_obj_classname,
                   :rb_raise, :proc_get_safe_level, :proc_set_safe_level, :proc_jump_error,
                   :block_orphan
      add_method :to_proc
      <<-END
        function block_pass(self, node) {
          var proc = rb_eval(self, node.nd_body);
          var data;
          var result = Qnil;
          var safe = ruby_safe_level;
          var state = 0;
          
          if (NIL_P(proc)) {
            PUSH_ITER(ITER_NOT);
            result = rb_eval(self, node.nd_iter);
            POP_ITER();
            return result;
          }
          if (!rb_obj_is_proc(proc)) {
            var b = rb_check_convert_type(proc, T_DATA, 'Proc', 'to_proc');
            if (!rb_obj_is_proc(b)) { rb_raise(rb_eTypeError, "wrong argument type %s (expected Proc)", rb_obj_classname(proc)); }
            proc = b;
          }
          if (ruby_safe_level >= 1 && OBJ_TAINTED(proc) && ruby_safe_level > proc_get_safe_level(proc)) { rb_raise(rb_eSecurityError, "Insecure: tainted block value"); }
          if (ruby_block && ruby_block.block_obj == proc) {
            PUSH_ITER(ITER_PAS);
            result = rb_eval(self, node.nd_iter);
            POP_ITER();
            return result;
          }
          
        //Data_Get_Struct(proc, data);
          var data = proc.data;
          var orphan = block_orphan(data);
          
          var old_block = ruby_block;
          var _block = data;
          _block.outer = ruby_block;
          if (orphan) { _block.uniq = block_unique++; }
          ruby_block = _block;
          PUSH_ITER(ITER_PRE);
          if (ruby_frame.iter == ITER_NOT) { ruby_frame.iter = ITER_PRE; }
            
          PUSH_TAG(PROT_LOOP);
          do {
            var goto_retry = 0;
            try {
              proc_set_safe_level(proc);
              if (safe > ruby_safe_level) { ruby_safe_level = safe; }
              result = rb_eval(self, node.nd_iter);
            } catch (x) {
              if (typeof(state = x) != 'number') { throw(state); }
              if (state == TAG_BREAK && TAG_DEST()) {
                result = prot_tag.retval;
                state = 0;
              } else if (state == TAG_RETRY) {
                state = 0;
                goto_retry = 1;
              }
            }
          } while (goto_retry);
          POP_TAG();
          POP_ITER();
          ruby_block = old_block;
          ruby_safe_level = safe;
          
          switch (state) { /* escape from orphan block */
            case 0:
              break;
            case TAG_RETURN:
              if (orphan) { proc_jump_error(state, prot_tag.retval); }
              break;
            default:
              JUMP_TAG(state);
          }
          
          return result;
        }
      END
    end
    
    # verbatim
    def break_jump
      add_function :localjump_error
      <<-END
        function break_jump(retval) {
          var tt = prot_tag;
          if (retval == Qundef) { retval = Qnil; }
          while (tt) {
            switch (tt.tag) {
              case PROT_THREAD:
              case PROT_YIELD:
              case PROT_LOOP:
              case PROT_LAMBDA:
                tt.dst = tt.frame.uniq;
                tt.retval = retval;
                JUMP_TAG(TAG_BREAK);
                break;
              case PROT_FUNC:
                tt = 0;
                continue;
              default:
                break;
            }
            tt = tt.prev;
          }
          localjump_error("unexpected break", retval, TAG_BREAK);
        }
      END
    end
    
    # verbatim
    def call_cfunc
      add_function :rb_raise, :rb_ary_new4
      <<-END
        function call_cfunc(func, recv, len, argc, argv) {
          if (len >= 0 && argc != len) { rb_raise(rb_eArgError, "wrong number of arguments (%d for %d)", argc, len); }
          switch (len) {
            case -2:
              return func(recv, rb_ary_new4(argc, argv));
            case -1:
              return func(argc, argv, recv);
            case 0:  return func(recv);
            case 1:  return func(recv, argv[0]);
            case 2:  return func(recv, argv[0], argv[1]);
            case 3:  return func(recv, argv[0], argv[1], argv[2]);
            case 4:  return func(recv, argv[0], argv[1], argv[2], argv[3]);
            case 5:  return func(recv, argv[0], argv[1], argv[2], argv[3], argv[4]);
            case 6:  return func(recv, argv[0], argv[1], argv[2], argv[3], argv[4], argv[5]);
            case 7:  return func(recv, argv[0], argv[1], argv[2], argv[3], argv[4], argv[5], argv[6]);
            case 8:  return func(recv, argv[0], argv[1], argv[2], argv[3], argv[4], argv[5], argv[6], argv[7]);
            case 9:  return func(recv, argv[0], argv[1], argv[2], argv[3], argv[4], argv[5], argv[6], argv[7], argv[8]);
            case 10: return func(recv, argv[0], argv[1], argv[2], argv[3], argv[4], argv[5], argv[6], argv[7], argv[8], argv[9]);
            case 11: return func(recv, argv[0], argv[1], argv[2], argv[3], argv[4], argv[5], argv[6], argv[7], argv[8], argv[9], argv[10]);
            case 12: return func(recv, argv[0], argv[1], argv[2], argv[3], argv[4], argv[5], argv[6], argv[7], argv[8], argv[9], argv[10], argv[11]);
            case 13: return func(recv, argv[0], argv[1], argv[2], argv[3], argv[4], argv[5], argv[6], argv[7], argv[8], argv[9], argv[10], argv[11], argv[12]);
            case 14: return func(recv, argv[0], argv[1], argv[2], argv[3], argv[4], argv[5], argv[6], argv[7], argv[8], argv[9], argv[10], argv[11], argv[12], argv[13]);
            case 15: return func(recv, argv[0], argv[1], argv[2], argv[3], argv[4], argv[5], argv[6], argv[7], argv[8], argv[9], argv[10], argv[11], argv[12], argv[13], argv[14]);
            default:
              rb_raise(rb_eArgError, "too many arguments (%d)", len);
              break;
          }
          return Qnil;
        }
      END
    end
    
    # removed ruby_wrapper branch
    def class_prefix
      add_function :rb_raise, :rb_obj_as_string
      <<-END
        function class_prefix(self, cpath) {
          // removed bug warning
          if (cpath.nd_head) {
            var c = rb_eval(self, cpath.nd_head);
            switch (TYPE(c)) {
              case T_CLASS:
              case T_MODULE:
                break;
              default:
                rb_raise(rb_eTypeError, "%s is not a class/module", rb_obj_as_string(c).ptr);
            }
            return c;
          } else if (nd_type(cpath) == NODE_COLON2) {
            return ruby_cbase;
          } else { // removed ruby_wrapper branch
            return rb_cObject;
          }
        }
      END
    end
    
    # verbatim
    def dvar_asgn
      add_function :dvar_asgn_internal
      <<-END
        function dvar_asgn(id, value) {
          dvar_asgn_internal(id, value, 0);
        }
      END
    end
    
    # verbatim
    def dvar_asgn_curr
      add_function :dvar_asgn_internal
      <<-END
        function dvar_asgn_curr(id, value) {
          dvar_asgn_internal(id, value, 1);
        }
      END
    end
    
    # verbatim
    def dvar_asgn_internal
      add_function :new_dvar
      <<-END
        function dvar_asgn_internal(id, value, curr) {
          var n = 0;
          var vars = ruby_dyna_vars;
          while (vars) {
            if (curr && (vars.id === 0)) {
              /* first null is a dvar header */
              n++;
              if (n == 2) { break; }
            }
            if (vars.id == id) {
              vars.val = value;
              return;
            }
            vars = vars.next;
          }
          if (!ruby_dyna_vars) {
            ruby_dyna_vars = new_dvar(id, value, 0);
          } else {
            vars = new_dvar(id, value, ruby_dyna_vars.next);
            ruby_dyna_vars.next = vars;
          }
        }
      END
    end
    
    # verbatim
    def errat_getter
      add_function :get_backtrace
      <<-END
        function errat_getter(id) {
          return get_backtrace(ruby_errinfo);
        }
      END
    end
    
    # modified to return variable instead of using pointer
    def errat_setter
      add_function :rb_raise, :set_backtrace
      <<-END
        function errat_setter(val, id, variable) {
          if (NIL_P(ruby_errinfo)) { rb_raise(rb_eArgError, "$! not set"); }
          set_backtrace(ruby_errinfo, val);
          return val;
        }
      END
    end
    
    # modified to return variable instead of using pointer
    def errinfo_setter
      add_function :rb_obj_is_kind_of, :rb_raise
      <<-END
        function errinfo_setter(val, id, variable) {
          if (!NIL_P(val) && !rb_obj_is_kind_of(val, rb_eException)) { rb_raise(rb_eTypeError, "assigning non-exception to $!"); }
          return val;
        }
      END
    end
    
    # verbatim
    def error_pos
      add_function :ruby_set_current_source, :warn_printf, :rb_id2name
      <<-END
        function error_pos() {
          ruby_set_current_source();
          if (ruby_sourcefile) {
            if (ruby_frame.last_func) {
              warn_printf("%s:%d:in '%s'", ruby_sourcefile, ruby_sourceline, rb_id2name(ruby_frame.orig_func));
            } else if (ruby_sourceline === 0) {
              warn_printf("%s", ruby_sourcefile);
            } else {
              warn_printf("%s:%d", ruby_sourcefile, ruby_sourceline);
            }
          }
        }
      END
    end
    
    # added console.log command here, as in io_puts
    def error_print
      add_function :get_backtrace, :ruby_set_current_source, :warn_printf,
                   :error_pos, :rb_write_error, :rb_intern, :rb_class_name,
                   :rb_funcall, :rb_intern
      add_method :message
      <<-END
        function error_print() {
          var errat = Qnil;
          var eclass;
          var e;
          var elen;
          var einfo = '';
          if (NIL_P(ruby_errinfo)) { return; }
          PUSH_TAG(PROT_NONE);
          try { // was EXEC_TAG
            errat = get_backtrace(ruby_errinfo);
          } catch (x) {
            if (typeof(state = x) != 'number') { throw(state); }
            errat = Qnil;
          }
          try { // was EXEC_TAG
            if (NIL_P(errat)) {
              ruby_set_current_source();
              if (ruby_sourcefile) {
                warn_printf("%s:%d", ruby_sourcefile, ruby_sourceline);
              } else {
                warn_printf("%d", ruby_sourceline);
              }
            } else if (errat.ptr.length === 0) {
              error_pos();
            } else {
              var mesg = errat.ptr[0];
              if (NIL_P(mesg)) {
                error_pos();
              } else {
                var mesg = rb_write_error(mesg.ptr);
              }
            }
            eclass = CLASS_OF(ruby_errinfo);
          } catch (x) { // was 'goto error'
            if (typeof(state = x) != 'number') { throw(state); }
            prot_tag = _tag.prev; 
            return; // exits TAG_MACRO wrapper function
          }
          try { // was EXEC_TAG
            e = rb_funcall(ruby_errinfo, rb_intern('message'), 0, 0);
          //StringValue(e);
            if (e.data) { e = name_err_mesg_to_str(e); } // this line is a hack
            einfo = e.ptr;
            elen = einfo.length;
          } catch (x) {
            if (typeof(state = x) != 'number') { throw(state); }
            einfo = '';
            elen = 0;
          }
          try { // was EXEC_TAG
            if ((eclass == rb_eRuntimeError) && (elen === 0)) {
              rb_write_error(": unhandled exception\\n");
            } else {
              var epath = rb_class_name(eclass);
              if (elen === 0) {
                rb_write_error(": " + epath.ptr + "\\n");
              } else {
                var tail = 0;
                var len = elen;
                if (epath.ptr[0] == '#') { epath = 0; }
                if ((tail = einfo.indexOf('\\n')) !== 0) {
                  len = tail - einfo;
                  tail++ /* skip newline */
                }
                rb_write_error(": " + einfo);
                if (epath) { rb_write_error(" (" + epath.ptr + ")\\n"); }
                if (tail && (elen > len + 1)) {
                  rb_write_error(tail);
                  if (einfo[elen - 1] != '\\n') { rb_write_error("\\n"); }
                }
              }
            }
            if (!NIL_P(errat)) {
              var ep = errat;
              var truncate = (eclass == rb_eSysStackError);
              for (var i = 1, p = ep.ptr, l = ep.ptr.length; i < l; ++i) {
                if (TYPE(p[i]) == T_STRING) { warn_printf(" \\t \\tfrom %s\\n", p[i].ptr); }
                if (truncate && (i == 8) && (l > 18)) {
                  warn_printf(" \\t \\t ... %d levels ...\\n", l - 13);
                  i = l - 5;
                }
              }
            }
          } catch (x) { // was 'goto error'
            if (typeof(state = x) != 'number') { throw(state); }
          }
          POP_TAG();
          console.log(CONSOLE_LOG_BUFFER); // added
          CONSOLE_LOG_BUFFER = ''; // added
        }
      END
    end
    
    # removed 'autoload' call
    def ev_const_get
      add_function :rb_const_get, :st_lookup
      <<-END
        function ev_const_get(cref, id, self) {
          var cbase = cref;
          var result;
          while (cbase && cbase.nd_next) {
            var klass = cbase.nd_clss;
            if (!NIL_P(klass)) {
              while (klass.iv_tbl && (result = st_lookup(klass.iv_tbl, id))[0]) {
                if (result[1] == Qundef) { continue; } // removed 'autoload' call
                return result[1];
              }
            }
            cbase = cbase.nd_next;
          }
          return rb_const_get(NIL_P(cref.nd_clss) ? CLASS_OF(self) : cref.nd_clss, id);
        }
      END
    end
    
    # verbatim
    def exec_under
      <<-END
        function exec_under(func, under, cbase, args) {
          var val = Qnil; /* OK */
          var state = 0;
          var mode;
          var f = ruby_frame;
          PUSH_CLASS(under);
          PUSH_FRAME();
          ruby_frame.self = f.self;
          ruby_frame.last_func = f.last_func;
          ruby_frame.orig_func = f.orig_func;
          ruby_frame.last_class = f.last_class;
          ruby_frame.argc = f.argc;
          if (cbase) { PUSH_CREF(cbase); }
          mode = scope_vmode;
          SCOPE_SET(SCOPE_PUBLIC);
          PUSH_TAG(PROT_NONE);
          try { // was EXEC_TAG
            val = func(args);
          } catch(x) {
            if (typeof(state = x) != 'number') { throw(state); }
          }
          POP_TAG();
          if (cbase) { POP_CREF(); }
          SCOPE_SET(mode);
          POP_FRAME();
          POP_CLASS();
          if (state) { JUMP_TAG(state); }
          return val;
        }
      END
    end
    
    # FIND OUT WHY THE TOP FRAME ENDS UP WITH A PREV
    def frame_dup
      <<-END
        function frame_dup(frame) {
          for (;;) {
            frame.tmp = 0;
            if (!frame.prev || frame.this_is_the_top_frame) { break; }
            var tmp = frame.prev;
            frame.prev = tmp;
            frame = tmp;
          }
        }
      END
    end
    
    # CHECK
    def get_backtrace
      add_function :rb_funcall, :rb_check_backtrace
      add_method :backtrace
      <<-END
        function get_backtrace(info) {
          if (NIL_P(info)) { return Qnil; }
          info = rb_funcall(info, bt, 0);
          if (NIL_P(info)) { return Qnil; }
          return rb_check_backtrace(info);
        }
      END
    end
    
    # modified looping through array of exception types
    def handle_rescue
      add_function :rb_obj_is_kind_of, :rb_raise, :rb_funcall
      add_method :===
      <<-END
        function handle_rescue(self, node) {
          var argc;
          var argv;
        //TMP_PROTECT;
          if (!node.nd_args) { return rb_obj_is_kind_of(ruby_errinfo, rb_eStandardError); }
          BEGIN_CALLARGS;
          SETUP_ARGS(node.nd_args);
          END_CALLARGS;
          while (argc--) {
            if (!rb_obj_is_kind_of(argv[argc], rb_cModule)) { rb_raise(rb_eTypeError, "class or module required for rescue clause"); }
            if (RTEST(rb_funcall(argv[argc], eqq, 1, ruby_errinfo))) { return 1; }
          }
          return 0;
        }
      END
    end
    
    # unsupported
    def is_defined
      add_function :rb_raise
      <<-END
        function is_defined() {
          rb_raise(rb_eRuntimeError, "Red doesn't support 'defined?'");
        }
      END
    end
    
    # verbatim
    def iterate_method
      add_function :rb_funcall2
      <<-END
        function iterate_method(arg) {
          return rb_funcall2(arg.obj, arg.mid, arg.argc, arg.argv);
        }
      END
    end
    
    # verbatim
    def jump_tag_but_local_jump
      add_function :localjump_error
      <<-END
        function jump_tag_but_local_jump(state, val) {
          if (val == Qundef) { val = prot_tag.retval; }
          switch (state) {
            case 0:
              break;
            case TAG_RETURN:
              localjump_error("unexpected return", val, state);
              break;
            case TAG_BREAK:
              localjump_error("unexpected break", val, state);
              break;
            case TAG_NEXT:
              localjump_error("unexpected next", val, state);
              break;
            case TAG_REDO:
              localjump_error("unexpected redo", Qnil, state);
              break;
            case TAG_RETRY:
              localjump_error("retry outside of rescue clause", Qnil, state);
              break;
          }
          JUMP_TAG(state);
        }
      END
    end
    
    # changed rb_exc_new2 to rb_exc_new
    def localjump_error
      add_function :rb_exc_new, :rb_iv_set, :rb_exc_raise, :rb_intern
      <<-END
        function localjump_error(mesg, value, reason) {
          var exc = rb_exc_new(rb_eLocalJumpError, mesg); // was rb_exc_new2
          var id;
          rb_iv_set(exc, '@exit_value', value);
          switch (reason) {
            case TAG_BREAK:
              id = rb_intern('break');
              break;
            case TAG_REDO:
              id = rb_intern('redo');
              break;
            case TAG_RETRY:
              id = rb_intern('retry');
              break;
            case TAG_NEXT:
              id = rb_intern('next');
              break;
            case TAG_RETURN:
              id = rb_intern('return');
              break;
            default:
              id = rb_intern('noreason');
              break;
          }
          rb_iv_set(exc, '@reason', ID2SYM(id));
          rb_exc_raise(exc);
        }
      END
    end
    
    # verbatim
    def make_backtrace
      add_function :backtrace
      <<-END
        function make_backtrace() {
          return backtrace(-1);
        }
      END
    end
    
    # verbatim
    def massign
      add_function :assign, :rb_raise, :rb_ary_new4
      <<-END
        function massign(self, node, val, pcall) {
          var len = val.ptr.length;
          var list = node.nd_head;
          for (var i = 0, p = val.ptr; list && (i < len); i++) {
            assign(self, list.nd_head, p[i], pcall);
            list = list.nd_next;
          }
          if (pcall && list) {
            while (list) { i++; list = list.nd_next; }
            rb_raise(rb_eArgError, "wrong number of arguments (%d for %d)", len, i);
          }
          if (node.nd_args) {
            if (node.nd_args == -1) {
              /* no check for mere `*' */
            } else if (!list && (i < len)) {
              assign(self, node.nd_args, rb_ary_new4(len - i, p.slice(i)), pcall);
            } else {
              assign(self, node.nd_args, rb_ary_new(), pcall);
            }
          } else if (pcall && (i < len)) {
            while (list) { i++; list = list.nd_next; }
            rb_raise(rb_eArgError, "wrong number of arguments (%d for %d)", len, i);
          }
          while (list) {
            i++;
            assign(self, list.nd_head, Qnil, pcall);
            list = list.nd_next;
          }
          return val;
        }
      END
    end
    
    # hacked MEMCPY with offset
    def method_missing(x = nil)
      raise NoMethodError if x
      add_function :rb_method_missing, :rb_raise, :splat_value, :rb_funcall2
      add_method :method_missing
      <<-END
        function method_missing(obj, id, argc, argv, call_status) {
          var nargv;
          last_call_status = call_status;
          if (id == missing) {
            PUSH_FRAME();
            rb_method_missing(argc, argv, obj);
            POP_FRAME();
          } else if (id == ID_ALLOCATOR) {
            rb_raise(rb_eTypeError, "allocator undefined for %s", rb_class2name(obj));
          }
          if (argc < 0) {
            var tmp;
            argc = -argc - 1;
            tmp = splat_value(argv[argc]);
            nargv = []; // was 'nargv = ALLOCA_N(VALUE, argc + RARRAY(tmp)->len + 1)'
            MEMCPY(nargv, argv, argc, 1);
            MEMCPY(nargv, tmp.ptr, tmp.ptr.length, 1 + argc);
            argc += tmp.ptr.length;
          } else {
            nargv = []; // was 'nargv = ALLOCA_N(VALUE, argc+1)'
            MEMCPY(nargv, argv, argc, 1); // is it +1 or -1 offset?
          }
          nargv[0] = ID2SYM(id);
          return rb_funcall2(obj, missing, argc + 1, nargv);
        }
      END
    end
    
    # changed local vars handling, removed event hooks
    def module_setup
      add_function :rb_eval
      <<-END
        function module_setup(module, n) {
          var node = n.nd_body;
          var state = 0;
          var result = Qnil;
        //TMP_PROTECT;
          var frame = ruby_frame;
          frame.tmp = ruby_frame;
          ruby_frame = frame;
          PUSH_CLASS(module);
          PUSH_SCOPE();
          PUSH_VARS();
          if (node.nd_tbl) {
            var vars = []; // was VALUE *vars = TMP_ALLOC(node->nd_tbl[0]+1)
            vars.zero = node; // was *vars++ = (VALUE)node
            ruby_scope.local_vars = vars;
          //rb_mem_clear(ruby_scope->local_vars, node->nd_tbl[0]);
            ruby_scope.local_tbl = node.nd_tbl;
          } else {
            ruby_scope.local_vars = 0;
            ruby_scope.local_tbl = 0;
          }
          PUSH_CREF(module);
          PUSH_TAG(PROT_NONE);
          try { // was EXEC_TAG
            result = rb_eval(ruby_cbase, node.nd_next);
          } catch(state) {
            if (typeof(state) != 'number') { throw(state); }
          }
          POP_TAG();
          POP_CREF();
          POP_VARS();
          POP_SCOPE();
          POP_CLASS();
          ruby_frame = frame.tmp;
        //removed event hook handler
          if (state) { JUMP_TAG(state); }
          return result;
        }
      END
    end
    
    # verbatim
    def new_dvar
      <<-END
        function new_dvar(id, value, prev) {
          var vars = NEWOBJ();
          OBJSETUP(vars, 0, T_VARMAP);
          vars.id = id;
          vars.val = value;
          vars.next = prev;
          return vars;
        }
      END
    end
    
    # verbatim
    def next_jump
      add_function :local_jump_error
      <<-END
        function next_jump(retval) {
          var tt = prot_tag;
          if (retval == Qundef) { retval = Qnil; }
          while (tt) {
            switch (tt.tag) {
              case PROT_THREAD:
              case PROT_YIELD:
              case PROT_LOOP:
              case PROT_LAMBDA:
              case PROT_FUNC:
                tt.dst = tt.frame.uniq;
                tt.retval = retval;
                JUMP_TAG(TAG_NEXT);
                break;
              default:
                break;
            }
            tt = tt.prev;
          }
          localjump_error("unexpected next", retval, TAG_NEXT);
        }
      END
    end
    
    def print_undef
      add_function :rb_name_error, :rb_id2name, :rb_class2name
      <<-END
        function print_undef(klass, id) {
          rb_name_error(id, "undefined method '%s' for %s '%s'", rb_id2name(id), (TYPE(klass) == T_MODULE) ? "module" : "class", rb_class2name(klass));
        }
      END
    end
    
    # verbatim
    def proc_jump_error
      add_function :localjump_error
      <<-END
        function proc_jump_error(state, result) {
          var statement;
          switch (state) {
            case TAG_BREAK:
              statement = "break"; break;
            case TAG_RETURN:
              statement = "return"; break;
            case TAG_RETRY:
              statement = "retry"; break;
            default:
              statement = "local-jump"; break; /* should not happen */
          }
          var mesg = jsprintf("%s from proc-closure", [statement]);
          localjump_error(mesg, result, state);
        }
      END
    end
    
    # verbatim
    def rb_add_method
      add_function :rb_raise, :rb_intern, :rb_error_frozen, :rb_clear_cache_by_id, :rb_funcall, :rb_iv_get, :st_insert
      add_method :singleton_method_added, :method_added
      <<-END
        function rb_add_method(klass, mid, node, noex) {
          var body;
          if (NIL_P(klass)) { klass = rb_cObject; }
          if (ruby_safe_level >= 4 && (klass == rb_cObject || !OBJ_TAINTED(klass))) { rb_raise(rb_eSecurityError, "Insecure: can't define method"); }
          if (!FL_TEST(klass, FL_SINGLETON) && node && (nd_type(node) != NODE_ZSUPER) && (mid == rb_intern('initialize') || mid == rb_intern('initialize_copy'))) {
            noex = NOEX_PRIVATE | noex;
          } else if (FL_TEST(klass, FL_SINGLETON) && node && (nd_type(node) == NODE_CFUNC) && (mid == rb_intern('allocate'))) {
            // removed warning about defining 'allocate'
            mid = ID_ALLOCATOR;
          }
          if (OBJ_FROZEN(klass)) { rb_error_frozen("class/module"); }
          rb_clear_cache_by_id(mid);
          body = NEW_METHOD(node, NOEX_WITH_SAFE(noex));
          st_insert(klass.m_tbl, mid, body);
          if (node && (mid != ID_ALLOCATOR) && ruby_running) {
            if (FL_TEST(klass, FL_SINGLETON)) {
              rb_funcall(rb_iv_get(klass, '__attached__'), singleton_added, 1, ID2SYM(mid));
            } else {
              rb_funcall(klass, added, 1, ID2SYM(mid));
            }
          }
        }
      END
    end
    
    # expanded search_method
    def rb_alias
      add_function :rb_frozen_class_p, :search_method, :print_undef, :rb_iv_get, :rb_clear_cache_by_id, :rb_funcall, :st_insert
      add_method :singleton_method_added, :method_added
      <<-END
        function rb_alias(klass, name, def) {
          var origin;
          var orig;
          var body;
          var node;
          var singleton = 0;
          rb_frozen_class_p(klass);
          if (name == def) { return; }
          if (klass == rb_cObject) { rb_secure(4); }
          var tmp = search_method(klass, def); // expanded
          orig = tmp[0];
          origin = tmp[1]; // ^^
          if (!orig || !orig.nd_body) {
            if (TYPE(klass) == T_MODULE) {
              tmp = search_method(rb_cObject, def); // expanded
              orig = tmp[0];
              origin = tmp[1]; // ^^
            }
          }
          if (!orig || !orig.nd_body) { print_undef(klass, def); }
          if (FL_TEST(klass, FL_SINGLETON)) { singleton = rb_iv_get(klass, '__attached__'); }
          body = orig.nd_body;
          orig.u3++; // was orig->nd_cnt++
          if (nd_type(body) == NODE_FBODY) { /* was alias */
            def = body.nd_mid;
            origin = body.nd_orig;
            body = body.nd_head;
          }
          rb_clear_cache_by_id(name);
          // removed warning
          st_insert(klass.m_tbl, name, NEW_METHOD(NEW_FBODY(body, def, origin), NOEX_WITH_SAFE(orig.nd_noex)));
          if (!ruby_running) { return; }
          if (singleton) {
            rb_funcall(singleton, singleton_added, 1, ID2SYM(name));
          } else {
            rb_funcall(klass, added, 1, ID2SYM(name));
          }
        }
      END
    end
    
    # changed_string_handling
    def rb_attr
      add_function :rb_is_local_id, :rb_is_const_id, :rb_name_error, :rb_id2name, :rb_raise, :rb_intern, :rb_add_method
      <<-END
        function rb_attr(klass, id, read, write, ex) {
          var noex;
          if (!ex) {
            noex = NOEX_PUBLIC;
          } else if (SCOPE_TEST(SCOPE_PRIVATE)) {
            noex = NOEX_PRIVATE;
            // removed warning
          } else if (SCOPE_TEST(SCOPE_PROTECTED)) {
            noex = NOEX_PROTECTED;
          } else {
            noex = NOEX_PUBLIC;
          }
          if (!rb_is_local_id(id) && !rb_is_const_id(id)) { rb_name_error(id, "invalid attribute name '%s'", rb_id2name(id)); }
          var name = rb_id2name(id);
          if (!name) { rb_raise(rb_eArgError, "argument needs to be symbol or string"); }
          // removed string buf computation
          var attriv = rb_intern('@' + name);
          if (read) { rb_add_method(klass, id, NEW_IVAR(attriv), noex); }
          if (write) { rb_add_method(klass, rb_id_attrset(id), NEW_ATTRSET(attriv), noex); }
        }
      END
    end
    
    # verbatim
    def rb_block_call
      add_function :iterate_method
      <<-END
        function rb_block_call(obj, mid, argc, argv, bl_proc, data2) {
          var arg = {};
          arg.obj = obj;
          arg.mid = mid;
          arg.argc = argc;
          arg.argv = argv;
          return rb_iterate(iterate_method, arg, bl_proc, data2);
        }
      END
    end
    
    # verbatim
    def rb_block_given_p
      <<-END
        function rb_block_given_p() {
          return ((ruby_frame.iter == ITER_CUR) && ruby_block) ? Qtrue : Qfalse;
        }
      END
    end
    
    # verbatim
    def rb_block_proc
      add_function :proc_alloc
      <<-END
        function rb_block_proc() {
          return proc_alloc(rb_cProc, Qfalse);
        }
      END
    end
    
    # modified cache access and expanded rb_get_method_body
    def rb_call
      add_function :rb_id2name, :rb_raise, :rb_get_method_body, :method_missing, :rb_class_real, :rb_obj_is_kind_of, :rb_call0
      <<-END
        function rb_call(klass, recv, mid, argc, argv, scope, self) {
          var body;
          var noex;
          var id = mid;
          var ent;
          if (!klass) { rb_raise(rb_eNotImpError, "method '%s' called on terminated object (0x%x)", rb_id2name(mid), recv); }
          /* is it in the method cache? */
          ent = cache[EXPR1(klass, mid)] || {}; // was 'ent = cache + EXPR1(klass, mid)'
          if ((ent.mid == mid) && (ent.klass == klass)) {
            if (!ent.method) { return method_missing(recv, mid, argc, argv, scope == 2 ? CSTAT_VCALL : 0); }
            body  = ent.method;
            klass = ent.origin;
            id    = ent.mid0;
            noex  = ent.noex;
          } else {
            var tmp = rb_get_method_body(klass, id, noex); // ff. was 'body = rb_get_method_body(&klass, &id, &noex)'
            body  = tmp[0];
            klass = tmp[1];
            id    = tmp[2];
            noex  = tmp[3];
            if (body === 0) {
              if (scope == 3) { return method_missing(recv, mid, argc, argv, CSTAT_SUPER); }
            //console.log(klass, recv, mid, argc, argv, scope, self);
            //throw('fail');
              return method_missing(recv, mid, argc, argv, scope == 2 ? CSTAT_VCALL : 0);
            }
          }
          if ((mid != missing) && (scope === 0)) {
            /* receiver specified form for private method */
            if (noex & NOEX_PRIVATE) { return method_missing(recv, mid, argc, argv, CSTAT_PRIV); }
            /* self must be kind of a specified form for protected method */
            if (noex & NOEX_PROTECTED) {
              var defined_class = klass;
              if (self == Qundef) { self = ruby_frame.self; }
              if (TYPE(defined_class) == T_ICLASS) { defined_class = defined_class.basic.klass; }
              if (!rb_obj_is_kind_of(self, rb_class_real(defined_class))) { return method_missing(recv, mid, argc, argv, CSTAT_PROT); }
            }
          }
          return rb_call0(klass, recv, mid, id, argc, argv, body, noex);
        }
      END
    end
    
    # CHECK
    def rb_call0
      add_function :rb_raise, :call_cfunc, :jump_tag_but_local_jump, :rb_attr_get
      <<-END
        function rb_call0(klass, recv, id, oid, argc, argv, body, flags) {
          var b2;
          var result = Qnil;
          var itr;
        //var tick;
        //TMP_PROTECT();
          var safe = -1;
          if ((NOEX_SAFE(flags) > ruby_safe_level) && (NOEX_SAFE(flags) > 2)) { rb_raise(rb_eSecurityError, "calling insecure method: %s", rb_id2name(id)); }
          switch (ruby_iter.iter) {
            case ITER_PRE:
            case ITER_PAS:
              itr = ITER_CUR;
              break;
            case ITER_CUR:
            default:
              itr = ITER_NOT;
              break;
          }
        //removed GC 'tick' process
          if (argc < 0) {
            var tmp;
            var nargv;
            argc = -argc - 1;
            tmp = splat_value(argv[argc]);
            var nargv = [];
            MEMCPY(nargv, argv, argc);
            // CHECK THIS ***********************
            // CHECK THIS ***********************
            // CHECK THIS ***********************
            // CHECK THIS ***********************
            console.log('HEY CHECK IF THE MEMCPY IN rb_call0 IS CORRECT');
            MEMCPY(nargv, tmp.ptr, tmp.ptr.length, argc); // is it +argc or -argc?
            argc += tmp.ptr.length;
            argv = nargv;
          }
          
          PUSH_ITER(itr);
          
          PUSH_FRAME();
          ruby_frame.last_func = id;
          ruby_frame.orig_func = oid;
          ruby_frame.last_class = (flags & NOEX_NOSUPER) ? 0 : klass;
          ruby_frame.self = recv;
          ruby_frame.argc = argc;
          ruby_frame.flags = 0;
          
          switch(nd_type(body)) {
            case NODE_ATTRSET:
              if (argc != 1) { rb_raise(rb_eArgError, "wrong number of arguments (%d for 1)", argc); }
              result = rb_ivar_set(recv, body.nd_vid, argv[0]);
              break;
            
            case NODE_CFUNC:
              // removed bug warning
              // removed event hooks handler
              result = call_cfunc(body.nd_cfnc, recv, body.nd_argc, argc, argv);
              break;
            
            case NODE_IVAR:
              if (argc != 0) { rb_raise(rb_eArgError, "wrong number of arguments (%d for 0)", argc); }
              result = rb_attr_get(recv, body.nd_vid);
              break;
            
            // skipped other types of nodes for now
            
            case NODE_SCOPE:
              var local_vars;
              var state = 0;
              var saved_cref = 0;
              
              PUSH_SCOPE();
              
              if (body.nd_rval) {
                saved_cref = ruby_cref;
                ruby_cref = body.nd_rval;
              }
              
              PUSH_CLASS(ruby_cbase);
              
              if (body.nd_tbl) {
                local_vars = []; // was 'local_vars = TMP_ALLOC(body->nd_tbl[0]+1)'
              //*local_vars++ = (VALUE)body;
              //rb_mem_clear(local_vars, body->nd_tbl[0]);
                ruby_scope.local_tbl = body.nd_tbl;
                ruby_scope.local_vars = local_vars;
              } else {
                local_vars = ruby_scope.local_vars = 0;
                ruby_scope.local_tbl = 0;
              }
              b2 = body = body.nd_next;
              
              if (NOEX_SAFE(flags) > ruby_safe_level) {
                safe = ruby_safe_level;
                ruby_safe_level = NOEX_SAFE(flags);
              }
              
              PUSH_VARS();
              
              PUSH_TAG(PROT_FUNC);
              
              try { // was EXEC_TAG
                var node = 0;
                var nopt = 0;
                
                if (nd_type(body) == NODE_ARGS) {
                  node = body;
                  body = 0;
                } else if (nd_type(body) == NODE_BLOCK) {
                  node = body.nd_head;
                  body = body.nd_next;
                }
                
                if (node) {
                  // removed bug warning
                  var i = node.nd_cnt;
                  if (argc < i) { rb_raise(rb_eArgError, "wrong number of arguments (%d for %d)", argc, i); }
                  if (!node.nd_rest) {
                    var optnode = node.nd_opt;
                    nopt = i;
                    while (optnode) {
                      nopt++;
                      optnode = optnode.nd_next;
                    }
                    if (argc > nopt) { rb_raise(rb_eArgError, "wrong number of arguments (%d for %d)", argc, nopt); }
                  }
                  
                  // this part is a hack
                  var offset_hack = node.nd_rest ? 1 : 0;
                  if (node.nd_opt) {
                    var opt = node.nd_opt;
                    var tmp_argc = argc;
                    // this loops through each optional argument, calling :assign
                    // after each optional argument is processed:
                    //   argvp is incremented by one. final result: argvp points to the start of the rest args in argv
                    //   argc is decremented by one. final result: argc is equal to the number of rest args only
                    //   i is incremented by one. final result: i is equal to the combined number of formal and optional args
                    while (opt && tmp_argc) {
                      tmp_argc--;
                      offset_hack++;
                      opt = opt.nd_next;
                    }
                  }
                  
                  if (local_vars) {
                    if (i > 0) { // this part is obviously hacked
                      MEMCPY(local_vars, argv, i, 4 + offset_hack);
                    }
                  }
                  
                  var argvp = i;
                  argc -= i;
                  
                  if (node.nd_opt) {
                    var opt = node.nd_opt;
                    // this loops through each optional argument, calling :assign
                    // after each optional argument is processed:
                    //   argvp is incremented by one. final result: argvp points to the start of the rest args in argv
                    //   argc is decremented by one. final result: argc is equal to the number of rest args only
                    //   i is incremented by one. final result: i is equal to the combined number of formal and optional args
                    while (opt && argc) {
                      assign(recv, opt.nd_head, argv[argvp], 1);
                      argvp++;
                      argc--;
                      ++i;
                      opt = opt.nd_next;
                    }
                    if (opt) {
                      rb_eval(recv, opt);
                      while (opt) {
                        opt = opt.nd_next;
                        ++i;
                      }
                    }
                  }
                  if (!node.nd_rest) {
                    i = nopt;
                  } else {
                    var v = rb_ary_new();
                    if (argc > 0) {
                      for (var argv_index = 0, l = argv.length, offset = l - argc, dest = v.ptr; argv_index < argc; ++argv_index) {
                        dest[argv_index] = argv[argv_index + offset];
                      }
                      i = -i - 1;
                    }
                    assign(recv, node.nd_rest, v, 1);
                  }
                  ruby_frame.argc = i;
                }
              //if (event_hooks) { EXEC_EVENT_HOOK(RUBY_EVENT_CALL, b2, recv, id, klass); }
                result = rb_eval(recv, body);
              } catch (x) {
                if (typeof(state = x) != 'number') { throw(state); }
                if ((state == TAG_RETURN) && TAG_DST()) {
                  result = prot_tag.retval;
                  state = 0;
                }
              }
              POP_TAG();
              POP_VARS();
              POP_CLASS();
              POP_SCOPE();
              ruby_cref = saved_cref;
              if (safe >= 0) { ruby_safe_level = safe; }
              switch (state) {
                case 0:
                  break;
                case TAG_BREAK:
                case TAG_RETURN:
                  JUMP_TAG(state);
                  break;
                case TAG_RETRY:
                  if (rb_block_given_p()) { JUMP_TAG(state); }
                  /* fall through */
                default:
                  jump_tag_but_local_jump(state, result);
              }
              break;
            default:
              console.log('unimplemented node type in rb_call0: %x', nd_type(body));
          }
          POP_FRAME();
          POP_ITER();
          return result;
        }
      END
    end
    
    # verbatim
    def rb_call_super
      add_function :rb_name_error, :rb_id2name, :method_missing, :rb_call
      <<-END
        function rb_call_super(argc, argv) {
          var result;
          var self;
          var klass;
          if (ruby_frame.last_class === 0) { rb_name_error(ruby_frame.last_func, "calling 'super' from '%s' is prohibited", rb_id2name(ruby_frame.orig_func)); }
          self = ruby_frame.self;
          klass = ruby_frame.last_class;
          if (klass.superclass === 0) { return method_missing(self, ruby_frame.orig_func, argc, argv, CSTAT_SUPER); }
          PUSH_ITER(ruby_iter.iter ? ITER_PRE : ITER_NOT);
          result = rb_call(klass.superclass, self, ruby_frame.orig_func, argc, argv, 3, Qundef);
          POP_ITER();
          return result;
        }
      END
    end
    
    # modified cache handling
    def rb_clear_cache
      <<-END
        function rb_clear_cache() {
          if (!ruby_running) { return; }
          for (var x in cache) { cache[x].mid = 0; }
        }
      END
    end
    
    # modified cache handling
    def rb_clear_cache_by_class
      <<-END
        function rb_clear_cache_by_class(klass) {
          if (!ruby_running) { return; }
          for (var x in cache) {
            var ent = cache[x];
            if ((ent.klass == klass) || (ent.origin == klass)) { ent.mid = 0; }
          }
        }
      END
    end
    
    # modified cache handling
    def rb_clear_cache_by_id
      <<-END
        function rb_clear_cache_by_id(id) {
          if (!ruby_running) { return; }
          for (var x in cache) {
            var ent = cache[x];
            if (ent.mid == id) { ent.mid = 0; }
          }
        }
      END
    end
    
    # CHECK THIS; IT'S WEIRD
    def rb_copy_node_scope
      <<-END
        function rb_copy_node_scope(node, rval) {
          var copy = NEW_NODE(NODE_SCOPE, 0, rval, node.nd_next);
          if (node.nd_tbl) {
            copy.u1 = []; // was 'copy->nd_tbl = ALLOC_N(ID, node->nd_tbl[0]+1)'
            copy.nd_tbl.zero = node.nd_tbl; // added... but why?
            MEMCPY(copy.nd_tbl, node.nd_tbl, node.nd_tbl.length); // was 'MEMCPY(copy->nd_tbl, node->nd_tbl, ID, node->nd_tbl[0]+1)'
          } else {
            copy.u1 = 0;
          }
          return copy;
        }
      END
    end
    
    # verbatim
    def rb_define_alloc_func
      add_function :rb_add_method, :rb_singleton_class, :rb_check_type
      <<-END
        function rb_define_alloc_func(klass, func) {
          Check_Type(klass, T_CLASS);
          rb_add_method(rb_singleton_class(klass), ID_ALLOCATOR, NEW_CFUNC(func, 0), NOEX_PRIVATE);
        }
      END
    end
    
    # verbatim
    def rb_dvar_ref
      <<-END
        function rb_dvar_ref(id) {
          var vars = ruby_dyna_vars;
          while (vars) {
            if (vars.id == id) { return vars.val; }
            vars = vars.next;
          }
          return Qnil;
        }
      END
    end
    
    # removed thread check
    def rb_ensure
      <<-END
        function rb_ensure(b_proc, data1, e_proc, data2) {
          var state;
          var result = Qnil;
          var retval;
          PUSH_TAG(PROT_NONE);
          try { // was EXEC_TAG
            result = b_proc(data1);
          } catch (x) {
            if (typeof(state = x) != 'number') { throw(state); }
          }
          POP_TAG();
          retval = (prot_tag) ? prot_tag.retval : Qnil; /* save retval */
          e_proc(data2); // was 'if (!thread_no_ensure()) { (*e_proc)(data2); }'
          if (prot_tag) { return_value(retval); }
          if (state) { JUMP_TAG(state); }
          return result;
        }
      END
    end
    
    # CHECK
    def rb_eval
      add_function :ev_const_get, :rb_dvar_ref, :block_pass, :rb_hash_new,
                   :rb_hash_aset, :rb_alias, :rb_to_id, :rb_ary_new,
                   :local_tbl, :module_setup, :class_prefix, :rb_copy_node_scope,
                   :rb_const_get_from, :rb_gvar_set, :rb_gvar_get, :rb_global_entry,
                   :handle_rescue
      add_method :[]=
      <<-END
        function rb_eval(self, node) {
          ruby_current_node = node;
          var state = 0;
          var result = Qnil;
          var contnode = 0;
          var finish_flag = 0xfe;
          var again_flag = 0xff;
          do {
            try {
              var goto_again = 0;
              if (!node) { RETURN(Qnil); }
              switch (nd_type(node)) {
                case NODE_ALIAS:
                  rb_alias(ruby_class, rb_to_id(rb_eval(self, node.nd_1st)), rb_to_id(rb_eval(self, node.nd_2nd)));
                  result = Qnil;
                  break;

                case NODE_AND:
                  result = rb_eval(self, node.nd_1st);
                  if (!RTEST(result)) { break; }
                  node = node.nd_2nd;
                  throw({ goto_flag: again_flag });
                  break;
                
                case NODE_ARRAY:
                  var ary = rb_ary_new(); // changed from rb_ary_new2, ignoring node->nd_alen
                  for (var i = 0, dest = ary.ptr; node; node = node.nd_next) {
                    dest[i++] = rb_eval(self, node.nd_head);
                    // removed ary->len
                  }
                  result = ary;
                  break;
                
                // verbatim
                case NODE_ATTRASGN:
                  var recv;
                  var argc;
                  var argv;
                  var scope;
                //TMP_PROTECT;
                  BEGIN_CALLARGS;
                  if (node.nd_recv == 1) {
                    recv = self;
                    scope = 1;
                  } else {
                    recv = rb_eval(self, node.nd_recv);
                    scope = 0;
                  }
                  SETUP_ARGS(node.nd_args);
                  END_CALLARGS;
                  ruby_current_node = node;
                  rb_call(CLASS_OF(recv), recv, node.nd_mid, argc, argv, scope, self);
                  result = argv[argc - 1];
                
                // verbatim
                case NODE_BEGIN:
                  node = node.nd_body;
                  throw({ goto_flag: again_flag }); // was 'goto again'
                
                // verbatim
                case NODE_BREAK:
                  break_jump(rb_eval(self, node.nd_stts));
                  break;

                // verbatim
                case NODE_BLOCK:
                  if (contnode) {
                    result = rb_eval(self, node);
                    break;
                  }
                  contnode = node.nd_next;
                  node = node.nd_head;
                  throw({ goto_flag: again_flag }); // was 'goto again'

                case NODE_BLOCK_ARG:
                  if (rb_block_given_p()) {
                    result = rb_block_proc();
                    ruby_scope.local_vars[node.nd_cnt] = result;
                  } else {
                    result = Qnil;
                  }
                  break;

                // verbatim
                case NODE_BLOCK_PASS:
                  result = block_pass(self, node);
                  break;

                case NODE_CALL:
                  var recv;
                  var argc;
                  var argv;
                //TMP_PROTECT;
                  BEGIN_CALLARGS;
                  recv = rb_eval(self, node.nd_recv);
                  SETUP_ARGS(node.nd_args);
                  END_CALLARGS;
                  ruby_current_node = node;
                  result = rb_call(CLASS_OF(recv), recv, node.nd_mid, argc, argv, 0, self);
                  break;

                case NODE_CDECL:
                  //u1: vid         (v)     if not zero, only need value and vid; if zero, need value, else, and else.nd_mid
                  //u2: value/mid   (val)   value is always needed; mid is taken from else when else is needed
                  //u3: else        (path)  only needed if vid is 0
                  result = rb_eval(self, node.nd_value);
                  if (node.nd_vid === 0) {
                    // CHECK node.nd_else.nd_mid
                    // CHECK node.nd_else.nd_mid
                    // CHECK node.nd_else.nd_mid
                    // CHECK node.nd_else.nd_mid
                    // CHECK node.nd_else.nd_mid
                    rb_const_set(class_prefix(self, node.nd_else), node.nd_else.nd_mid, result);
                  } else {
                    rb_const_set(ruby_cbase, node.nd_vid, result);
                  }
                  break;

                // verbatim
                case NODE_CASE:
                  var val = rb_eval(self, node.nd_head);
                  var node = node.nd_body;
                  while (node) {
                    var tag;
                    if (nd_type(node) != NODE_WHEN) { throw({ goto_flag: again_flag }); } // was 'goto again'
                    tag = node.nd_head;
                    while (tag) {
                      // removed event hook
                      if (tag.nd_head && (nd_type(tag.nd_head) == NODE_WHEN)) {
                        var v = rb_eval(self, tag.nd_head.nd_head);
                        if (TYPE(v) != T_ARRAY) { v = rb_ary_to_ary(v); }
                        for (var i = 0, p = v.ptr, l = v.ptr.length; i < l; ++i) {
                          if (RTEST(rb_funcall2(p[i], eqq, 1, [val]))) { // changed &val to [val]
                            node = node.nd_body;
                            throw({ goto_flag: again_flag }); // was 'goto again'
                          }
                        }
                        tag = tag.nd_next;
                        continue;
                      }
                      if (RTEST(rb_funcall2(rb_eval(self, tag.nd_head), eqq, 1, [val]))) { // changed &val to [val]
                        node = node.nd_body;
                        throw({ goto_flag: again_flag }); // was 'goto again'
                      }
                      tag = tag.nd_next;
                    }
                    node = node.nd_next;
                  }
                  RETURN(Qnil);
                  break;

                case NODE_CLASS:
                  var superclass;
                  var gen = Qfalse;
                  var cbase = class_prefix(self, node.nd_cpath);
                  var cname = node.nd_cpath.nd_mid;

                  if (node.nd_super) {
                    superclass = rb_eval(self, node.nd_super);
                    rb_check_inheritable(superclass);
                  } else {
                    superclass = 0;
                  }

                  if (rb_const_defined_at(cbase, cname)) {
                    var klass = rb_const_get_at(cbase, cname);
                    if (TYPE(klass) != T_CLASS) { rb_raise(rb_eTypeError, "%s is not a class", rb_id2name(cname)); }
                    if (superclass) {
                      var tmp = rb_class_real(klass.superclass);
                      if (tmp != superclass) { rb_raise(rb_eTypeError, "superclass mismatch for class %s", rb_id2name(cname)); }
                      superclass = 0;
                    }
                    if (ruby_safe_level >= 4) { rb_raise(rb_eSecurityError, "extending class prohibited"); }
                  } else {
                    if (!superclass) { superclass = rb_cObject; }
                    var klass = rb_define_class_id(cname, superclass);
                    rb_set_class_path(klass, cbase, rb_id2name(cname));
                    rb_const_set(cbase, cname, klass);
                    gen = Qtrue;
                  }

                  if (superclass && gen) { rb_class_inherited(superclass, klass); }
                  result = module_setup(klass, node);
                  break;

                case NODE_COLON2:
                  var klass = rb_eval(self, node.nd_head);
                  switch (TYPE(klass)) {
                    case T_CLASS:
                    case T_MODULE:
                      result = rb_const_get_from(klass, node.nd_mid);
                      break;
                    default:
                      rb_raise(rb_eTypeError, "%s is not a class/module", rb_obj_as_string(klass).ptr);
                  }
                  break;

                case NODE_COLON3:
                  result = rb_const_get_from(rb_cObject, node.nd_mid);
                  break;

                case NODE_CONST:
                  result = ev_const_get(ruby_cref, node.nd_vid, self);
                  break;

                case NODE_CVAR:
                  result = rb_cvar_get(cvar_cbase(), node.nd_vid);
                  break;

                case NODE_CVASGN:
                case NODE_CVDECL:
                  result = rb_eval(self, node.nd_value);
                  rb_cvar_set(cvar_cbase(), node.nd_vid, result);
                  break;

                case NODE_DASGN_CURR:
                  result = rb_eval(self, node.nd_value);
                  dvar_asgn_curr(node.nd_vid, result);
                  break;

                case NODE_DEFINED:
                  var desc = is_defined(self, node.nd_head);
                  result = desc ? rb_str_new(desc) : Qnil;
                  break;

                case NODE_DEFN:
                  if (node.nd_defn) {
                    rb_frozen_class_p(ruby_class);
                    var tmp = search_method(ruby_class, node.nd_mid);
                    var body = tmp[0];
                    var origin = tmp[1];

                    var noex = NOEX_PUBLIC;
                    if (SCOPE_TEST(SCOPE_PRIVATE) || (node.nd_mid == init)) { noex = NOEX_PRIVATE; } else
                    if (SCOPE_TEST(SCOPE_PROTECTED)) { noex = NOEX_PROTECTED; }
                    if (body && (origin == ruby_class) && (body.nd_body === 0)) { noex |= NOEX_NOSUPER; }

                    var defn = rb_copy_node_scope(node.nd_defn, ruby_cref);
                    rb_add_method(ruby_class, node.nd_mid, defn, noex);

                    if (scope_vmode == SCOPE_MODFUNC) {
                      rb_add_method(rb_singleton_class(ruby_class), node.nd_mid, defn, NOEX_PUBLIC);
                    }
                    result = Qnil;
                  }
                  break;

                case NODE_DEFS:
                  if (node.nd_defn) {
                    var data;
                    var body = 0;
                    var recv = rb_eval(self, node.nd_recv);

                    if (ruby_safe_level >= 4 && !OBJ_TAINTED(recv)) { rb_raise(rb_eSecurityError, "Insecure: can't define singleton method"); }
                    if (FIXNUM_P(recv) || SYMBOL_P(recv)) { rb_raise(rb_eTypeError, "can't define singleton method '%s' for %s", rb_id2name(node.nd_mid, rb_obj_classname(recv))); }
                    if (OBJ_FROZEN(recv)) { rb_error_frozen("object"); }
                    var klass = rb_singleton_class(recv);
                    if ((data = st_lookup(klass.m_tbl, node.nd_mid))[0]) {
                      body = data[1];
                      if (ruby_safe_level >= 4) { rb_raise(rb_eSecurityError, "redefining method prohibited"); }
                    }
                    var defn = rb_copy_node_scope(node.nd_defn, ruby_cref);
                    rb_add_method(klass, node.nd_mid, defn, NOEX_PUBLIC | (body ? body.nd_noex & NOEX_UNDEF : 0));
                    result = Qnil;
                  }
                  break;

                case NODE_DOT2:
                case NODE_DOT3:
                  var beg = rb_eval(self, node.nd_beg);
                  var end = rb_eval(self, node.nd_end);
                  result = rb_range_new(beg, end, nd_type(node) == NODE_DOT3);
                  break;

                case NODE_DREGX:
                case NODE_DREGX_ONCE:
                case NODE_DSTR:
                case NODE_DSYM:
                case NODE_DXSTR:
                  var str2;
                  var list = node.nd_next;
                  var str = rb_str_new(node.nd_lit);
                  while (list) {
                    if (list.nd_head) {
                      switch (nd_type(list.nd_head)) {
                        case NODE_STR:
                          str2 = list.nd_head.nd_lit;
                          break;
                        default:
                          str2 = rb_eval(self, list.nd_head);
                      }
                      rb_str_append(str, str2);
                      OBJ_INFECT(str, str2);
                    }
                    list = list.nd_next;
                  }
                  switch (nd_type(node)) {
                    case NODE_DREGX:
                      result = rb_reg_new(str.ptr, str.ptr.length, node.nd_cflag);
                      break;
                    case NODE_DREGX_ONCE:
                      result = rb_reg_new(str.ptr, str.ptr.length, node.nd_cflag);
                      nd_set_type(node, NODE_LIT);
                      node.nd_lit = result;
                      break;
                    case NODE_DXSTR:
                      result = rb_funcall(self, '`', 1, str); // may need to change this to support backticks
                      break;
                    case NODE_DSYM:
                      result = rb_str_intern(str);
                      break;
                    default:
                      result = str;
                  }
                  break;

                case NODE_DVAR:
                  result = rb_dvar_ref(node.nd_vid);
                  break;

                // verbatim
                case NODE_ENSURE:
                  PUSH_TAG(PROT_NONE);
                  try {
                    result = rb_eval(self, node.nd_head);
                  } catch (x) {
                    if (typeof(state = x) != 'number') { throw(state); }
                  }
                  POP_TAG();
                  if (node.nd_ensr) {
                    var retval = prot_tag.retval; /* save retval */
                    var errinfo = ruby_errinfo;
                    rb_eval(self, node.nd_ensr);
                    return_value(retval);
                    ruby_errinfo = errinfo;
                  }
                  if (state) { JUMP_TAG(state); }
                  break;

                case NODE_EVSTR:
                  result = rb_obj_as_string(rb_eval(self, node.nd_body));
                  break;
                
                // verbatim
                case NODE_FALSE:
                  RETURN(Qfalse);
                  break;
                
                case NODE_FCALL:
                  var argc;
                  var argv;
                //TMP_PROTECT;
                  BEGIN_CALLARGS;
                  SETUP_ARGS(node.nd_args);
                  END_CALLARGS;
                  ruby_current_node = node;
                  result = rb_call(CLASS_OF(self), self, node.nd_mid, argc, argv, 1, self);
                  break;
                
                // verbatim
                case NODE_GASGN:
                  result = rb_eval(self, node.nd_value);
                  rb_gvar_set(node.nd_entry, result);
                  break;
                
                // verbatim
                case NODE_GVAR:
                  result = rb_gvar_get(node.nd_entry);
                  break;
                
                // modified hash to build from JS array rather than linked list
                case NODE_HASH:
                  var hash = rb_hash_new();
                  var list = node.nd_head;
                  var key;
                  var val;
                  for (var i = 0, l = list.length; i < l; ++i) {
                    key = rb_eval(self, list[i]);
                    val = rb_eval(self, list[++i]);
                    rb_hash_aset(hash, key, val);
                  }
                  result = hash;
                  break;
                
                case NODE_IASGN:
                  result = rb_eval(self, node.nd_value);
                  rb_ivar_set(self, node.nd_vid, result);
                  break;
                  
                // verbatim
                case NODE_IF:
                  node = RTEST(rb_eval(self, node.nd_cond)) ? node.nd_body : node.nd_else; // removed event hooks
                  throw({ goto_flag: again_flag }); // was 'goto again'

                // unwound 'goto' architecture
                case NODE_ITER:
                case NODE_FOR:
                  PUSH_TAG(PROT_LOOP);
                  PUSH_BLOCK(node.nd_var, node.nd_body);
                  do { // added to handle 'goto' architecture
                    var goto_retry = 0;
                    try { // was EXEC_TAG
                      PUSH_ITER(ITER_PRE);
                      if (nd_type(node) == NODE_ITER) {
                        result = rb_eval(self, node.nd_iter);
                      } else {
                        var recv;
                        _block.flags &= ~BLOCK_D_SCOPE;
                        BEGIN_CALLARGS;
                        recv = rb_eval(self, node.nd_iter);
                        END_CALLARGS;
                        ruby_current_node = node;
                        result = rb_call(CLASS_OF(recv),recv,each,0,0,0,self);
                      }
                      POP_ITER();
                    } catch (x) {
                      if (typeof(state = x) != 'number') { throw(state); }
                      if ((state == TAG_BREAK) && TAG_DST()) {
                        result = prot_tag.retval;
                        state = 0;
                      } else if (state == TAG_RETRY) {
                        state = 0;
                        goto_retry = 1;
                      }
                    }
                  } while (goto_retry); // added to handle 'goto' architecture
                  POP_BLOCK();
                  POP_TAG();
                  if (state) { JUMP_TAG(state); }
                  break;

                case NODE_IVAR:
                  result = rb_ivar_get(self, node.nd_vid);
                  break;

                case NODE_LASGN:
                  result = rb_eval(self, node.nd_value);
                  ruby_scope.local_vars[node.nd_cnt] = result;
                  break;

                case NODE_LVAR:
                  result = ruby_scope.local_vars[node.nd_cnt];
                  break;

                case NODE_LIT:
                  result = node.nd_lit;
                  break;

                // verbatim
                case NODE_MATCH:
                  result = rb_reg_match2(node.nd_lit);
                  break;

                // verbatim
                case NODE_MATCH2:
                  var l = rb_eval(self,node.nd_recv);
                  var r = rb_eval(self,node.nd_value);
                  result = rb_reg_match(l, r);
                  break;

                // verbatim
                case NODE_MATCH3:
                  var r = rb_eval(self,node.nd_recv);
                  var l = rb_eval(self,node.nd_value);
                  result = (TYPE(l) == T_STRING) ? rb_reg_match(r,l) : rb_funcall(l, match, 1, r);
                  break;

                case NODE_MODULE:
                  var module;
                  var cbase = class_prefix(self, node.nd_cpath);
                  var cname = node.nd_cpath.nd_mid;
                  if (rb_const_defined_at(cbase, cname)) {
                    module = rb_const_get_at(cbase, cname);
                    if (TYPE(module) != T_MODULE) { rb_raise(rb_eTypeError, "%s is not a module", rb_id2name(cname)); }
                    if (ruby_safe_level >= 4) { rb_raise(rb_eSecurityError, "extending module prohibited"); }
                  } else {
                    module = rb_define_module_id(cname);
                    rb_set_class_path(module, cbase, rb_id2name(cname));
                    rb_const_set(cbase, cname, module);
                  }
                  result = module_setup(module, node);
                  break;

                // verbatim
                case NODE_NEXT:
                //CHECK_INTS;
                  next_jump(rb_eval(self, node.nd_stts));
                  break;

                // verbatim
                case NODE_NIL:
                  RETURN(Qnil);
                  break;

                case NODE_NOT:
                  result = RTEST(rb_eval(self, node.nd_body)) ? Qfalse : Qtrue;
                  break;

                // unsupported
                case NODE_OPT_N:
                  break;

                case NODE_OR:
                  result = rb_eval(self, node.nd_1st);
                  if (RTEST(result)) { break; }
                  node = node.nd_2nd;
                  throw({ goto_flag: again_flag });
                  break;

                // verbatim
                case NODE_POSTEXE:
                  rb_f_END();
                  nd_set_type(node, NODE_NIL); /* exec just once */
                  result = Qnil;
                  break;

                case NODE_REDO:
                //CHECK_INTS;
                  JUMP_TAG(TAG_REDO);
                  break;

                case NODE_RESCUE:
                  var e_info = ruby_errinfo;
                  var rescuing = 0;
                  PUSH_TAG(PROT_NONE);
                  do {
                    var goto_retry_entry = 0;
                    try {
                      result = rb_eval(self, node.nd_head);
                    } catch (x) {
                      if (typeof(state = x) != 'number') { throw(state); }
                      if (rescuing) {
                        if (rescuing < 0) {
                          /* in rescue argument, just reraise */
                        } else if (state == TAG_RETRY) {
                          rescuing = state = 0;
                          ruby_errinfo = e_info;
                          goto_retry_entry = 1;
                        } else if (state != TAG_RAISE) {
                          result = prot_tag.retval;
                        }
                      } else if (state == TAG_RAISE) {
                        var resq = node.nd_resq;
                        rescuing = -1;
                        while (resq) {
                          ruby_current_node = resq;
                          if (handle_rescue(self, resq)) {
                            state = 0;
                            rescuing = 1;
                            result = rb_eval(self, resq.nd_body);
                            break;
                          }
                          resq = resq.nd_head; /* next rescue */
                        }
                      } else {
                        result = prot_tag.retval;
                      }
                    }
                  } while (goto_retry_entry);
                  POP_TAG();
                  if (state != TAG_RAISE) { ruby_errinfo = e_info; }
                  if (state) { JUMP_TAG(state); }
                  if (!rescuing && (node = node.nd_else)) { /* else clause given */
                    throw({ goto_flag: again_flag }); // was 'goto again'
                  }
                  break;

                case NODE_RETRY:
                //CHECK_INTS;
                  JUMP_TAG(TAG_RETRY);
                  break;

                case NODE_RETURN:
                  return_jump(rb_eval(self, node.nd_stts));
                  break;

                case NODE_SCLASS:
                  result = rb_eval(self, node.nd_recv);
                  if (FIXNUM_P(result) || SYMBOL_P(result)) { rb_raise(rb_eTypeError, "no virtual class for %s", rb_obj_classname(result)); }
                  if (ruby_safe_level >= 4 && !OBJ_TAINTED(result)) { rb_raise(rb_eSecurityError, "Insecure: can't extend object"); }
                  var klass = rb_singleton_class(result);
                  result = module_setup(klass, node);
                  break;

                // possibly unnecessary
                case NODE_SCOPE:
                  console.log('you made it into a NODE_SCOPE in rb_eval(); how did you do that?');
                  break;

                // verbatim
                case NODE_SELF:
                  RETURN(self);
                  break;

                // verbatim
                case NODE_SPLAT:
                  result = splat_value(rb_eval(self, node.nd_head));
                  break;

                case NODE_STR:
                  result = rb_str_new(node.nd_lit);
                  break;

                // verbatim
                case NODE_SVALUE:
                  result = avalue_splat(rb_eval(self, node.nd_head));
                  if (result == Qundef) { result = Qnil; }
                  break;

                // verbatim
                case NODE_TO_ARY:
                  result = rb_ary_to_ary(rb_eval(self, node.nd_head));
                  break;

                // verbatim
                case NODE_TRUE:
                  RETURN(Qtrue);
                  break;

                // unwound 'goto' loop architecture
                case NODE_UNTIL:
                  PUSH_TAG(PROT_LOOP);
                  result = Qnil;
                  try { // was EXEC_TAG
                    if (!(node.nd_state && RTEST(rb_eval(self, node.nd_cond)))) {
                      do { rb_eval(self, node.nd_body); } while (!RTEST(rb_eval(self, node.nd_cond)));
                    }
                  } catch (x) {
                    if (typeof(state = x) != 'number') { throw(state); }
                    switch (state) {
                      case TAG_REDO:
                        state = 0;
                        do { rb_eval(self, node.nd_body); } while (!RTEST(rb_eval(self, node.nd_cond)));
                        break;
                      case TAG_NEXT:
                        state = 0;
                        while (!RTEST(rb_eval(self, node.nd_cond))) { rb_eval(self, node.nd_body); }
                        break;
                      case TAG_BREAK:
                        if (TAG_DST()) {
                          state = 0;
                          result = prot_tag.retval;
                        }
                        break;
                    }
                  }
                  POP_TAG();
                  if (state) { JUMP_TAG(state); }
                  RETURN(result);
                  break;

                case NODE_VALIAS:
                  rb_alias_variable(node.nd_1st, node.nd_2nd);
                  result = Qnil;
                  break;

                case NODE_VCALL:
                  result = rb_call(CLASS_OF(self),self,node.nd_mid,0,0,2,self);
                  break;

                // possibly unnecessary
                case NODE_WHEN:
                  console.log('you made it into a NODE_WHEN in rb_eval(); how did you do that?');
                  break;

                // unwound 'goto' loop architecture
                case NODE_WHILE:
                  PUSH_TAG(PROT_LOOP);
                  result = Qnil;
                  try { // was EXEC_TAG
                    if (!(node.nd_state && !RTEST(rb_eval(self, node.nd_cond)))) {
                      do { rb_eval(self, node.nd_body); } while (RTEST(rb_eval(self, node.nd_cond)));
                    }
                  } catch (x) {
                    if (typeof(state = x) != 'number') { throw(state); }
                    switch (state) {
                      case TAG_REDO:
                        state = 0;
                        do { rb_eval(self, node.nd_body); } while (RTEST(rb_eval(self, node.nd_cond)));
                        break;
                      case TAG_NEXT:
                        state = 0;
                        while (RTEST(rb_eval(self, node.nd_cond))) { rb_eval(self, node.nd_body); }
                        break;
                      case TAG_BREAK:
                        if (TAG_DST()) {
                          state = 0;
                          result = prot_tag.retval;
                        }
                        break;
                    }
                  }
                  POP_TAG();
                  if (state) { JUMP_TAG(state); }
                  RETURN(result);
                  break;

                case NODE_XSTR:
                  result = node.nd_head();
                  result = (result === null || result === undefined) ? Qnil : result;
                  break;

                case NODE_ZARRAY:
                  result = rb_ary_new();
                  break;
              }
            } catch (e) {
              switch (e.goto_flag) {
                case finish_flag:
                  result = e.value;
                  break;
                case again_flag:
                  goto_again = 1;
                  break;
                default:
                  throw(e);
              }
            }
            if (contnode && !goto_again) {
              node = contnode;
              contnode = 0;
              goto_again = 1;
            }
          } while (goto_again);
          return result;
        }
      END
    end
    
    # replaced recursive hash threaded lookup with JS global var 'recursive_hash'
    def rb_exec_recursive
      add_function :rb_obj_id, :recursive_check, :recursive_push, :recursive_pop
      <<-END
        function rb_exec_recursive(func, obj, arg) {
          var hash = recursive_hash;
          var objid = rb_obj_id(obj);
          if (recursive_check(hash, objid)) {
            return func(obj, arg, Qtrue);
          } else {
            var result = Qundef;
            var state = 0;
            hash = recursive_push(hash, objid);
            PUSH_TAG(PROT_NONE);
            try { // was EXEC_TAG
              result = func(obj, arg, Qfalse);
            } catch (x) {
              if (typeof(state = x) != 'number') { throw(state); }
            }
            POP_TAG();
            recursive_pop(hash, objid);
            if (state) { JUMP_TAG(state); }
            return result;
          }
        }
      END
    end
    
    # expanded 'search_method'
    def rb_export_method
      add_function :rb_secure, :rb_add_method, :search_method
      <<-END
        function rb_export_method(klass, name, noex) {
          if (klass == rb_cObject) { rb_secure(4); }
          var tmp = search_method(klass, name);
          var body = tmp[0];
          var origin = tmp[1];
          if (!body && (TYPE(klass) == T_MODULE)) {
            tmp = search_method(rb_cObject, name);
            body = tmp[0];
            origin = tmp[1];
          }
          if (!body || !body.nd_body) { print_undef(klass, name); }
          if (body.nd_noex != noex) {
            if (klass == origin) {
              body.nd_noex = noex;
            } else {
              rb_add_method(klass, name, NEW_ZSUPER(), noex);
            }
          }
        }
      END
    end
    
    # verbatim
    def rb_f_block_given_p
      <<-END
        function rb_f_block_given_p() {
          if (ruby_frame.prev && (ruby_frame.prev.iter == ITER_CUR) && ruby_block) { return Qtrue; }
          return Qfalse;
        }
      END
    end
    
    # unsupported
    def rb_f_END
      add_function :rb_raise
      <<-END
        function rb_f_END() {
          rb_raise(rb_eRuntimeError, "Red doesn't support END blocks");
        }
      END
    end
    
    # ADDED
    def rb_f_log
      <<-END
        function rb_f_log(self,obj) {
          console.log(obj);
          return Qnil;
        }
      END
    end
    
    # verbatim
    def rb_f_raise
      add_function :rb_raise_jump, :rb_make_exception
      <<-END
        function rb_f_raise(argc, argv) {
          rb_raise_jump(rb_make_exception(argc, argv));
          return Qnil; /* not reached */
        }
      END
    end
    
    # verbatim
    def rb_f_send
      add_function :rb_block_given_p, :rb_call, :rb_to_id
      <<-END
        function rb_f_send(argc, argv, recv) {
          if (argc === 0) { rb_raise(rb_eArgError, "no method name given"); }
          var retval;
          PUSH_ITER(rb_block_given_p() ? ITER_PRE : ITER_NOT);
          retval = rb_call(CLASS_OF(recv), recv, rb_to_id(argv[0]), argc - 1, argv.slice(1), 1, Qundef);
          POP_ITER();
          return retval;
        }
      END
    end
    
    # verbatim
    def rb_frozen_class_p
      add_function :rb_error_frozen
      <<-END
        function rb_frozen_class_p(klass) {
          var desc = '???';
          if (OBJ_FROZEN(klass)) {
            if (FL_TEST(klass, FL_SINGLETON)) {
              desc = "object";
            } else {
              switch (TYPE(klass)) {
                case T_MODULE:
                case T_ICLASS:
                  desc = "module";
                  break;
                case T_CLASS:
                  desc = "class";
                  break;
              }
            }
            rb_error_frozen(desc);
          }
        }
      END
    end
    
    # collapsed rb_funcall and vafuncall; simplified va handling
    def rb_funcall
      add_function :rb_call
      <<-END
        function rb_funcall(recv, mid, n) {
          var argv = 0;
          if (n > 0) {
            for (var i = 0, argv = []; i < n; ++i) {
              argv[i] = arguments[i + 3];
            }
          }
          return rb_call(CLASS_OF(recv), recv, mid, n, argv, 1, Qundef);
        }
      END
    end
    
    # verbatim
    def rb_funcall2
      add_function :rb_call
      <<-END
        function rb_funcall2(recv, mid, argc, argv) {
          return rb_call(CLASS_OF(recv), recv, mid, argc, argv, 1, Qundef);
        }
      END
    end
    
    # modified to return array including 'pointers': [body, klassp, idp, noexp], changed cache handling
    def rb_get_method_body
      add_function :search_method
      <<-END
        function rb_get_method_body(klassp, idp, noexp) {
          var id = idp;
          var klass = klassp;
          var origin = 0;
          var body;
          var ent;
          var tmp = search_method(klass, id, origin); // expanded search_method
          body = tmp[0];
          origin = tmp[1];
          if (body === 0 || !body.nd_body) {
            /* store empty info in cache */
            ent = cache[EXPR1(klass, id)] = {}; // was 'ent = cache + EXPR1(klass, id)'
            ent.klass = klass;
            ent.origin = klass;
            ent.mid = ent.mid0 = id;
            ent.noex = 0;
            ent.method = 0;
            return [0,klassp,idp,noexp];
          }
          if (ruby_running) {
            /* store in cache */
            ent = cache[EXPR1(klass, id)] = {}; // was 'ent = cache + EXPR1(klass, id)'
            ent.klass = klass;
            ent.noex = body.nd_noex;
            noexp = body.nd_noex;
            body = body.nd_body;
            if (nd_type(body) == NODE_FBODY) {
              ent.mid = id;
              klassp = body.nd_orig;
              ent.origin = body.nd_orig;
              idp = ent.mid0 = body.nd_mid;
              body = ent.method = body.nd_head;
            } else {
              klassp = origin;
              ent.origin = origin;
              ent.mid = ent.mid0 = id;
              ent.method = body;
            }
          } else {
            noexp = body.nd_noex;
            body = body.nd_body;
            if (nd_type(body) == NODE_FBODY) {
              klassp = body.nd_orig;
              idp = body.nd_mid;
              body = body.nd_head;
            } else {
              klassp = origin;
            }
          }
          return [body, klassp, idp, noexp];
        }
      END
    end
    
    # unwound 'goto' architecture, expanded EXEC_TAG
    def rb_iterate
      <<-END
        function rb_iterate(it_proc, data1, bl_proc, data2) {
          var state = 0;
          var retval = Qnil;
          var node = NEW_IFUNC(bl_proc, data2);
          var self = ruby_top_self;
          PUSH_TAG(PROT_LOOP);
          PUSH_BLOCK(0, node);
          PUSH_ITER(ITER_PRE);
          do { // added to handle 'goto iter_retry'
            var goto_iter_retry = 0;
            try { // was EXEC_TAG
              retval = it_proc(data1);
            } catch (x) {
              if (typeof(state = x) != 'number') { throw(state); }
              if ((state == TAG_BREAK) && TAG_DST()) {
                retval = prot_tag.retval;
                state = 0;
              } else if (state == TAG_RETRY) {
                state = 0;
                goto_iter_retry = 1;
              }
            }
          } while (goto_iter_retry);
          POP_ITER();
          POP_BLOCK();
          POP_TAG();
          switch (state) {
            case 0:
              break;
            default:
              JUMP_TAG(state);
          }
          return retval;
        }
      END
    end
    
    # CHECK
    def rb_longjmp
      add_function :rb_exc_new, :ruby_set_current_source, :get_backtrace,
                   :make_backtrace, :set_backtrace, :rb_obj_dup
      <<-END
        function rb_longjmp(tag, mesg) {
          var at;
          // removed thread handling
          if (NIL_P(mesg)) { mesg = ruby_errinfo; }
          if (NIL_P(mesg)) { mesg = rb_exc_new(rb_eRuntimeError, 0, 0); }
          ruby_set_current_source();
          if (ruby_sourcefile && !NIL_P(mesg)) {
            at = get_backtrace(mesg);
            if (NIL_P(at)) {
              at = make_backtrace();
              if (OBJ_FROZEN(mesg)) { mesg = rb_obj_dup(mesg); }
              set_backtrace(mesg, at);
            }
          }
          if (!NIL_P(mesg)) { ruby_errinfo = mesg; }
          // removed 'debug' section
          // removed 'trap mask' call
          // removed event hook
          if (!prot_tag) { error_print(); }
          // removed thread handler
          JUMP_TAG(tag);
        }
      END
    end
    
    # unwound 'goto' architecture
    def rb_make_exception
      add_function :rb_exc_new3, :rb_intern, :rb_respond_to, :rb_funcall, :rb_obj_is_kind_of, :set_backtrace, :rb_raise
      add_method :exception
      <<-END
        function rb_make_exception(argc, argv) {
          var exception;
          var n;
          var mesg = Qnil;
          switch (argc) {
            case 0:
              mesg = Qnil;
              break;
            case 1:
              if (NIL_P(argv[0])) { break; }
              if (TYPE(argv[0]) == T_STRING) {
                mesg = rb_exc_new3(rb_eRuntimeError, argv[0]);
                break;
              }
              n = 0;
              // removed 'goto exception_call' and duplicated code here
              exception = rb_intern('exception'); 
              if (!rb_respond_to(argv[0], exception)) { rb_raise(rb_eTypeError, "exception class/object expected"); }
              mesg = rb_funcall(argv[0], exception, n, argv[1]);
              break;
            case 2:
            case 3:
              n = 1;
              exception = rb_intern('exception');
              if (!rb_respond_to(argv[0], exception)) { rb_raise(rb_eTypeError, "exception class/object expected"); }
              mesg = rb_funcall(argv[0], exception, n, argv[1]);
              break;
            default:
              rb_raise(rb_eArgError, "wrong number of arguments");
              break;
          }
          if (argc > 0) {
            if (!rb_obj_is_kind_of(mesg, rb_eException)) { rb_raise(rb_eTypeError, "exception object expected"); }
            if (argc > 2) { set_backtrace(mesg, argv[2]); }
          }
          return mesg;
        }
      END
    end
    
    # modified cache handling and expanded rb_get_method_body
    def rb_method_boundp
      add_function :rb_get_method_body
      <<-END
        function rb_method_boundp(klass, id, ex) {
          var ent;
          var noex;
          /* is it in the method cache? */
          ent = cache[EXPR1(klass, id)] || {}; // was 'ent = cache + EXPR1(klass, id)'
          if ((ent.mid == id) && (ent.klass == klass)) {
            if (ex && (ent.noex & NOEX_PRIVATE)) { return Qfalse; }
            if (!ent.method) { return Qfalse; }
            return Qtrue;
          }
          var tmp = rb_get_method_body(klass, id, noex); // expanded
          var body = tmp[0];
          var noex = tmp[3];
          if (body) { return (ex && (noex & NOEX_PRIVATE)) ? Qfalse : Qtrue; }
          return Qfalse;
        }
      END
    end
    
    # verbatim
    def rb_method_node
      add_function :rb_get_method_body
      <<-END
        function rb_method_node(klass, id) {
          return rb_get_method_body(klass, id)[0];
        }
      END
    end
    
    # verbatim
    def rb_need_block
      add_function :rb_block_given_p, :localjump_error
      <<-END
        function rb_need_block() {
          if (!rb_block_given_p()) { localjump_error("no block given", Qnil, 0); }
        }
      END
    end
    
    # reduced nesting of 'union' slots
    def rb_node_newnode
      <<-END
        function rb_node_newnode(type, a0, a1, a2) {
          var n = {
            'rvalue': last_value += 4,
            'flags': T_NODE,
            'nd_file': ruby_sourcefile,
            'u1': a0,
            'u2': a1,
            'u3': a2
          };
          nd_set_line(n,ruby_sourceline);
          nd_set_type(n,type);
          return n;
        }
      END
    end
    
    # verbatim
    def rb_obj_respond_to
      add_function :rb_method_node, :rb_method_boundp, :rb_funcall2
      add_method :respond_to?
      <<-END
        function rb_obj_respond_to(obj, id, priv) {
          var klass = CLASS_OF(obj);
          if (rb_method_node(klass, respond_to) == basic_respond_to) {
            return rb_method_boundp(klass, id, !priv);
          } else {
            var args = [];
            var n = 0;
            args[n++] = ID2SYM(id);
            if (priv) { args[n++] = Qtrue; }
            return RTEST(rb_funcall2(obj, respond_to, n, args));
          }
        }
      END
    end
    
    # removed cont_protect stuff, modified to return array [result, status] instead of using pointers
    def rb_protect
      <<-END
        function rb_protect(proc, data) {
          var result = Qnil;
          var status = 0;
          PUSH_TAG(PROT_NONE);
          try { // was EXEC_TAG
            result = proc(data);
          } catch (x) {
            if (typeof(status = x) != 'number') { throw(status); }
          }
          POP_TAG();
          if (status != 0) { return [Qnil, status]; }
          return [result, 0];
        }
      END
    end
    
    # verbatim
    def rb_raise_jump
      add_function :rb_longjmp
      <<-END
        function rb_raise_jump(mesg) {
          if (ruby_frame != top_frame) {
            PUSH_FRAME(); /* fake frame */
            ruby_frame = _frame.prev.prev;
            rb_longjmp(TAG_RAISE, mesg);
            POP_FRAME();
          }
          rb_longjmp(TAG_RAISE, mesg);
        }
      END
    end
    
    # verbatim
    def rb_rescue
      add_function :rb_rescue2
      <<-END
        function rb_rescue(b_proc, data1, r_proc, data2) {
          return rb_rescue2(b_proc, data1, r_proc, data2, rb_eStandardError, 0);
        }
      END
    end
    
    # modified to use JS 'arguments' object instead of va_list
    def rb_rescue2
      add_function :rb_obj_is_kind_of
      <<-END
        function rb_rescue2(b_proc, data1, r_proc, data2) {
          var result;
          var state = 0;
          var e_info = ruby_errinfo;
          var handle = Qfalse;
          PUSH_TAG(PROT_NONE);
          try { // was EXEC_TAG
            result = b_proc(data1);
          } catch (x) {
            if (typeof(state = x) != 'number') { throw(state); }
            switch (state) {
              case TAG_RETRY:
                if (!handle) { break; }
                handle = Qfalse;
                state = 0;
                ruby_errinfo = Qnil;
              case TAG_RAISE:
                if (handle) { break; }
                handle = Qfalse;
                for (var i = 4, l = arguments.length; i < l; ++i) {
                  if (rb_obj_is_kind_of(ruby_errinfo, arguments[i])) {
                    handle = Qtrue;
                    break;
                  }
                }
                if (handle) {
                  state = 0;
                  if (r_proc) {
                    result = r_proc(data2, ruby_errinfo);
                  } else {
                    result = Qnil;
                  }
                  ruby_errinfo = e_info;
                }
            }
          }
          POP_TAG();
          if (state) { JUMP_TAG(state); }
          return result;
        }
      END
    end
    
    # verbatim
    def rb_respond_to
      add_function :rb_obj_respond_to
      <<-END
        function rb_respond_to(obj, id) {
          return rb_obj_respond_to(obj, id, Qfalse);
        }
      END
    end
    
    # verbatim
    def rb_secure
      add_function :rb_raise, :rb_id2name
      <<-END
        function rb_secure(level) {
          if (level <= ruby_safe_level) {
            if (ruby_frame.last_func) {
              rb_raise(rb_eSecurityError, "Insecure operation '%s' at level %d", rb_id2name(ruby_frame.last_func), ruby_safe_level);
            } else {
              rb_raise(rb_eSecurityError, "Insecure operation at level %d", ruby_safe_level);
            }
          }
        }
      END
    end
    
    # CHECK
    def rb_special_const_p
      <<-END
        function rb_special_const_p(obj) {
          return SPECIAL_CONST_P(obj) ? Qtrue : Qfalse;
        }
      END
    end
    
    # verbatim
    def rb_undef_alloc_func
      add_function :rb_add_method, :rb_singleton_class, :rb_check_type
      <<-END
        function rb_undef_alloc_func(klass) {
          Check_Type(klass, T_CLASS);
          rb_add_method(rb_singleton_class(klass), ID_ALLOCATOR, 0, NOEX_UNDEF);
        }
      END
    end
    
    # verbatim
    def rb_yield
      add_function :rb_yield_0
      <<-END
        function rb_yield(val) {
          return rb_yield_0(val, 0, 0, 0, Qfalse);
        }
      END
    end
    
    # CHECK
    def rb_yield_0
      add_function :rb_need_block, :new_dvar, :rb_raise, :svalue_to_mrhs, :massign, :assign,
                   :rb_ary_new3, :svalue_to_avalue, :avalue_to_svalue, :rb_block_proc,
                   :rb_eval, :scope_dup, :proc_jump_error
      <<-END
        // unwound 'goto' architecture, eliminated GC handlers
        function rb_yield_0(val, x, klass, flags, avalue) {
          var node;
          var vars;
          var result = Qnil;
          var old_cref;
          var block;
          var old_scope;
          var old_vmode;
          var frame;
          var cnode = ruby_current_node;
          var lambda = flags & YIELD_LAMBDA_CALL;
          var state = 0;
          rb_need_block();
          PUSH_VARS();
          block = ruby_block;
          frame = block.frame;
          frame.prev = ruby_frame;
          frame.node = cnode;
          ruby_frame = frame;
          old_cref = ruby_cref;
          ruby_cref = block.cref;
          old_scope = ruby_scope;
          ruby_scope = block.scope;
          old_vmode = scope_vmode;
          scope_vmode = (flags & YIELD_PUBLIC_DEF) ? SCOPE_PUBLIC : block.vmode;
          ruby_block = block.prev;
          if (block.flags & BLOCK_D_SCOPE) {
            ruby_dyna_vars = new_dvar(0, 0, block.dyna_vars)
          } else { /* FOR does not introduce new scope */
            ruby_dyna_vars = block.dyna_vars;
          }
          PUSH_CLASS(klass || block.klass);
          if (!klass) { self = block.self; }
          node = block.body;
          vars = block.vars;
          var goto_pop_state = 0;
          if (vars) {
            PUSH_TAG(PROT_NONE);
            try { // was EXEC_TAG
              var bvar = null;
              do { // added to handled 'goto block_var'
                var goto_block_var = 0;
                if (vars == 1) { // vars == (NODE*)1 : what is this?   original comment: /* no parameter || */
                  if (lambda && val.ptr.length != 0) { rb_raise(rb_eArgError, "wrong number of arguments (%d for 0)", val.ptr.length); }
                } else if (vars == 2) { // vars == (NODE*)2
                  if ((TYPE(val) == T_ARRAY) && (val.ptr.length != 0)) { rb_raise(rb_eArgError, "wrong number of arguments (%d for 0)", val.ptr.length); }
                } else if (!bvar && (nd_type(vars) == NODE_BLOCK_PASS)) {
                  bvar = vars.nd_body;
                  vars = vars.nd_args;
                  goto_block_var = 1;
                } else if (nd_type(vars) == NODE_MASGN) {
                  if (!avalue) { val = svalue_to_mrhs(val, vars.nd_head); }
                  massign(self, vars, val, lambda);
                } else { // unwound local 'goto' architecture
                  var len = 0;
                  if (avalue) {
                    len = val.ptr.length;
                    if (len === 0) {
                      val = Qnil;
                      ruby_current_node = cnode;
                    } else if (len == 1) {
                      val = val.ptr[0];
                    } else {
                      // removed warning
                      ruby_current_node = cnode;
                    }
                  } else if (val == Qundef) {
                    val = Qnil;
                    // removed warning
                    ruby_current_node = cnode;
                  }
                  assign(self, vars, val, lambda);
                }
              } while (goto_block_var); // added to handled 'goto block_var'
              if (bvar) {
                var blk;
                if (flags & YIELD_PROC_CALL) {
                  blk = block.block_obj;
                } else {
                  blk = rb_block_proc();
                }
                assign(self, bvar, blk, 0);
              }
            } catch (x) {
              if (typeof(state = x) != 'number') { throw(state); }
            }
            POP_TAG();
            if (state) { goto_pop_state = 1; }
          }
          if (!node && !goto_pop_state) {
            state = 0;
            goto_pop_state = 1;
          }
          if (!goto_pop_state) {
            ruby_current_node = node;
            PUSH_ITER(block.iter);
            PUSH_TAG(lambda ? PROT_NONE : PROT_YIELD);
            do { // added to handle 'goto redo'
              var goto_redo = 0;
              try { // was EXEC_TAG
                if ((nd_type(node) == NODE_CFUNC) || (nd_type(node) == NODE_IFUNC)) {
                  switch (node.nd_state) {
                    case YIELD_FUNC_LAMBDA:
                      if (!avalue) { val = rb_ary_new3(1, val); }
                      break;
                    case YIELD_FUNC_AVALUE:
                      if (!avalue) { val = svalue_to_avalue(val); }
                      break;
                    default:
                      if (avalue) { val = avalue_to_svalue(val); }
                      if ((val == Qundef) && (node.nd_state != YIELD_FUNC_SVALUE)) { val = Qnil; }
                  }
                  result = node.nd_cfnc(val, node.nd_tval, self);
                } else { result = rb_eval(self, node); }
              } catch (x) {
                if (typeof(state = x) != 'number') { throw(state); }
                switch (state) {
                  case TAG_REDO:
                    state = 0;
                  //CHECK_INTS;
                    goto_redo = 1;
                  case TAG_NEXT:
                    if (!lambda) {
                      state = 0;
                      result = prot_tag.retval;
                    }
                    break;
                  case TAG_BREAK:
                    if (TAG_DST()) {
                      result = prot_tag.retval;
                    } else {
                      lambda = Qtrue; /* just pass TAG_BREAK */
                    }
                    break;
                  default:
                    break;
                }
              }
            } while (goto_redo); // added to handle 'goto redo'
            POP_TAG();
            POP_ITER();
          } // added to handle 'goto pop_state'
          POP_CLASS();
          // removed GC stuff
          POP_VARS();
          ruby_block = block;
          ruby_frame = ruby_frame.prev;
          ruby_cref = old_cref;
          if (ruby_scope.flags & SCOPE_DONT_RECYCLE) { scope_dup(old_scope); }
          ruby_scope = old_scope;
          scope_vmode = old_vmode;
          switch (state) {
            case 0:
              break;
            case TAG_BREAK:
              if (!lambda) {
                var tt = prot_tag;
                while (tt) {
                  if ((tt.tag == PROT_LOOP) && (tt.blkid == ruby_block.uniq)) {
                    tt.dst = tt.frame.uniq;
                    tt.retval = result;
                    JUMP_TAG(TAG_BREAK);
                  }
                  tt = tt.prev;
                }
                proc_jump_error(TAG_BREAK, result);
              }
              /* fall through */
            default:
              JUMP_TAG(state);
              break;
          }
          ruby_current_node = cnode;
          return result;
        } 
      END
    end
    
    # verbatim
    def recursive_check
      add_function :rb_hash_aref, :rb_hash_lookup
      <<-END
        function recursive_check(hash, obj) {
          if (NIL_P(hash) || (TYPE(hash) != T_HASH)) {
            return Qfalse;
          } else {
            var list = rb_hash_aref(hash, ID2SYM(ruby_frame.last_func));
            if (NIL_P(list) || TYPE(list) != T_HASH) { return Qfalse; }
            if (NIL_P(rb_hash_lookup(list, obj))) { return Qfalse; }
            return Qtrue;
          }
        }
      END
    end
    
    # verbatim
    def recursive_pop
      add_function :rb_inspect, :rb_raise, :rb_string_value, :rb_hash_aref, :rb_hash_delete
      <<-END
        function recursive_pop(hash, obj) {
          var sym = ID2SYM(ruby_frame.last_func);
          if (NIL_P(hash) || TYPE(hash) != T_HASH) {
            var symname = rb_inspect(sym);
            rb_raise(rb_eTypeError, "invalid inspect_tbl hash for %s", rb_string_value(symname).ptr);
          }
          var list = rb_hash_aref(hash, sym);
          if (NIL_P(list) || TYPE(list) != T_HASH) {
            var symname = rb_inspect(sym);
            rb_raise(rb_eTypeError, "invalid inspect_tbl list for %s", rb_string_value(symname).ptr);
          }
          rb_hash_delete(list, obj);
        }
      END
    end
    
    # replaced recursive hash threaded lookup with JS global var 'recursive_hash'
    def recursive_push
      add_function :rb_hash_new, :rb_hash_aref, :rb_hash_aset
      <<-END
        function recursive_push(hash, obj) {
          var list;
          var sym = ID2SYM(ruby_frame.last_func);
          if (NIL_P(hash) || (TYPE(hash) != T_HASH)) {
            hash = rb_hash_new();
            recursive_hash = hash;
            list = Qnil;
          } else {
            list = rb_hash_aref(hash, sym);
          }
          if (NIL_P(list) || TYPE(list) != T_HASH) {
            list = rb_hash_new();
            rb_hash_aset(hash, sym, list);
          }
          rb_hash_aset(list, obj, Qtrue);
          return hash;
        }
      END
    end
    
    # verbatim
    def return_jump
      add_function :localjump_error
      <<-END
        function return_jump(retval) {
          var tt = prot_tag;
          var yield = Qfalse;
          if (retval == Qundef) { retval = Qnil; }
          while (tt) {
            if (tt.tag == PROT_YIELD) {
              yield = Qtrue;
              tt = tt.prev;
            }
            if ((tt.tag == PROT_FUNC) && (tt.frame.uniq == ruby_frame.uniq)) {
              tt.dst = ruby_frame.uniq;
              tt.retval = retval;
              JUMP_TAG(TAG_RETURN);
            }
            if ((tt.tag == PROT_LAMBDA) && !yield) {
              tt.dst = tt.frame.uniq;
              tt.retval = retval;
              JUMP_TAG(TAG_RETURN);
            }
          //removed thread jump error
            tt = tt.prev;
          }
          localjump_error("unexpected return", retval, TAG_RETURN);
        }
      END
    end
    
    # verbatim
    def ruby_set_current_source
      <<-END
        function ruby_set_current_source() {
          if (ruby_current_node) {
            ruby_sourcefile = ruby_current_node.nd_file;
            ruby_sourceline = nd_line(ruby_current_node);
          }
        }
      END
    end
    
    # IS THE [0] OF A LOCAL TBL ITS LENGTH?
    def scope_dup
      <<-END
        function scope_dup(scope) {
          var tbl;
          var vars;
          scope.flags |= SCOPE_DONT_RECYCLE;
          if (scope.flags & SCOPE_MALLOC) { return; }
          if (scope.local_tbl) {
            tbl = scope.local_tbl;
            vars = []; // was 'vars = ALLOC_N(VALUE, tbl[0]+1)'
            vars.zero = scope.local_vars.zero; // added... but why?
            MEMCPY(vars, scope.local_vars, tbl[0]); // IS THE [0] OF A LOCAL TBL ITS LENGTH?
            scope.local_vars = vars;
            scope.flags |= SCOPE_MALLOC;
          }
        }
      END
    end
    
    # modified to return array including '*origin': [body, origin]
    def search_method
      <<-END
        function search_method(klass, id, origin) {
          var body;
          if (!klass) { return [0, origin]; } // returning array
          while (!(body = st_lookup(klass.m_tbl, id))[0]) {
            klass = klass.superclass;
            if (!klass) { return [0, origin]; }
          }
          origin = klass;
          return [body[1], origin]; // returning array
        }
      END
    end
    
    # verbatim
    def secure_visibility
      add_function :rb_raise
      <<-END
        function secure_visibility(self) {
          if (ruby_safe_level >= 4 && !OBJ_TAINTED(self)) { rb_raise(rb_eSecurityError, "Insecure: can't change method visibility"); }
        }
      END
    end
    
    # verbatim
    def set_backtrace
      add_function :rb_funcall, :rb_intern
      add_method :set_backtrace
      <<-END
        function set_backtrace(info, bt) {
          rb_funcall(info, rb_intern('set_backtrace'), 1, bt);
        }
      END
    end
    
    # verbatim
    def set_method_visibility
      add_function :rb_export_method, :rb_to_id, :rb_clear_cache_by_class, :secure_visibility
      <<-END
        function set_method_visibility(self, argc, argv, ex) {
          secure_visibility(self);
          for (var i = 0; i < argc; ++i) {
            rb_export_method(self, rb_to_id(argv[i]), ex);
          }
          rb_clear_cache_by_class(self);
        }
      END
    end
    
    # removed option to eval a string
    def specific_eval
      add_function :rb_block_given_p, :rb_raise, :yield_under
      <<-END
        function specific_eval(argc, argv, klass, self) {
          if (rb_block_given_p()) {
            if (argc > 0) { rb_raise(rb_eArgError, "wrong number of arguments (%d for 0)", argc); }
            return yield_under(klass, self, Qundef);
          } else {
            rb_raise(rb_eArgError, "block not supplied");
          }
        }
      END
    end
    
    # verbatim
    def splat_value
      add_function :rb_Array, :rb_ary_new3
      <<-END
        function splat_value(v) {
          return NIL_P(v) ? rb_ary_new3(1, Qnil) : rb_Array(v);
        }
      END
    end
    
    # verbatim
    def svalue_to_avalue
      add_function :rb_ary_new, :rb_check_array_type, :rb_ary_new3
      <<-END
        function svalue_to_avalue(v) {
          var tmp;
          var top;
          if (v == Qundef) { return rb_ary_new(); }
          tmp = rb_check_array_type(v);
          if (NIL_P(tmp)) { return rb_ary_new3(1, v); }
          if (tmp.ptr.length == 1) {
            top = rb_check_array_type(tmp.ptr[0]);
            if (!NIL_P(top) && top.ptr.length > 1) { return tmp; }
            return rb_ary_new3(1, v);
          }
          return tmp;
        }
      END
    end
    
    # changed rb_ary_new2 to rb_ary_new
    def svalue_to_mrhs
      add_function :rb_ary_new, :rb_check_array_type, :rb_ary_new3
      <<-END
        function svalue_to_mrhs(v, lhs) {
          if (v == Qundef) { return rb_ary_new(); }
          var tmp = rb_check_array_type(v);
          if (NIL_P(tmp)) { return rb_ary_new3(1, v); }
          /* no lhs means splat lhs only */
          if (!lhs) { return rb_ary_new3(1, v); }
          return tmp;
        }
      END
    end
    
    # verbatim
    def top_include
      add_function :rb_secure, :rb_mod_include
      <<-END
        function top_include(argc, argv, self) {
          rb_secure(4);
          return rb_mod_include(argc, argv, rb_cObject);
        }
      END
    end
    
    # verbatim
    def top_public
      add_function :rb_mod_public
      <<-END
        function top_public(argc, argv) {
          return rb_mod_public(argc, argv, rb_cObject);
        }
      END
    end
    
    # modified to use jsprintf instead of va_args
    def warn_printf
      add_function :rb_write_error
      <<-END
        function warn_printf(fmt) {
          for (var i = 1, ary = []; typeof(arguments[i]) != 'undefined'; ++i) { ary.push(arguments[i]); }
          var buf = jsprintf(fmt,ary);
          rb_write_error(buf);
        }
      END
    end
    
    # verbatim
    def yield_args_under_i
      add_function :rb_yield_0
      <<-END
        function yield_args_under_i(info) {
          return rb_yield_0(info[0], info[1], ruby_class, YIELD_PUBLIC_DEF, Qtrue);
        }
      END
    end
    
    # verbatim
    def yield_under
      add_function :exec_under, :yield_under_i, :yield_args_under_i
      <<-END
        function yield_under(under, self, args) {
          if (args == Qundef) {
            return exec_under(yield_under_i, under, 0, self);
          } else {
            return exec_under(yield_args_under_i, under, 0, [args, self]);
          }
        }
      END
    end
    
    # verbatim
    def yield_under_i
      add_function :rb_yield_0
      <<-END
        function yield_under_i(self) {
          return rb_yield_0(self, self, ruby_class, YIELD_PUBLIC_DEF, Qfalse);
        }
      END
    end
  end
  
  include Boot
  include Eval
end
