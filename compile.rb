require 'src/ruby/array'
require 'src/ruby/bignum'
require 'src/ruby/boot'
require 'src/ruby/class'
require 'src/ruby/comparable'
require 'src/ruby/data'
require 'src/ruby/enumerable'
require 'src/ruby/enumerator'
require 'src/ruby/eval'
require 'src/ruby/exception'
require 'src/ruby/false'
require 'src/ruby/fixnum'
require 'src/ruby/float'
require 'src/ruby/hash'
require 'src/ruby/integer'
require 'src/ruby/io'
require 'src/ruby/match'
require 'src/ruby/math'
require 'src/ruby/method'
require 'src/ruby/module'
require 'src/ruby/nil'
require 'src/ruby/numeric'
require 'src/ruby/object'
require 'src/ruby/parse'
require 'src/ruby/precision'
require 'src/ruby/proc'
require 'src/ruby/range'
require 'src/ruby/regexp'
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
      $mc.add_functions :false_xor, :true_xor, :fix_xor, :rb_big_xor
      <<-END
        rb_define_method(rb_cBignum, "^", rb_big_xor, 1);
        rb_define_method(rb_cFalseClass, '^', false_xor, 1);
        rb_define_method(rb_cNilClass, '^', false_xor, 1);
        rb_define_method(rb_cFixnum, '^', fix_xor, 1);
        rb_define_method(rb_cTrueClass, '^', true_xor, 1);
      END
    end
    
    def %
      $mc.add_function :rb_str_format_m, :fix_mod, :flo_mod, :rb_big_modulo
      <<-END
        rb_define_method(rb_cBignum, "%", rb_big_modulo, 1);
        rb_define_method(rb_cString, '%', rb_str_format_m, 1);
        rb_define_method(rb_cFixnum, '%', fix_mod, 1);
        rb_define_method(rb_cFloat, '%', flo_mod, 1);
      END
    end
    
    def &
      $mc.add_functions :false_and, :true_and, :rb_ary_and, :fix_and, :rb_big_and
      <<-END
        rb_define_method(rb_cBignum, "&", rb_big_and, 1);
        rb_define_method(rb_cFalseClass, '&', false_and, 1);
        rb_define_method(rb_cNilClass, '&', false_and, 1);
        rb_define_method(rb_cArray, '&', rb_ary_and, 1);
        rb_define_method(rb_cTrueClass, '&', true_and, 1);
        rb_define_method(rb_cFixnum, '&', fix_and, 1);
      END
    end
    
    def *
      $mc.add_function :rb_str_times, :rb_ary_times, :fix_mul, :flo_mul, :rb_big_mul
      <<-END
        rb_define_method(rb_cString, '*', rb_str_times, 1);
        rb_define_method(rb_cFloat, '*', flo_mul, 1);
        rb_define_method(rb_cBignum, "*", rb_big_mul, 1);
        rb_define_method(rb_cArray, '*', rb_ary_times, 1);
        rb_define_method(rb_cFixnum, '*', fix_mul, 1);
      END
    end
    
    def **
      $mc.add_function :fix_pow, :flo_pow, :rb_big_pow
      <<-END
        rb_define_method(rb_cFixnum, '**', fix_pow, 1);
        rb_define_method(rb_cFloat, '**', flo_pow, 1);
        rb_define_method(rb_cBignum, "**", rb_big_pow, 1);
      END
    end
    
    def +
      $mc.add_function :rb_str_plus, :rb_ary_plus, :fix_plus, :flo_plus, :time_plus, :rb_big_plus
      <<-END
        rb_define_method(rb_cBignum, "+", rb_big_plus, 1);
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
      $mc.add_function :num_uminus, :fix_uminus, :flo_uminus, :rb_big_uminus
      <<-END
        rb_define_method(rb_cNumeric, '-@', num_uminus, 0);
        rb_define_method(rb_cBignum, "-@", rb_big_uminus, 0);
        rb_define_method(rb_cFloat, '-@', flo_uminus, 0);
        rb_define_method(rb_cFixnum, '-@', fix_uminus, 0);
      END
    end
    
    def /
      $mc.add_function :fix_div, :flo_div, :rb_big_div
      <<-END
        rb_define_method(rb_cFixnum, '/', fix_div, 1);
        rb_define_method(rb_cBignum, "/", rb_big_div, 1);
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
      $mc.add_function :rb_str_concat, :rb_ary_push, :rb_fix_lshift, :classes_append, :rb_big_lshift
      <<-END
        rb_define_method(rb_cBignum, "<<", rb_big_lshift, 1);
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
                        :fix_cmp, :flo_cmp, :time_cmp, :rb_big_cmp
      <<-END
        rb_define_method(rb_cTime, "<=>", time_cmp, 1);
        rb_define_method(rb_cModule, '<=>',  rb_mod_cmp, 1);
        rb_define_method(rb_cFloat, '<=>', flo_cmp, 1);
        rb_define_method(rb_cBignum, "<=>", rb_big_cmp, 1);
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
                       :elem_eq, :rb_big_eq
      <<-END
        rb_define_method(rb_cElement, '==', elem_eq, 1);
        rb_define_method(rb_cStruct, '==', rb_struct_equal, 1);
        rb_define_method(rb_cHash,'==', rb_hash_equal, 1);
        rb_define_method(rb_cBignum, "==", rb_big_eq, 1);
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
      $mc.add_function :rb_fix_rshift, :rb_big_rshift
      <<-END
        rb_define_method(rb_cFixnum, '>>', rb_fix_rshift, 1);
        rb_define_method(rb_cBignum, ">>", rb_big_rshift, 1);
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
                       :styles_aref, :rb_big_aref
      <<-END
        rb_define_method(rb_cStyles, '[]', styles_aref, 1);
      //rb_define_method(rb_cBignum, "[]", rb_big_aref, 1);
        rb_define_method(rb_cProperties, '[]', prop_aref, 1);
        rb_define_module_function(rb_mDocument, '[]', elem_find, 1);
      //rb_define_method(rb_cStruct, '[]', rb_struct_aref, 1);
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
      $mc.add_functions :false_or, :true_or, :rb_ary_or, :fix_or, :rb_big_or
      <<-END
        rb_define_method(rb_cBignum, "|", rb_big_or, 1);
        rb_define_method(rb_cFalseClass, '|', false_or, 1);
        rb_define_method(rb_cArray, '|', rb_ary_or, 1);
        rb_define_method(rb_cNilClass, '|', false_or, 1);
        rb_define_method(rb_cFixnum, '|', fix_or,  1);
        rb_define_method(rb_cTrueClass, '|', true_or, 1);
      END
    end
    
    def ~
      $mc.add_function :fix_rev, :rb_big_neg
      <<-END
        rb_define_method(rb_cFixnum, '~', fix_rev, 0);
        rb_define_method(rb_cBignum, "~", rb_big_neg, 0);
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
      $mc.add_function :num_abs, :fix_abs, :flo_abs, :rb_big_abs
      <<-END
        rb_define_method(rb_cNumeric, 'abs', num_abs, 0);
        rb_define_method(rb_cBignum, "abs", rb_big_abs, 0);
        rb_define_method(rb_cFixnum, 'abs', fix_abs, 0);
        rb_define_method(rb_cFloat, 'abs', flo_abs, 0);
      END
    end
    
    def acos
      $mc.add_function :rb_define_module_function, :math_acos
      <<-END
        rb_define_module_function(rb_mMath, "acos", math_acos, 1);
      END
    end
    
    def acosh
      $mc.add_function :rb_define_module_function, :math_acosh
      <<-END
        rb_define_module_function(rb_mMath, "acosh", math_acosh, 1);
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
    
    def asin
      $mc.add_function :rb_define_module_function, :math_asin
      <<-END
        rb_define_module_function(rb_mMath, "asin", math_asin, 1);
      END
    end
    
    def asinh
      $mc.add_function :rb_define_module_function, :math_asinh
      <<-END
        rb_define_module_function(rb_mMath, "asinh", math_asinh, 1);
      END
    end
    
    def at
      $mc.add_function :rb_ary_at, :time_s_at
      <<-END
        rb_define_method(rb_cArray, 'at', rb_ary_at, 1);
        rb_define_singleton_method(rb_cTime, "at", time_s_at, -1);
      END
    end
    
    def atan
      $mc.add_function :rb_define_module_function, :math_atan
      <<-END
        rb_define_module_function(rb_mMath, "atan", math_atan, 1);
      END
    end
    
    def atan2
      $mc.add_function :rb_define_module_function, :math_atan2
      <<-END
        rb_define_module_function(rb_mMath, "atan2", math_atan2, 2);
      END
    end
    
    def atanh
      $mc.add_function :rb_define_module_function, :math_atanh
      <<-END
        rb_define_module_function(rb_mMath, "atanh", math_atanh, 1);
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
      $mc.add_function :num_coerce, :flo_coerce, :rb_big_coerce
      <<-END
        rb_define_method(rb_cNumeric, 'coerce', num_coerce, 1);
        rb_define_method(rb_cBignum, "coerce", rb_big_coerce, 1);
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
    
    def cos
      $mc.add_function :rb_define_module_function, :math_cos
      <<-END
        rb_define_module_function(rb_mMath, "cos", math_cos, 1);
      END
    end
    
    def cosh
      $mc.add_function :rb_define_module_function, :math_cosh
      <<-END
        rb_define_module_function(rb_mMath, "cosh", math_cosh, 1);
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
      $mc.add_function :num_div, :fix_div, :rb_big_div
      <<-END
        rb_define_method(rb_cNumeric, 'div', num_div, 1);
        rb_define_method(rb_cBignum, "div", rb_big_div, 1);
        rb_define_method(rb_cFixnum, 'div', fix_div, 1);
      END
    end
    
    def divmod
      $mc.add_function :num_divmod, :fix_divmod, :flo_divmod, :rb_big_divmod
      <<-END
        rb_define_method(rb_cNumeric, 'divmod', num_divmod, 1);
        rb_define_method(rb_cBignum, "divmod", rb_big_divmod, 1);
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
      $mc.add_function :rb_hash_each, :rb_str_each_line, :rb_ary_each,
                       :rb_struct_each, :enumerator_each, :range_each
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
                       :elem_eql, :time_eql, :rb_big_eql
      <<-END
        rb_define_method(rb_cTime, "eql?", time_eql, 1);
        rb_define_method(rb_cElement, 'eql?', elem_eql, 1);
        rb_define_method(rb_cBignum, "eql?", rb_big_eql, 1);
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
    
    def erf
      $mc.add_function :rb_define_module_function, :math_erf
      <<-END
        rb_define_module_function(rb_mMath, "erf", math_erf, 1);
      END
    end
    
    def erfc
      $mc.add_function :rb_define_module_function, :math_erfc
      <<-END
        rb_define_module_function(rb_mMath, "erfc", math_erfc, 1);
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
    
    def exp
      $mc.add_function :rb_define_module_function, :math_exp
      <<-END
        rb_define_module_function(rb_mMath, "exp", math_exp, 1);
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
      $mc.add_function :fix_quo, :rb_big_quo
      <<-END
        rb_define_method(rb_cFixnum, 'fdiv', fix_quo, 1);
        rb_define_method(rb_cBignum, "fdiv", rb_big_quo, 1);
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
    
    def frexp
      $mc.add_function :rb_define_module_function, :math_frexp
      <<-END
        rb_define_module_function(rb_mMath, "frexp", math_frexp, 1);
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
                       :rb_ary_hash, :flo_hash, :rb_struct_hash, :time_hash,
                       :rb_big_hash
      <<-END
        rb_define_method(rb_cRange, 'hash', range_hash, 0);
        rb_define_method(rb_cStruct, 'hash', rb_struct_hash, 0);
        rb_define_method(rb_cBignum, "hash", rb_big_hash, 0);
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
    
    def hypot
      $mc.add_function :rb_define_module_function, :math_hypot
      <<-END
        rb_define_module_function(rb_mMath, "hypot", math_hypot, 2);
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
      //rb_define_method(rb_cString, 'index', rb_str_index_m, -1);
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
    
    def ldexp
      $mc.add_function :rb_define_module_function, :math_ldexp
      <<-END
        rb_define_module_function(rb_mMath, "ldexp", math_ldexp, 2);
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
      $mc.add_function :rb_f_log, :math_log, :rb_define_global_function, :rb_define_module_function
      <<-END
        rb_define_global_function('log', rb_f_log, 1);
        rb_define_module_function(rb_mMath, "log", math_log, 1);
      END
    end
    
    def log10
      $mc.add_function :rb_define_module_function, :math_log10
      <<-END
        rb_define_module_function(rb_mMath, "log10", math_log10, 1);
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
      $mc.add_function :rb_str_match_m, :rb_reg_match_m
      <<-END
        rb_define_method(rb_cString, 'match', rb_str_match_m, 1);
        rb_define_method(rb_cRegexp, 'match', rb_reg_match_m, 1);
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
      $mc.add_function :num_modulo, :fix_mod, :flo_mod, :rb_big_modulo
      <<-END
        rb_define_method(rb_cNumeric, 'modulo', num_modulo, 1);
        rb_define_method(rb_cBignum, "modulo", rb_big_modulo, 1);
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
      $mc.add_function :num_quo, :fix_quo, :rb_big_quo
      <<-END
        rb_define_method(rb_cNumeric, 'quo', num_quo, 1);
        rb_define_method(rb_cBignum, "quo", rb_big_quo, 1);
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
      $mc.add_function :num_remainder, :rb_big_remainder
      <<-END
        rb_define_method(rb_cNumeric, 'remainder', num_remainder, 1);
        rb_define_method(rb_cBignum, "remainder", rb_big_remainder, 1);
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
    
    def sin
      $mc.add_function :rb_define_module_function, :math_sin
      <<-END
        rb_define_module_function(rb_mMath, "sin", math_sin, 1);
      END
    end
    
    def sinh
      $mc.add_function :rb_define_module_function, :math_sinh
      <<-END
        rb_define_module_function(rb_mMath, "sinh", math_sinh, 1);
      END
    end
    
    def size
      $mc.add_function :rb_hash_size, :rb_str_length, :fix_size, :rb_struct_size, :rb_big_size, :rb_define_alias
      $mc.add_method :length
      <<-END
        rb_define_method(rb_cStruct, 'size', rb_struct_size, 0);
        rb_define_method(rb_cBignum, "size", rb_big_size, 0);
        rb_define_method(rb_cHash,'size', rb_hash_size, 0);
        rb_define_method(rb_cString, 'size', rb_str_length, 0);
        rb_define_alias(rb_cArray, 'size', 'length');
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
      $mc.add_function :rb_str_split_m, :rb_define_global_function, :rb_f_split
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
    
    def sqrt
      $mc.add_function :rb_define_module_function, :math_sqrt
      <<-END
        rb_define_module_function(rb_mMath, "sqrt", math_sqrt, 1);
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
      $mc.add_function :int_succ, :time_succ#, :rb_str_succ
      <<-END
        rb_define_method(rb_cTime, 'succ', time_succ, 0);
      //rb_define_method(rb_cString, 'succ', rb_str_succ, 0);
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
    
    def tan
      $mc.add_function :rb_define_module_function, :math_tan
      <<-END
        rb_define_module_function(rb_mMath, "tan", math_tan, 1);
      END
    end
    
    def tanh
      $mc.add_function :rb_define_module_function, :math_tanh
      <<-END
        rb_define_module_function(rb_mMath, "tanh", math_tanh, 1);
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
      $mc.add_function :resp_text, :elem_text_get, :elem_text_set
      <<-END
        rb_define_method(rb_cElement, 'text', elem_text_get, 0);
        rb_define_method(rb_cResponse, 'text', resp_text, 0);
        rb_define_method(rb_cElement, 'text=', elem_text_set, 1);
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
                       :rb_struct_to_a, :time_to_a, :match_to_a
      <<-END
        rb_define_method(rb_cStruct, 'to_a', rb_struct_to_a, 0);
        rb_define_method(rb_cMatch, 'to_a', match_to_a, 0);
        rb_define_method(rb_cTime, 'to_a', time_to_a, 0);
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
      $mc.add_function :nil_to_f, :rb_str_to_f, :fix_to_f, :flo_to_f, :time_to_f, :rb_big_to_f
      <<-END
        rb_define_method(rb_cNilClass, 'to_f', nil_to_f, 0);
        rb_define_method(rb_cFixnum, 'to_f', fix_to_f, 0);
        rb_define_method(rb_cFloat, 'to_f', flo_to_f, 0);
        rb_define_method(rb_cBignum, "to_f", rb_big_to_f, 0);
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
        rb_define_method(rb_cProc, 'to_s', proc_to_s, 0);
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
end
