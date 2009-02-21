require 'src/redshift/browser'
require 'src/redshift/document'
require 'src/redshift/element'
require 'src/redshift/event'
require 'src/redshift/user_event'
require 'src/redshift/window'
class Red::MethodCompiler
  attr_reader :functions
  
  Ruby = Object.new
  
  def initialize
    @compiled_functions = []
    @missing_functions  = []
    @functions          = ""
    
    @compiled_methods = []
    @missing_methods  = []
    @methods          = ""
  end
  
  def methods
    "      function define_methods() {\n%s}\n" % @methods
  end
  
  def add_functions(*functions_to_compile)
    functions_to_compile.each do |function|
      next if @compiled_functions.include?(function)
      @compiled_functions |= [function]
      result = 
    begin
      self.send(function)
    rescue NoMethodError
      "        console.log(\"missing JS function '%s'\");\n" % function
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
      Ruby.send(method)
    rescue NoMethodError
      "        console.log(\"undefined Ruby method '%s'\");\n" % method
    end
      @methods += result
    end
  end
  
  alias add_method add_methods
  alias add_function add_functions
  
  class << Ruby
    def _!
      $mc.add_function :name_err_mesg_new, :rb_define_singleton_method
      <<-END
        rb_define_singleton_method(rb_cNameErrorMesg, "!", name_err_mesg_new, 3);
      END
    end
    
    def ^
      $mc.add_functions :false_xor, :true_xor, :fix_xor
      <<-END
        rb_define_method(rb_cFalseClass, "^", false_xor, 1);
        rb_define_method(rb_cNilClass, "^", false_xor, 1);
        rb_define_method(rb_cFixnum, "^", fix_xor, 1);
        rb_define_method(rb_cTrueClass, "^", true_xor, 1);
      END
    end
    
    def %
      $mc.add_function :rb_str_format_m, :fix_mod, :flo_mod
      <<-END
        rb_define_method(rb_cString, "%", rb_str_format_m, 1);
        rb_define_method(rb_cFixnum, "%", fix_mod, 1);
        rb_define_method(rb_cFloat, "%", flo_mod, 1);
      END
    end
    
    def &
      $mc.add_functions :false_and, :true_and, :rb_ary_and, :fix_and
      <<-END
        rb_define_method(rb_cFalseClass, "&", false_and, 1);
        rb_define_method(rb_cNilClass, "&", false_and, 1);
        rb_define_method(rb_cArray, "&", rb_ary_and, 1);
        rb_define_method(rb_cTrueClass, "&", true_and, 1);
        rb_define_method(rb_cFixnum, "&", fix_and, 1);
      END
    end
    
    def *
      $mc.add_function :rb_str_times, :rb_ary_times, :fix_mul, :flo_mul
      <<-END
        rb_define_method(rb_cString, "*", rb_str_times, 1);
        rb_define_method(rb_cFloat, "*", flo_mul, 1);
        rb_define_method(rb_cArray, "*", rb_ary_times, 1);
        rb_define_method(rb_cFixnum, "*", fix_mul, 1);
      END
    end
    
    def **
      $mc.add_function :fix_pow, :flo_pow
      <<-END
        rb_define_method(rb_cFixnum, "**", fix_pow, 1);
        rb_define_method(rb_cFloat, "**", flo_pow, 1);
      END
    end
    
    def +
      $mc.add_function :rb_str_plus, :rb_ary_plus, :fix_plus, :flo_plus
      <<-END
        rb_define_method(rb_cString, "+", rb_str_plus, 1);
        rb_define_method(rb_cArray, "+", rb_ary_plus, 1);
        rb_define_method(rb_cFloat, "+", flo_plus, 1);
        rb_define_method(rb_cFixnum, "+", fix_plus, 1);
      END
    end
    
    def +@
      $mc.add_function :num_uplus
      <<-END
        rb_define_method(rb_cNumeric, "+@", num_uplus, 0);
      END
    end
    
    def -
      $mc.add_function :rb_ary_diff, :fix_minus, :flo_minus
      <<-END
        rb_define_method(rb_cArray, "-", rb_ary_diff, 1);
        rb_define_method(rb_cFloat, "-", flo_minus, 1);
        rb_define_method(rb_cFixnum, "-", fix_minus, 1);
      END
    end
    
    def -@
      $mc.add_function :num_uminus, :fix_uminus, :flo_uminus
      <<-END
        rb_define_method(rb_cNumeric, "-@", num_uminus, 0);
        rb_define_method(rb_cFloat, "-@", flo_uminus, 0);
        rb_define_method(rb_cFixnum, "-@", fix_uminus, 0);
      END
    end
    
    def /
      $mc.add_function :fix_div, :flo_div
      <<-END
        rb_define_method(rb_cFixnum, "/", fix_div, 1);
        rb_define_method(rb_cFloat, "/", flo_div, 1);
      END
    end
    
    def <
      $mc.add_function :cmp_lt, :rb_mod_lt, :fix_lt, :flo_lt
      <<-END
        rb_define_method(rb_cModule, "<",  rb_mod_lt, 1);
        rb_define_method(rb_cFixnum, "<",  fix_lt, 1);
        rb_define_method(rb_cFloat, "<", flo_lt, 1);
        rb_define_method(rb_mComparable, "<", cmp_lt, 1);
      END
    end
    
    def <<
      $mc.add_function :rb_str_concat, :rb_ary_push, :rb_fix_lshift
      <<-END
        rb_define_method(rb_cString, "<<", rb_str_concat, 1);
        rb_define_method(rb_cArray, "<<", rb_ary_push, 1);
        rb_define_method(rb_cFixnum, "<<", rb_fix_lshift, 1);
      END
    end
    
    def <=
      $mc.add_function :cmp_le, :rb_class_inherited_p, :fix_le, :flo_le
      <<-END
        rb_define_method(rb_cModule, "<=", rb_class_inherited_p, 1);
        rb_define_method(rb_cFloat, "<=", flo_le, 1);
        rb_define_method(rb_mComparable, "<=", cmp_le, 1);
        rb_define_method(rb_cFixnum, "<=", fix_le, 1);
      END
    end
    
    def <=>
      $mc.add_functions :rb_mod_cmp, :rb_str_cmp_m, :rb_ary_cmp, :rb_num_cmp,
                        :fix_cmp, :flo_cmp
      <<-END
        rb_define_method(rb_cModule, "<=>",  rb_mod_cmp, 1);
        rb_define_method(rb_cFloat, "<=>", flo_cmp, 1);
        rb_define_method(rb_cNumeric, "<=>", num_cmp, 1);
        rb_define_method(rb_cString, "<=>", rb_str_cmp_m, 1);
        rb_define_method(rb_cArray, "<=>", rb_ary_cmp, 1);
        rb_define_method(rb_cFixnum, "<=>", fix_cmp, 1);
     END
    end
    
    def ==
      $mc.add_function :rb_obj_equal, :cmp_equal, :method_eq, :proc_eq,
                       :range_eq, :rb_hash_equal, :rb_str_equal,
                       :rb_ary_equal, :fix_equal, :flo_eq, :rb_struct_equal,
                       :elem_eq
      <<-END
        rb_define_method(rb_cElement, "==", elem_eq, 1);
        rb_define_method(rb_cStruct, "==", rb_struct_equal, 1);
        rb_define_method(rb_cHash,"==", rb_hash_equal, 1);
        rb_define_method(rb_cRange, "==", range_eq, 1);
        rb_define_method(rb_cModule, "==", rb_obj_equal, 1);
        rb_define_method(rb_cMethod, "==", method_eq, 1);
        rb_define_method(rb_cFloat, "==", flo_eq, 1);
        rb_define_method(rb_mKernel, "==", rb_obj_equal, 1);
        rb_define_method(rb_mComparable, "==", cmp_equal, 1);
        rb_define_method(rb_cProc, "==", proc_eq, 1);
        rb_define_method(rb_cString, "==", rb_str_equal, 1);
        rb_define_method(rb_cArray, "==", rb_ary_equal, 1);
        rb_define_method(rb_cFixnum, "==", fix_equal, 1);
        rb_define_method(rb_cUnboundMethod, "==", method_eq, 1);
      END
    end
    
    def ===
      $mc.add_function :rb_equal, :rb_obj_equal, :rb_mod_eqq, :range_include,
                       :rb_define_singleton_method, :syserr_eqq
      <<-END
        rb_define_method(rb_cRange, "===", range_include, 1);
        rb_define_method(rb_cModule, "===", rb_mod_eqq, 1);
        rb_define_method(rb_mKernel, "===", rb_equal, 1);
        rb_define_method(rb_cSymbol, "===", rb_obj_equal, 1);
        rb_define_singleton_method(rb_eSystemCallError, "===", syserr_eqq, 1);
      END
    end
    
    def =~
      $mc.add_function :rb_obj_pattern_match, :rb_str_match
      <<-END
        rb_define_method(rb_mKernel, "=~", rb_obj_pattern_match, 1);
        rb_define_method(rb_cString, "=~", rb_str_match, 1);
      END
    end
    
    def >
      $mc.add_function :cmp_gt, :rb_mod_gt, :fix_gt, :flo_gt
      <<-END
        rb_define_method(rb_cModule, ">",  rb_mod_gt, 1);
        rb_define_method(rb_cFixnum, ">",  fix_gt, 1);
        rb_define_method(rb_cFloat, ">", flo_gt, 1);
        rb_define_method(rb_mComparable, ">", cmp_gt, 1);
      END
    end
    
    def >>
      $mc.add_function :rb_fix_rshift
      <<-END
        rb_define_method(rb_cFixnum, ">>", rb_fix_rshift, 1);
      END
    end
    
    def >=
      $mc.add_function :cmp_ge, :rb_mod_ge, :fix_ge, :flo_ge
      <<-END
        rb_define_method(rb_cModule, ">=", rb_mod_ge, 1);
        rb_define_method(rb_mComparable, ">=", cmp_ge, 1);
        rb_define_method(rb_cFloat, ">=", flo_ge, 1);
        rb_define_method(rb_cFixnum, ">=", fix_ge, 1);
      END
    end
    
    def []
      $mc.add_function :method_call, :rb_proc_call, :rb_hash_s_create,
                       :rb_hash_aref, :rb_define_singleton_method,
                       :rb_str_aref_m, :rb_ary_s_create, :rb_ary_aref,
                       :fix_aref, :rb_struct_aref, :elem_s_find,
                       :rb_define_module_function
      <<-END
        rb_define_module_function(rb_mDocument, "[]", elem_s_find, 1);
      //rb_define_method(rb_cStruct, "[]", rb_struct_aref, 1);
      //rb_define_method(rb_cMethod, "[]", method_call, -1);
      //rb_define_method(rb_cString, "[]", rb_str_aref_m, -1);
        rb_define_singleton_method(rb_cHash, "[]", rb_hash_s_create, -1);
        rb_define_method(rb_cHash,"[]", rb_hash_aref, 1);
      //rb_define_singleton_method(rb_cArray, "[]", rb_ary_s_create, -1);
      //rb_define_method(rb_cArray, "[]", rb_ary_aref, -1);
      //rb_define_method(rb_cFixnum, "[]", fix_aref, 1);
      //rb_define_method(rb_cProc, "[]", rb_proc_call, -2);
      END
    end
    
    def []=
      $mc.add_function :rb_hash_aset, :rb_str_aset_m, :rb_ary_aset, :rb_struct_aset
      <<-END
        rb_define_method(rb_cStruct, "[]=", rb_struct_aset, 2);
        rb_define_method(rb_cHash,"[]=", rb_hash_aset, 2);
        rb_define_method(rb_cString, "[]=", rb_str_aset_m, -1);
        rb_define_method(rb_cArray, "[]=", rb_ary_aset, -1);
      END
    end
    
    def |
      $mc.add_functions :false_or, :true_or, :rb_ary_or, :fix_or
      <<-END
        rb_define_method(rb_cFalseClass, "|", false_or, 1);
        rb_define_method(rb_cArray, "|", rb_ary_or, 1);
        rb_define_method(rb_cNilClass, "|", false_or, 1);
        rb_define_method(rb_cFixnum, "|", fix_or,  1);
        rb_define_method(rb_cTrueClass, "|", true_or, 1);
      END
    end
    
    def ~
      $mc.add_function :fix_rev
      <<-END
        rb_define_method(rb_cFixnum, "~", fix_rev, 0);
      END
    end
    
    def __id__
      $mc.add_function :rb_obj_id
      <<-END
        rb_define_method(rb_mKernel, "__id__", rb_obj_id, 0);
      END
    end
    
    def _dump
      $mc.add_function :name_err_mesg_to_str
      <<-END
        rb_define_method(rb_cNameErrorMesg, "_dump", name_err_mesg_to_str, 1);
      END
    end
    
    def _load
      $mc.add_function :rb_define_singleton_method, :name_err_mesg_load
      <<-END
        rb_define_singleton_method(rb_cNameErrorMesg, "_load", name_err_mesg_load, 1);
      END
    end
    
    def abs
      $mc.add_function :num_abs, :fix_abs, :flo_abs
      <<-END
        rb_define_method(rb_cNumeric, "abs", num_abs, 0);
        rb_define_method(rb_cFixnum, "abs", fix_abs, 0);
        rb_define_method(rb_cFloat, "abs", flo_abs, 0);
      END
    end
    
    def add_listener
      $mc.add_function :uevent_add_listener
      <<-END
        rb_define_method(rb_mUserEvent, "add_listener", uevent_add_listener, 1);
      END
    end
    
    def air?
      $mc.add_function :rb_define_global_function, :rb_f_air_p
      <<-END
        rb_define_global_function("air?", rb_f_air_p, 0);
      END
    end
    
    def all?
      $mc.add_function :enum_all
      <<-END
        rb_define_method(rb_mEnumerable, "all?", enum_all, 0);
      END
    end
    
    def all_symbols
      $mc.add_function :rb_sym_all_symbols, :rb_define_singleton_method
      <<-END
        rb_define_singleton_method(rb_cSymbol, "all_symbols", rb_sym_all_symbols, 0);
      END
    end
    
    def allocate
      $mc.add_function :rb_obj_alloc
      <<-END
        rb_define_method(rb_cClass, "allocate", rb_obj_alloc, 0);
      END
    end
    
    def alt?
      $mc.add_function :event_alt
      <<-END
        rb_define_method(rb_cEvent, "alt?", event_alt, 0);
      END
    end
    
    def ancestors
      $mc.add_function :rb_mod_ancestors
      <<-END
        rb_define_method(rb_cModule, "ancestors", rb_mod_ancestors, 0);
      END
    end
    
    def any?
      $mc.add_function :enum_any
      <<-END
        rb_define_method(rb_mEnumerable, "any?", enum_any, 0);
      END
    end
    
    def append_features
      $mc.add_function :rb_mod_append_features, :rb_define_private_method
      <<-END
        rb_define_private_method(rb_cModule, "append_features", rb_mod_append_features, 1);
      END
    end
    
    def args
      $mc.add_function :nometh_err_args
      <<-END
        rb_define_method(rb_eNoMethodError, "args", nometh_err_args, 0);
      END
    end
    
    def arity
      $mc.add_function :method_arity, :proc_arity
      <<-END
        rb_define_method(rb_cProc, "arity", proc_arity, 0);
        rb_define_method(rb_cMethod, "arity", method_arity, 0);
        rb_define_method(rb_cUnboundMethod, "arity", method_arity, 0);
      END
    end
    
    def Array
      $mc.add_function :rb_f_array, :rb_define_global_function
      <<-END
        rb_define_global_function("Array", rb_f_array, 1);
      END
    end
    
    def at
      $mc.add_function :rb_ary_at
      <<-END
        rb_define_method(rb_cArray, "at", rb_ary_at, 1);
      END
    end
    
    def attr
      $mc.add_function :rb_mod_attr, :rb_define_private_method
      <<-END
        rb_define_private_method(rb_cModule, "attr", rb_mod_attr, -1);
      END
    end
    
    def attr_accessor
      $mc.add_function :rb_mod_attr_accessor, :rb_define_private_method
      <<-END
        rb_define_private_method(rb_cModule, "attr_accessor", rb_mod_attr_accessor, -1);
      END
    end
    
    def attr_reader
      $mc.add_function :rb_mod_attr_reader, :rb_define_private_method
      <<-END
        rb_define_private_method(rb_cModule, "attr_reader", rb_mod_attr_reader, -1);
      END
    end
    
    def attr_writer
      $mc.add_function :rb_mod_attr_writer, :rb_define_private_method
      <<-END
        rb_define_private_method(rb_cModule, "attr_writer", rb_mod_attr_writer, -1);
      END
    end
    
    def backtrace
      $mc.add_function :exc_backtrace
      <<-END
        rb_define_method(rb_eException, "backtrace", exc_backtrace, 0);
      END
    end
    
    def base_type
      $mc.add_function :event_base_type
      <<-END
        rb_define_method(rb_cEvent, "base_type", event_base_type, 0);
      END
    end
    
    def begin
      $mc.add_function :range_first
      <<-END
        rb_define_method(rb_cRange, "begin", range_first, 0);
      END
    end
    
    def between?
      $mc.add_function :cmp_between
      <<-END
        rb_define_method(rb_mComparable, "between?", cmp_between, 2);
      END
    end
    
    def bind
      $mc.add_function :umethod_bind
      <<-END
        rb_define_method(rb_cUnboundMethod, "bind", umethod_bind, 1);
      END
    end
    
    def binding
      $mc.add_function :proc_binding, :rb_f_binding, :rb_define_global_function
      <<-END
        rb_define_global_function("binding", rb_f_binding, 0);
        rb_define_method(rb_cProc, "binding", proc_binding, 0);
      END
    end
    
    def body
      $mc.add_function :doc_body
      <<-END
        rb_define_module_function(rb_mDocument, "body", doc_body, 0);
      END
    end
    
    def bytes
      $mc.add_function :rb_str_each_byte
      <<-END
        rb_define_method(rb_cString, "bytes", rb_str_each_byte, 0);
      END
    end
    
    def bytesize
      $mc.add_function :rb_str_length
      <<-END
        rb_define_method(rb_cString, "bytesize", rb_str_length, 0);
      END
    end
    
    def call
      $mc.add_function :method_call, :rb_proc_call
      <<-END
      //rb_define_method(rb_cMethod, "call", method_call, -1);
        rb_define_method(rb_cProc, "call", rb_proc_call, -2);
      END
    end
    
    def capitalize
      $mc.add_function :rb_str_capitalize
      <<-END
        rb_define_method(rb_cString, "capitalize", rb_str_capitalize, 0);
      END
    end
    
    def capitalize!
      $mc.add_function :rb_str_capitalize_bang
      <<-END
        rb_define_method(rb_cString, "capitalize!", rb_str_capitalize_bang, 0);
      END
    end
    
    def casecmp
      $mc.add_function :rb_str_casecmp
      <<-END
        rb_define_method(rb_cString, "casecmp", rb_str_casecmp, 1);
      END
    end
    
    def ceil
      $mc.add_function :num_ceil, :int_to_i, :flo_ceil
      <<-END
        rb_define_method(rb_cNumeric, "ceil", num_ceil, 0);
        rb_define_method(rb_cFloat, "ceil", flo_ceil, 0);
        rb_define_method(rb_cInteger, "ceil", int_to_i, 0);
      END
    end
    
    def center
      $mc.add_function :rb_str_center
      <<-END
        rb_define_method(rb_cString, "center", rb_str_center, -1);
      END
    end
    
    def chars
      $mc.add_function :rb_str_each_char
      <<-END
        rb_define_method(rb_cString, "chars", rb_str_each_char, 0);
      END
    end
    
    def children
      $mc.add_function :elem_children
      <<-END
        rb_define_method(rb_cElement, "children", elem_children, 0);
      END
    end
    
    def choice
      $mc.add_function :rb_ary_choice
      <<-END
        rb_define_method(rb_cArray, "choice", rb_ary_choice, 0);
      END
    end
    
    def chomp
      $mc.add_function :rb_str_chomp, :rb_f_chomp, :rb_define_global_function
      <<-END
        rb_define_method(rb_cString, "chomp", rb_str_chomp, -1);
        rb_define_global_function("chomp", rb_f_chomp, -1);
      END
    end
    
    def chomp!
      $mc.add_function :rb_str_chomp_bang, :rb_f_chomp_bang
      <<-END
        rb_define_method(rb_cString, "chomp!", rb_str_chomp_bang, -1);
        rb_define_global_function("chomp!", rb_f_chomp_bang, -1);
      END
    end
    
    def chop
      $mc.add_function :rb_str_chop, :rb_f_chop
      <<-END
        rb_define_method(rb_cString, "chop", rb_str_chop, 0);
        rb_define_global_function("chop", rb_f_chop, 0);
      END
    end
    
    def chop!
      $mc.add_function :rb_str_chop_bang, :rb_f_chop_bang,
                       :rb_define_global_function
      <<-END
        rb_define_method(rb_cString, "chop!", rb_str_chop_bang, 0);
        rb_define_global_function("chop!", rb_f_chop_bang, 0);
      END
    end
    
    def chr
      $mc.add_function :int_chr
      <<-END
        rb_define_method(rb_cInteger, "chr", int_chr, 0);
      END
    end
    
    def class
      $mc.add_function :rb_obj_class
      <<-END
        rb_define_method(rb_mKernel, "class", rb_obj_class, 0);
      END
    end
    
    def class_eval
      $mc.add_function :rb_mod_module_eval
      <<-END
        rb_define_method(rb_cModule, "class_eval", rb_mod_module_eval, -1);
      END
    end
    
    def class_exec
      $mc.add_function :rb_mod_module_exec
      <<-END
        rb_define_method(rb_cModule, "class_exec", rb_mod_module_exec, -1);
      END
    end
    
    def class_variable_defined?
      $mc.add_function :rb_mod_cvar_defined
      <<-END
        rb_define_method(rb_cModule, "class_variable_defined?", rb_mod_cvar_defined, 1);
      END
    end
    
    def class_variable_get
      $mc.add_function :rb_mod_cvar_get, :rb_define_private_method
      <<-END
        rb_define_private_method(rb_cModule, "class_variable_get", rb_mod_cvar_get, 1);
      END
    end
    
    def class_variable_set
      $mc.add_function :rb_mod_cvar_set, :rb_define_private_method
      <<-END
        rb_define_private_method(rb_cModule, "class_variable_set", rb_mod_cvar_set, 2);
      END
    end
    
    def class_variables
      $mc.add_function :rb_mod_class_variables
      <<-END
        rb_define_method(rb_cModule, "class_variables", rb_mod_class_variables, 0);
      END
    end
    
    def clear
      $mc.add_function :rb_hash_clear, :rb_ary_clear
      <<-END
        rb_define_method(rb_cHash, "clear", rb_hash_clear, 0);
        rb_define_method(rb_cArray, "clear", rb_ary_clear, 0);
      END
    end
    
    def client
      $mc.add_function :event_client
      <<-END
        rb_define_method(rb_cEvent, "client", event_client, 0);
      END
    end
    
    def clone
      $mc.add_function :rb_obj_clone, :method_clone, :proc_clone
      <<-END
        rb_define_method(rb_cBinding, "clone", proc_clone, 0);
        rb_define_method(rb_cMethod, "clone", method_clone, 0);
        rb_define_method(rb_mKernel, "clone", rb_obj_clone, 0);
        rb_define_method(rb_cUnboundMethod, "clone", method_clone, 0);
        rb_define_method(rb_cProc, "clone", proc_clone, 0);
      END
    end
    
    def code
      $mc.add_function :event_code
      <<-END
        rb_define_method(rb_cEvent, "code", event_code, 0);
      END
    end
    
    def coerce
      $mc.add_function :num_coerce, :flo_coerce
      <<-END
        rb_define_method(rb_cNumeric, "coerce", num_coerce, 1);
        rb_define_method(rb_cFloat, "coerce", flo_coerce, 1);
      END
    end
    
    def collect
      $mc.add_function :enum_collect, :rb_ary_collect
      <<-END
        rb_define_method(rb_mEnumerable, "collect", enum_collect, 0);
        rb_define_method(rb_cArray, "collect", rb_ary_collect, 0);
      END
    end
    
    def collect!
      $mc.add_function :rb_ary_collect_bang
      <<-END
        rb_define_method(rb_cArray, "collect!", rb_ary_collect_bang, 0);
      END
    end
    
    def combination
      $mc.add_function :rb_ary_combination
      <<-END
        rb_define_method(rb_cArray, "combination", rb_ary_combination, 1);
      END
    end
    
    def compact
      $mc.add_function :rb_ary_compact
      <<-END
        rb_define_method(rb_cArray, "compact", rb_ary_compact, 0);
      END
    end
    
    def compact!
      $mc.add_function :rb_ary_cmopact_bang
      <<-END
        rb_define_method(rb_cArray, "compact!", rb_ary_compact_bang, 0);
      END
    end
    
    def concat
      $mc.add_function :rb_str_concat, :rb_ary_concat
      <<-END
        rb_define_method(rb_cString, "concat", rb_str_concat, 1);
        rb_define_method(rb_cArray, "concat", rb_ary_concat, 1);
      END
    end
    
    def const_defined?
      $mc.add_function :rb_mod_const_defined
      <<-END
        rb_define_method(rb_cModule, "const_defined?", rb_mod_const_defined, 1);
      END
    end
    
    def const_get
      $mc.add_function :rb_mod_const_get
      <<-END
        rb_define_method(rb_cModule, "const_get", rb_mod_const_get, 1);
      END
    end
    
    def const_missing
      $mc.add_function :rb_mod_const_missing
      <<-END
        rb_define_method(rb_cModule, "const_missing", rb_mod_const_missing, 1);
      END
    end
    
    def const_set
      $mc.add_function :rb_mod_const_set
      <<-END
        rb_define_method(rb_cModule, "const_set", rb_mod_const_set, 2);
      END
    end
    
    def constants
      $mc.add_function :rb_mod_constants
      <<-END
        rb_define_method(rb_cModule, "constants", rb_mod_constants, 0);
      END
    end
    
    def count
      $mc.add_function :enum_count, :rb_str_count, :rb_ary_count
      <<-END
        rb_define_method(rb_mEnumerable, "count", enum_count, -1);
        rb_define_method(rb_cString, "count", rb_str_count, -1);
        rb_define_method(rb_cArray, "count", rb_ary_count, -1);
      END
    end
    
    def crypt
      $mc.add_function :rb_str_crypt
      <<-END
        rb_define_method(rb_cString, "crypt", rb_str_crypt, 1);
      END
    end
    
    def ctrl?
      $mc.add_function :event_ctrl
      <<-END
        rb_define_method(rb_cEvent, "ctrl?", event_ctrl, 0);
      END
    end
    
    def cycle
      $mc.add_function :enum_cycle, :rb_ary_cycle
      <<-END
        rb_define_method(rb_cArray, "cycle", rb_ary_cycle, -1);
        rb_define_method(rb_mEnumerable, "cycle", enum_cycle, -1);
      END
    end
    
    def default
      $mc.add_function :rb_hash_default
      <<-END
        rb_define_method(rb_cHash,"default", rb_hash_default, -1);
      END
    end
    
    def default=
      $mc.add_function :rb_hash_set_default
      <<-END
        rb_define_method(rb_cHash,"default=", rb_hash_set_default, 1);
      END
    end
    
    def default_proc
      $mc.add_function :rb_hash_default_proc
      <<-END
        rb_define_method(rb_cHash,"default_proc", rb_hash_default_proc, 0);
      END
    end
    
    def define
      $mc.add_function :uevent_s_define, :rb_define_module_function
      <<-END
        rb_define_module_function(rb_mUserEvent, "define", uevent_s_define, 2);
      END
    end
    
    def delete
      $md.add_function :rb_hash_delete, :rb_str_delete, :rb_ary_delete
      <<-END
        rb_define_method(rb_cHash,"delete", rb_hash_delete, 1);
        rb_define_method(rb_cString, "delete", rb_str_delete, -1);
        rb_define_method(rb_cArray, "delete", rb_ary_delete, 1);
      END
    end
    
    def delete!
      $mc.add_function :rb_str_delete_bang
      <<-END
        rb_define_method(rb_cString, "delete!", rb_str_delete_bang, -1);
      END
    end
    
    def delete_at
      $mc.add_function :rb_ary_delete_at_m
      <<-END
        rb_define_method(rb_cArray, "delete_at", rb_ary_delete_at_m, 1);
      END
    end
    
    def delete_if
      $mc.add_function :rb_hash_delete_if, :rb_ary_delete_if
      <<-END
        rb_define_method(rb_cHash,"delete_if", rb_hash_delete_if, 0);
        rb_define_method(rb_cArray, "delete_if", rb_ary_delete_if, 0);
      END
    end
    
    def detect
      $mc.add_function :enum_find
      <<-END
        rb_define_method(rb_mEnumerable, "detect", enum_find, -1);
      END
    end
    
    def div
      $mc.add_function :num_div, :fix_div
      <<-END
        rb_define_method(rb_cNumeric, "div", num_div, 1);
        rb_define_method(rb_cFixnum, "div", fix_div, 1);
      END
    end
    
    def divmod
      $mc.add_function :num_divmod, :fix_divmod, :flo_divmod
      <<-END
        rb_define_method(rb_cNumeric, "divmod", num_divmod, 1);
        rb_define_method(rb_cFixnum, "divmod", fix_divmod, 1);
        rb_define_method(rb_cFloat, "divmod", flo_divmod, 1);
      END
    end
    
    def document
      $mc.add_function :doc_document, :rb_define_module_function
      <<-END
        rb_define_module_function(rb_mDocument, "document", doc_document, 0);
      END
    end
    
    def downcase
      $mc.add_function :rb_str_downcase
      <<-END
        rb_define_method(rb_cString, "downcase", rb_str_downcase, 0);
      END
    end
    
    def downcase!
      $mc.add_function :rb_str_downcase_bang
      <<-END
        rb_define_method(rb_cString, "downcase!", rb_str_downcase_bang, 0);
      END
    end
    
    def downto
      $mc.add_function :int_downto
      <<-END
        rb_define_method(rb_cInteger, "downto", int_downto, 1);
      END
    end
    
    def drop
      $mc.add_function :enum_drop, :rb_ary_drop
      <<-END
        rb_define_method(rb_mEnumerable, "drop", enum_drop, 1);
        rb_define_method(rb_cArray, "drop", rb_ary_drop, 1);
      END
    end
    
    def drop_while
      $mc.add_function :enum_drop_while, :rb_ary_drop_while
      <<-END
        rb_define_method(rb_mEnumerable, "drop_while", enum_drop_while, 0);
        rb_define_method(rb_cArray, "drop_while", rb_ary_drop_while, 0);
      END
    end
    
    def dump
      $mc.add_function :rb_str_dump
      <<-END
        rb_define_method(rb_cString, "dump", rb_str_dump, 0);
      END
    end
    
    def dup
      $mc.add_function :rb_obj_dup, :proc_dup
      <<-END
        rb_define_method(rb_mKernel, "dup", rb_obj_dup, 0);
        rb_define_method(rb_cBinding, "dup", proc_dup, 0);
        rb_define_method(rb_cProc, "dup", proc_dup, 0);
      END
    end
    
    def each
      $mc.add_function :range_each, :rb_hash_each, :rb_str_each_line,
                       :rb_ary_each, :rb_struct_each, :enumerator_each
      <<-END
        rb_define_method(rb_cRange, "each", range_each, 0);
        rb_define_method(rb_cStruct, "each", rb_struct_each, 0);
        rb_define_method(rb_cEnumerator, "each", enumerator_each, 0);
        rb_define_method(rb_cHash,"each", rb_hash_each, 0);
        rb_define_method(rb_cArray, "each", rb_ary_each, 0);
        rb_define_method(rb_cString, "each", rb_str_each_line, -1);
      END
    end
    
    def each_byte
      $mc.add_function :rb_str_each_byte
      <<-END
        rb_define_method(rb_cString, "each_byte", rb_str_each_byte, 0);
      END
    end
    
    def each_char
      $mc.add_function :rb_str_each_char
      <<-END
        rb_define_method(rb_cString, "each_char", rb_str_each_char, 0);
      END
    end
    
    def each_cons
      $mc.add_function :enum_each_cons
      <<-END
        rb_define_method(rb_mEnumerable, "each_cons", enum_each_cons, 1);
      END
    end
    
    def each_index
      $mc.add_function :rby_ary_each_index
      <<-END
        rb_define_method(rb_cArray, "each_index", rb_ary_each_index, 0);
      END
    end
    
    def each_key
      $mc.add_function :rb_hash_each_key
      <<-END
        rb_define_method(rb_cHash,"each_key", rb_hash_each_key, 0);
      END
    end
    
    def each_line
      $mc.add_function :rb_str_each_line
      <<-END
        rb_define_method(rb_cString, "each_line", rb_str_each_line, -1);
      END
    end
    
    def each_pair
      $mc.add_function :rb_hash_each_pair, :rb_struct_each_pair
      <<-END
        rb_define_method(rb_cHash,"each_pair", rb_hash_each_pair, 0);
        rb_define_method(rb_cStruct, "each_pair", rb_struct_each_pair, 0);
      END
    end
    
    def each_slice
      $mc.add_function :enum_each_slice
      <<-END
        rb_define_method(rb_mEnumerable, "each_slice", enum_each_slice, 1);
      END
    end
    
    def each_value
      $mc.add_function :rb_hash_each_value
      <<-END
        rb_define_method(rb_cHash,"each_value", rb_hash_each_value, 0);
      END
    end
    
    def each_with_index
      $mc.add_function :enum_each_with_index, :enumerator_with_index
      <<-END
        rb_define_method(rb_mEnumerable, "each_with_index", enum_each_with_index, 0);
        rb_define_method(rb_cEnumerator, "each_with_index", enumerator_with_index, 0);
      END
    end
    
    def empty?
      $mc.add_function :rb_hash_empty_p, :rb_str_empty, :rb_ary_empty_p
      <<-END
        rb_define_method(rb_cHash,"empty?", rb_hash_empty_p, 0);
        rb_define_method(rb_cArray, "empty?", rb_ary_empty_p, 0);
        rb_define_method(rb_cString, "empty?", rb_str_empty, 0);
      END
    end
    
    def end
      $mc.add_function :range_last
      <<-END
        rb_define_method(rb_cRange, "end", range_last, 0);
      END
    end
    
    def end_with?
      $mc.add_function :rb_str_end_with
      <<-END
        rb_define_method(rb_cString, "end_with?", rb_str_end_with, -1);
      END
    end
    
    def engine
      $mc.add_function :browser_engine, :rb_define_module_function
      <<-END
        rb_define_module_function(rb_mBrowser, "engine", browser_engine, 0);
      END
    end
    
    def entries
      $mc.add_function :enum_to_a
      <<-END
        rb_define_method(rb_mEnumerable, "entries", enum_to_a, -1);
      END
    end
    
    def enum_cons
      $mc.add_function :enum_each_cons
      <<-END
        rb_define_method(rb_mEnumerable, "enum_cons", enum_each_cons, 1);
      END
    end
    
    def enum_for
      $mc.add_function :obj_to_enum
      <<-END
        rb_define_method(rb_mKernel, "enum_for", obj_to_enum, -1);
      END
    end
    
    def enum_slice
      $mc.add_function :enum_each_slice
      <<-END
        rb_define_method(rb_mEnumerable, "enum_slice", enum_each_slice, 1);
      END
    end
    
    def enum_with_index
      $mc.add_function :enum_each_with_index
      <<-END
        rb_define_method(rb_mEnumerable, "enum_with_index", enum_each_with_index, 0);
      END
    end
    
    def eql?
      $mc.add_function :rb_obj_equal, :range_eql, :rb_hash_eql, :rb_str_eql,
                       :rb_ary_eql, :num_eql, :flo_eql, :rb_struct_eql,
                       :elem_eql
      <<-END
        rb_define_method(rb_cElement, "eql?", elem_eql, 1);
        rb_define_method(rb_cNumeric, "eql?", num_eql, 1);
        rb_define_method(rb_cStruct, "eql?", rb_struct_eql, 1);
        rb_define_method(rb_cRange, "eql?", range_eql, 1);
        rb_define_method(rb_cString, "eql?", rb_str_eql, 1);
        rb_define_method(rb_cArray, "eql?", rb_ary_eql, 1);
        rb_define_method(rb_cHash,"eql?", rb_hash_eql, 1);
        rb_define_method(rb_cFloat, "eql?", flo_eql, 1);
        rb_define_method(rb_mKernel, "eql?", rb_obj_equal, 1);
      END
    end
    
    def equal?
      $mc.add_function :rb_obj_equal
      <<-END
        rb_define_method(rb_mKernel, "equal?", rb_obj_equal, 1);
      END
    end
    
    def errno
      $mc.add_function :syserr_errno
      <<-END
        rb_define_method(rb_eSystemCallError, "errno", syserr_errno, 0);
      END
    end
    
    def eval
      $mc.add_function :bind_eval
      <<-END
        rb_define_method(rb_cBinding, "eval", bind_eval, -1);
      END
    end
    
    def even?
      $mc.add_function :int_even_p, :fix_even_p
      <<-END
        rb_define_method(rb_cInteger, "even?", int_even_p, 0);
        rb_define_method(rb_cFixnum, "even?", fix_even_p, 0);
      END
    end
    
    def exception
      $mc.add_function :rb_class_new_instance, :exc_exception, :rb_define_singleton_method
      <<-END
        rb_define_singleton_method(rb_eException, "exception", rb_class_new_instance, -1);
        rb_define_method(rb_eException, "exception", exc_exception, -1);
      END
    end
    
    def exclude_end?
      $mc.add_function :range_exclude_end_p
      <<-END
        rb_define_method(rb_cRange, "exclude_end?", range_exclude_end_p, 0);
      END
    end
    
    def execute_js
      $mc.add_function :doc_execute_js
      <<-END
        rb_define_module_function(rb_mDocument, "execute_js", doc_execute_js, 1);
      END
    end
    
    def exit_value
      $mc.add_function :localjump_xvalue
      <<-END
        rb_define_method(rb_eLocalJumpError, "exit_value", localjump_xvalue, 0);
      END
    end
    
    def extend_object
      $mc.add_function :rb_mod_extend_object, :rb_define_private_method
      <<-END
        rb_define_private_method(rb_cModule, "extend_object", rb_mod_extend_object, 1);
      END
    end
    
    def extended
      $mc.add_functions :rb_obj_dummy, :rb_define_private_method
      <<-END
        rb_define_private_method(rb_cModule, "extended", rb_obj_dummy, 1);
      END
    end
    
    def fdiv
      $mc.add_function :num_quo
      <<-END
        rb_define_method(rb_cNumeric, "fdiv", num_quo, 1);
      END
    end
    
    def fetch
      $mc.add_function :rb_hash_fetch, :rb_ary_fetch
      <<-END
        rb_define_method(rb_cHash,"fetch", rb_hash_fetch, -1);
        rb_define_method(rb_cArray, "fetch", rb_ary_fetch, -1);
      END
    end
    
    def fdiv
      $mc.add_function :fix_quo
      <<-END
        rb_define_method(rb_cFixnum, "fdiv", fix_quo, 1);
      END
    end
    
    def fill
      $mc.add_function :rb_ary_fill
      <<-END
        rb_define_method(rb_cArray, "fill", rb_ary_fill, -1);
      END
    end
    
    def find
      $mc.add_functions :enum_find, :elem_s_find, :rb_define_singleton_method
      <<-END
        rb_define_method(rb_mEnumerable, "find", enum_find, -1);
        rb_define_singleton_method(rb_cElement, "find", elem_s_find, 1);
      END
    end
    
    def find_all
      $mc.add_functions :enum_find_all
      <<-END
        rb_define_method(rb_mEnumerable, "find_all", enum_find_all, 0);
      END
    end
    
    def find_index
      $mc.add_function :enum_find_index, :rb_ary_index
      <<-END
        rb_define_method(rb_mEnumerable, "find_index", enum_find_index, -1);
        rb_define_method(rb_cArray, "find_index", rb_ary_index, -1);
      END
    end
    
    def finite
      $mc.add_function :flo_is_finite_p
      <<-END
        rb_define_method(rb_cFloat, "finite?", flo_is_finite_p, 0);
      END
    end
    
    def first
      $mc.add_function :enum_first, :range_first, :rb_ary_first
      <<-END
        rb_define_method(rb_cRange, "first", range_first, 0);
        rb_define_method(rb_cArray, "first", rb_ary_first, -1);
        rb_define_method(rb_mEnumerable, "first", enum_first, -1);
      END
    end
    
    def first_child
      $mc.add_function :elem_first_child
      <<-END
        rb_define_method(rb_cElement, "first_child", elem_first_child, 0);
      END
    end
    
    def flatten
      $mc.add_function :rb_ary_flatten
      <<-END
        rb_define_method(rb_cArray, "flatten", rb_ary_flatten, -1);
      END
    end
    
    def flatten!
      $mc.add_function :rb_ary_flatten_bang
      <<-END
        rb_define_method(rb_cArray, "flatten!", rb_ary_flatten_bang, -1);
      END
    end
    
    def Float
      $mc.add_function :rb_f_float, :rb_define_global_function
      <<-END
        rb_define_global_function("Float", rb_f_float, 1);
      END
    end
    
    def floor
      $mc.add_function :num_floor, :int_to_i, :flo_floor
      <<-END
        rb_define_method(rb_cNumeric, "floor", num_floor, 0);
        rb_define_method(rb_cFloat, "floor", flo_floor, 0);
        rb_define_method(rb_cInteger, "floor", int_to_i, 0);
      END
    end
    
    def format
      $mc.add_function :rb_f_sprintf, :rb_define_global_function
      <<-END
        rb_define_global_function("format", rb_f_sprintf, -1);
      END
    end
    
    def freeze
      $mc.add_function :rb_obj_freeze, :rb_mod_freeze
      <<-END
        rb_define_method(rb_cModule, "freeze", rb_mod_freeze, 0);
        rb_define_method(rb_mKernel, "freeze", rb_obj_freeze, 0);
      END
    end
    
    def frozen?
      $mc.add_function :rb_obj_frozen_p, :rb_ary_frozen_p
      <<-END
        rb_define_method(rb_mKernel, "frozen?", rb_obj_frozen_p, 0);
        rb_define_method(rb_cArray, "frozen?",  rb_ary_frozen_p, 0);
      END
    end
    
    def gecko?
      $mc.add_function :rb_f_gecko_p, :rb_define_global_function
      <<-END
        rb_define_global_function("gecko?", rb_f_gecko_p, -1);
      END
    end
    
    def grep
      $mc.add_function :enum_grep
      <<-END
        rb_define_method(rb_mEnumerable, "grep", enum_grep, 1);
      END
    end
    
    def group_by
      $mc.add_function :enum_group_by
      <<-END
        rb_define_method(rb_mEnumerable, "group_by", enum_group_by, 0);
      END
    end
    
    def gsub
      $mc.add_function :rb_str_gsub, :rb_f_gsub, :rb_define_global_function
      <<-END
        rb_define_method(rb_cString, "gsub", rb_str_gsub, -1);
        rb_define_global_function("gsub", rb_f_gsub, -1);
      END
    end
    
    def gsub!
      $mc.add_function :rb_str_gsub_bang, :rb_f_gsub_bang, :rb_define_global_function
      <<-END
        rb_define_method(rb_cString, "gsub!", rb_str_gsub_bang, -1);
        rb_define_global_function("gsub!", rb_f_gsub_bang, -1);
      END
    end
    
    def has_key?
      $mc.add_function :rb_hash_has_key
      <<-END
        rb_define_method(rb_cHash,"has_key?", rb_hash_has_key, 1);
      END
    end
    
    def has_value?
      $mc.add_function :rb_hash_has_value
      <<-END
        rb_define_method(rb_cHash,"has_value?", rb_hash_has_value, 1);
      END
    end
    
    def hash
      $mc.add_function :rb_obj_id, :range_hash, :rb_hash_hash, :rb_str_hash_m,
                       :rb_ary_hash, :flo_hash, :rb_struct_hash
      <<-END
        rb_define_method(rb_cRange, "hash", range_hash, 0);
        rb_define_method(rb_cStruct, "hash", rb_struct_hash, 0);
        rb_define_method(rb_cString, "hash", rb_str_hash_m, 0);
        rb_define_method(rb_mKernel, "hash", rb_obj_id, 0);
        rb_define_method(rb_cFloat, "hash", flo_hash, 0);
        rb_define_method(rb_cHash,"hash", rb_hash_hash, 0);
        rb_define_method(rb_cArray, "hash", rb_ary_hash, 0);
      END
    end
    
    def head
      $mc.add_function :doc_head
      <<-END
        rb_define_module_function(rb_mDocument, "head", doc_head, 0);
      END
    end
    
    def hex
      $mc.add_function :rb_str_hex
      <<-END
        rb_define_method(rb_cString, "hex", rb_str_hex, 0);
      END
    end
    
    def html
      $mc.add_function :doc_html
      <<-END
        rb_define_module_function(rb_mDocument, "html", doc_html, 0);
      END
    end
    
    def id2name
      $mc.add_functions :sym_to_s, :fix_id2name
      <<-END
        rb_define_method(rb_cSymbol, "id2name", sym_to_s, 0);
        rb_define_method(rb_cFixnum, "id2name", fix_id2name, 0);
      END
    end
    
    def include
      $mc.add_function :rb_mod_include, :rb_define_private_method
      <<-END
        rb_define_private_method(rb_cModule, "include", rb_mod_include, -1);
      END
    end
    
    def include?
      $mc.add_function :enum_member, :rb_mod_include_p, :range_include,
                       :rb_hash_has_key, :rb_str_include, :rb_ary_includes
      <<-END
        rb_define_method(rb_cRange, "include?", range_include, 1);
        rb_define_method(rb_cHash,"include?", rb_hash_has_key, 1);
        rb_define_method(rb_cArray, "include?", rb_ary_includes, 1);
        rb_define_method(rb_cModule, "include?", rb_mod_include_p, 1);
        rb_define_method(rb_cString, "include?", rb_str_include, 1);
        rb_define_method(rb_mEnumerable, "include?", enum_member, 1);
      END
    end
    
    def included
      $mc.add_functions :rb_obj_dummy, :rb_define_private_method, :rb_define_singleton_method, :prec_included
      <<-END
        rb_define_private_method(rb_cModule, "included", rb_obj_dummy, 1);
        rb_define_singleton_method(rb_mPrecision, "included", prec_included, 1);
      END
    end
    
    def included_modules
      $mc.add_function :rb_mod_included_modules
      <<-END
        rb_define_method(rb_cModule, "included_modules", rb_mod_included_modules, 0);
      END
    end
    
    def index
      $mc.add_function :rb_hash_index, :rb_str_index_m, :rb_ary_index
      <<-END
        rb_define_method(rb_cArray, "index", rb_ary_index, -1);
        rb_define_method(rb_cHash,"index", rb_hash_index, 1);
        rb_define_method(rb_cString, "index", rb_str_index_m, -1);
      END
    end
    
    def indexes
      $mc.add_function :rb_hash_indexes, :rb_ary_indexes
      <<-END
        rb_define_method(rb_cHash,"indexes", rb_hash_indexes, -1);
        rb_define_method(rb_cArray, "indexes", rb_ary_indexes, -1);
      END
    end
    
    def indices
      $mc.add_function :rb_hash_indexes, :rb_ary_indexes
      <<-END
        rb_define_method(rb_cHash,"indices", rb_hash_indexes, -1);
        rb_define_method(rb_cArray, "indices", rb_ary_indexes, -1);
      END
    end
    
    def induced_from
      $mc.add_function :rb_int_induced_from, :rb_define_singleton_method, :rb_fix_induced_from, :rb_flo_induced_from
      <<-END
        rb_define_singleton_method(rb_cInteger, "induced_from", rb_int_induced_from, 1);
        rb_define_singleton_method(rb_cFixnum, "induced_from", rb_fix_induced_from, 1);
        rb_define_singleton_method(rb_cFloat, "induced_from", rb_flo_induced_from, 1);
      END
    end
    
    def infinite?
      $mc.add_function :flo_is_infinite_p
      <<-END
        rb_define_method(rb_cFloat, "infinite?", flo_is_infinite_p, 0);
      END
    end
    
    def inherited
      $mc.add_functions :rb_obj_dummy, :rb_define_private_method
      <<-END
        rb_define_private_method(rb_cClass, "inherited", rb_obj_dummy, 1);
      END
    end
    
    def initialize
      $mc.add_function :rb_class_initialize, :rb_obj_dummy,
                       :rb_define_private_method, :rb_mod_initialize,
                       :range_initialize, :rb_hash_initialize, :rb_str_init,
                       :nometh_err_initialize, :syserr_initialize,
                       :exc_initialize, :name_err_initialize,
                       :exit_initialize, :rb_ary_initialize, :rb_struct_initialize,
                       :enumerator_initialize, :elem_initialize
      <<-END
        rb_define_method(rb_cElement, "initialize", elem_initialize, 1);
        rb_define_method(rb_cEnumerator, "initialize", enumerator_initialize, -1);
        rb_define_method(rb_cStruct, "initialize", rb_struct_initialize, -2);
        rb_define_method(rb_cArray, "initialize", rb_ary_initialize, -1);
        rb_define_method(rb_cHash,"initialize", rb_hash_initialize, -1);
        rb_define_method(rb_cRange, "initialize", range_initialize, -1);
        rb_define_method(rb_cModule, "initialize", rb_mod_initialize, 0);
        rb_define_method(rb_cClass, "initialize", rb_class_initialize, -1);
        rb_define_private_method(rb_cObject, "initialize", rb_obj_dummy, 0);
        rb_define_method(rb_cString, "initialize", rb_str_init, -1);
        rb_define_method(rb_eNoMethodError, "initialize", nometh_err_initialize, -1);
        rb_define_method(rb_eSystemCallError, "initialize", syserr_initialize, -1);
        rb_define_method(rb_eException, "initialize", exc_initialize, -1);
        rb_define_method(rb_eNameError, "initialize", name_err_initialize, -1);
        rb_define_method(rb_eSystemExit, "initialize", exit_initialize, -1);
      END
    end
    
    def initialize_copy
      $mc.add_function :rb_obj_init_copy, :rb_class_init_copy,
                       :rb_mod_init_copy, :rb_hash_replace, :rb_str_replace,
                       :rb_ary_replace, :num_init_copy, :rb_struct_init_copy,
                       :enumerator_init_copy
      <<-END
        rb_define_method(rb_cEnumerator, "initialize_copy", enumerator_init_copy, 1);
        rb_define_method(rb_cStruct, "initialize_copy", rb_struct_init_copy, 1);
        rb_define_method(rb_cHash,"initialize_copy", rb_hash_replace, 1);
        rb_define_method(rb_cArray, "initialize_copy", rb_ary_replace, 1);
        rb_define_method(rb_cModule, "initialize_copy", rb_mod_init_copy, 1);
        rb_define_method(rb_cClass, "initialize_copy", rb_class_init_copy, 1);
        rb_define_method(rb_cNumeric, "initialize_copy", num_init_copy, 1);
        rb_define_method(rb_mKernel, "initialize_copy", rb_obj_init_copy, 1);
        rb_define_method(rb_cString, "initialize_copy", rb_str_replace, 1);
      END
    end
    
    def inject
      $mc.add_function :enum_inject
      <<-END
        rb_define_method(rb_mEnumerable, "inject", enum_inject, -1);
      END
    end
    
    def insert
      $mc.add_function :rb_str_insert, :rb_ary_insert, :elem_insert
      <<-END
        rb_define_method(rb_cElement, "insert", elem_insert, -1);
      //rb_define_method(rb_cString, "insert", rb_str_insert, 2);
      //rb_define_method(rb_cArray, "insert", rb_ary_insert, -1);
      END
    end
    
    def inspect
      $mc.add_function :nil_inspect, :rb_obj_inspect, :range_inspect,
                       :sym_inspect, :method_inspect, :rb_hash_inspect,
                       :rb_str_inspect, :exc_inspect, :rb_ary_inspect,
                       :rb_struct_inspect
      <<-END
        rb_define_method(rb_cStruct, "inspect", rb_struct_inspect, 0);
        rb_define_method(rb_cArray, "inspect", rb_ary_inspect, 0);
        rb_define_method(rb_cRange, "inspect", range_inspect, 0);
        rb_define_method(rb_cString, "inspect", rb_str_inspect, 0);
        rb_define_method(rb_eException, "inspect", exc_inspect, 0);
        rb_define_method(rb_cHash,"inspect", rb_hash_inspect, 0);
        rb_define_method(rb_mKernel, "inspect", rb_obj_inspect, 0);
        rb_define_method(rb_cMethod, "inspect", method_inspect, 0);
        rb_define_method(rb_cNilClass, "inspect", nil_inspect, 0);
        rb_define_method(rb_cSymbol, "inspect", sym_inspect, 0);
        rb_define_method(rb_cUnboundMethod, "inspect", method_inspect, 0);
      END
    end
    
    def instance_method
      $mc.add_function :rb_mod_method
      <<-END
        rb_define_method(rb_cModule, "instance_method", rb_mod_method, 1);
      END
    end
    
    def instance_methods
      $mc.add_function :rb_class_instance_methods
      <<-END
        rb_define_method(rb_cModule, "instance_methods", rb_class_instance_methods, -1);
      END
    end
    
    def instance_of?
      $mc.add_function :rb_obj_is_instance_of
      <<-END
        rb_define_method(rb_mKernel, "instance_of?", rb_obj_is_instance_of, 1);
      END
    end
    
    def instance_variables
      $mc.add_function :rb_obj_instance_variables
      <<-END
        rb_define_method(rb_mKernel, "instance_variables", rb_obj_instance_variables, 0);
      END
    end
    
    def instance_variable_get
      $mc.add_function :rb_obj_ivar_get
      <<-END
        rb_define_method(rb_mKernel, "instance_variable_get", rb_obj_ivar_get, 1);
      END
    end
    
    def instance_variable_set
      $mc.add_function :rb_obj_ivar_set
      <<-END
        rb_define_method(rb_mKernel, "instance_variable_set", rb_obj_ivar_set, 2);
      END
    end
    
    def instance_variable_defined?
      $mc.add_function :rb_obj_ivar_defined
      <<-END
        rb_define_method(rb_mKernel, "instance_variable_defined?", rb_obj_ivar_defined, 1);
      END
    end
    
    def Integer
      $mc.add_function :rb_f_integer, :rb_define_global_function
      <<-END
        rb_define_global_function("Integer", rb_f_integer, 1);
      END
    end
    
    def integer?
      $mc.add_function :num_int_p, :int_int_p
      <<-END
        rb_define_method(rb_cInteger, "integer?", int_int_p, 0);
        rb_define_method(rb_cNumeric, "integer?", num_int_p, 0);
      END
    end
    
    def intern
      $mc.add_function :rb_str_intern
      <<-END
        rb_define_method(rb_cString, "intern", rb_str_intern, 0);
      END
    end
    
    def invert
      $mc.add_function :rb_hash_invert
      <<-END
        rb_define_method(rb_cHash,"invert", rb_hash_invert, 0);
      END
    end
    
    def is_a?
      $mc.add_function :rb_obj_is_kind_of
      <<-END
        rb_define_method(rb_mKernel, "is_a?", rb_obj_is_kind_of, 1);
      END
    end
    
    def join
      $mc.add_function :rb_ary_join_m
      <<-END
        rb_define_method(rb_cArray, "join", rb_ary_join_m, -1);
      END
    end
    
    def key
      $mc.add_function :event_key
      <<-END
        rb_define_method(rb_cEvent, "key", event_key, 0);
      END
    end
    
    def key?
      $mc.add_function :rb_hash_has_key
      <<-END
        rb_define_method(rb_cHash,"key?", rb_hash_has_key, 1);
      END
    end
    
    def keys
      $mc.add_function :rb_hash_keys
      <<-END
        rb_define_method(rb_cHash,"keys", rb_hash_keys, 0);
      END
    end
    
    def kill!
      $mc.add_function :event_kill
      <<-END
        rb_define_method(rb_cEvent, "kill!", event_kill, 0);
      END
    end
    
    def kind_of?
      $mc.add_function :rb_obj_is_kind_of
      <<-END
        rb_define_method(rb_mKernel, "kind_of?", rb_obj_is_kind_of, 1);
      END
    end
    
    def lambda
      $mc.add_function :proc_lambda
      <<-END
        rb_define_global_function("lambda", proc_lambda, 0);
      END
    end
    
    def last
      $mc.add_function :range_last, :rb_ary_last
      <<-END
        rb_define_method(rb_cRange, "last", range_last, 0);
        rb_define_method(rb_cArray, "last", rb_ary_last, -1);
      END
    end
    
    def last_child
      $mc.add_function :elem_last_child
      <<-END
        rb_define_method(rb_cElement, "last_child", elem_last_child, 0);
      END
    end
    
    def length
      $mc.add_function :rb_hash_size, :rb_str_length, :rb_ary_length, :rb_struct_size
      <<-END
        rb_define_method(rb_cString, "length", rb_str_length, 0);
        rb_define_method(rb_cStruct, "length", rb_struct_size, 0);
        rb_define_method(rb_cHash,"length", rb_hash_size, 0);
        rb_define_method(rb_cArray, "length", rb_ary_length, 0);
      END
    end
    
    def lines
      $mc.add_function :rb_str_each_line
      <<-END
        rb_define_method(rb_cString, "lines", rb_str_each_line, -1);
      END
    end
    
    def listen
      $mc.add_function :uevent_listen
      <<-END
        rb_define_method(rb_mUserEvent, "listen", uevent_listen, -1);
      END
    end
    
    def ljust
      $mc.add_function :rb_str_ljust
      <<-END
        rb_define_method(rb_cString, "ljust", rb_str_ljust, -1);
      END
    end
    
    def log
      $mc.add_function :rb_f_log
      <<-END
        rb_define_global_function("log", rb_f_log, 1);
      END
    end
    
    def lstrip
      $mc.add_function :rb_str_lstrip
      <<-END
        rb_define_method(rb_cString, "lstrip", rb_str_lstrip, 0);
      END
    end
    
    def lstrip!
      $mc.add_function :rb_str_lstrip_bang
      <<-END
        rb_define_method(rb_cString, "lstrip!", rb_str_lstrip_bang, 0);
      END
    end
    
    def map
      $mc.add_function :enum_collect, :rb_ary_collect
      <<-END
        rb_define_method(rb_mEnumerable, "map", enum_collect, 0);
        rb_define_method(rb_cArray, "map", rb_ary_collect, 0);
      END
    end
    
    def map!
      $mc.add_function :rb_ary_collect_bang
      <<-END
        rb_define_method(rb_cArray, "map!", rb_ary_collect_bang, 0);
      END
    end
    
    def match
      $mc.add_function :rb_str_match_m
      <<-END
        rb_define_method(rb_cString, "match", rb_str_match_m, 1);
      END
    end
    
    def max
      $mc.add_function :enum_max
      <<-END
        rb_define_method(rb_mEnumerable, "max", enum_max, 0);
      END
    end
    
    def max_by
      $mc.add_function :enum_max_by
      <<-END
        rb_define_method(rb_mEnumerable, "max_by", enum_max_by, 0);
      END
    end
    
    def member?
      $mc.add_function :enum_member, :range_include, :rb_hash_has_key
      <<-END
        rb_define_method(rb_cHash,"member?", rb_hash_has_key, 1);
        rb_define_method(rb_cRange, "member?", range_include, 1);
        rb_define_method(rb_mEnumerable, "member?", enum_member, 1);
      END
    end
    
    def members
      $mc.add_function :rb_struct_members_m
      <<-END
        rb_define_method(rb_cStruct, "members", rb_struct_members_m, 0);
      END
    end
    
    def merge
      $mc.add_function :rb_hash_merge
      <<-END
        rb_define_method(rb_cHash,"merge", rb_hash_merge, 1);
      END
    end
    
    def merge!
      $mc.add_function :rb_hash_update
      <<-END
        rb_define_method(rb_cHash,"merge!", rb_hash_update, 1);
      END
    end
    
    def message
      $mc.add_function :exc_to_str
      <<-END
        rb_define_method(rb_eException, "message", exc_to_str, 0);
      END
    end
    
    def meta?
      $mc.add_function :event_meta
      <<-END
        rb_define_method(rb_cEvent, "meta?", event_meta, 0);
      END
    end
    
    def method
      $mc.add_function :rb_obj_method
      <<-END
        rb_define_method(rb_mKernel, "method", rb_obj_method, 1);
      END
    end
    
    def method_added
      $mc.add_function :rb_define_private_method, :rb_obj_dummy
      <<-END
        rb_define_private_method(rb_cModule, "method_added", rb_obj_dummy, 1);
      END
    end
    
    def method_defined?
      $mc.add_function :rb_mod_method_defined
      <<-END
        rb_define_method(rb_cModule, "method_defined?", rb_mod_method_defined, 1);
      END
    end
    
    def method_missing(*x)
      $mc.add_function :rb_method_missing, :rb_define_global_function
      <<-END
        rb_define_global_function("method_missing", rb_method_missing, -1);
      END
    end
    
    def method_removed
      $mc.add_function :rb_obj_dummy, :rb_define_private_method
      <<-END
        rb_define_private_method(rb_cModule, "method_removed", rb_obj_dummy, 1);
      END
    end
    
    def method_undefined
      $mc.add_function :rb_obj_dummy, :rb_define_private_method
      <<-END
        rb_define_private_method(rb_cModule, "method_undefined", rb_obj_dummy, 1);
      END
    end
    
    def methods
      $mc.add_function :rb_obj_methods
      <<-END
        rb_define_method(rb_mKernel, "methods", rb_obj_methods, -1);
      END
    end
    
    def min
      $mc.add_function :enum_min
      <<-END
        rb_define_method(rb_mEnumerable, "min", enum_min, 0);
      END
    end
    
    def min_by
      $mc.add_function :enum_min_by
      <<-END
        rb_define_method(rb_mEnumerable, "min_by", enum_min_by, 0);
      END
    end
    
    def minmax
      $mc.add_function :enum_minmax
      <<-END
        rb_define_method(rb_mEnumerable, "minmax", enum_minmax, 0);
      END
    end
    
    def minmax_by
      $mc.add_function :enum_minmax_by
      <<-END
        rb_define_method(rb_mEnumerable, "minmax_by", enum_minmax_by, 0);
      END
    end
    
    def module_eval
      $mc.add_function :rb_mod_module_eval
      <<-END
        rb_define_method(rb_cModule, "module_eval", rb_mod_module_eval, -1);
      END
    end
    
    def module_exec
      $mc.add_function :rb_mod_module_exec
      <<-END
        rb_define_method(rb_cModule, "module_exec", rb_mod_module_exec, -1);
      END
    end
    
    def module_function
      $mc.add_function :rb_mod_modfunc, :rb_define_private_method
      <<-END
        rb_define_private_method(rb_cModule, "module_function", rb_mod_modfunc, -1);
      END
    end
    
    def modulo
      $mc.add_function :num_modulo, :fix_mod, :flo_mod
      <<-END
        rb_define_method(rb_cNumeric, "modulo", num_modulo, 1);
        rb_define_method(rb_cFixnum, "modulo", fix_mod, 1);
        rb_define_method(rb_cFloat, "modulo", flo_mod, 1);
      END
    end
    
    def name
      $mc.add_function :method_name, :rb_mod_name, :name_err_name
      <<-END
        rb_define_method(rb_cModule, "name", rb_mod_name, 0);
        rb_define_method(rb_eNameError, "name", name_err_name, 0);
        rb_define_method(rb_cMethod, "name", method_name, 0);
        rb_define_method(rb_cUnboundMethod, "name", method_name, 0);
      END
    end
    
    def nan?
      $mc.add_function :flo_is_nan_p
      <<-END
        rb_define_method(rb_cFloat, "nan?", flo_is_nan_p, 0);
      END
    end
    
    def new
      $mc.add_function :rb_class_new_instance, :proc_s_new, :rb_define_singleton_method, :rb_struct_s_def, :rb_io_s_new
      <<-END
        rb_define_method(rb_cClass, "new", rb_class_new_instance, -1);
        rb_define_singleton_method(rb_cProc, "new", proc_s_new, -1);
        rb_define_singleton_method(rb_cStruct, "new", rb_struct_s_def, -1);
        rb_define_singleton_method(rb_cIO, "new", rb_io_s_new, -1);
      END
    end
    
    def next
      $mc.add_function :rb_str_succ, :int_succ, :enumerator_next
      <<-END
        rb_define_method(rb_cString, "next", rb_str_succ, 0);
        rb_define_method(rb_cEnumerator, "next", enumerator_next, 0);
        rb_define_method(rb_cInteger, "next", int_succ, 0);
      END
    end
    
    def next!
      $mc.add_function :rb_str_succ_bang
      <<-END
        rb_define_method(rb_cString, "next!", rb_str_succ_bang, 0);
      END
    end
    
    def next_element
      $mc.add_function :elem_next_element
      <<-END
        rb_define_method(rb_cElement, "next_element", elem_next_element, 0);
      END
    end
    
    def next_elements
      $mc.add_function :elem_next_elements
      <<-END
        rb_define_method(rb_cElement, "next_elements", elem_next_elements, 0);
      END
    end
    
    def nil?
      $mc.add_function :rb_true
      <<-END
        rb_define_method(rb_mKernel, "nil?", rb_false, 0);
        rb_define_method(rb_cNilClass, "nil?", rb_true, 0);
      END
    end
    
    def nitems
      $mc.add_function :rby_ary_nitems
      <<-END
        rb_define_method(rb_cArray, "nitems", rb_ary_nitems, 0);
      END
    end
    
    def none?
      $mc.add_function :enum_none
      <<-END
        rb_define_method(rb_mEnumerable, "none?", enum_none, 0);
      END
    end
    
    def nonzero?
      $mc.add_function :num_nonzero_p
      <<-END
        rb_define_method(rb_cNumeric, "nonzero?", num_nonzero_p, 0);
      END
    end
    
    def object_id
      $mc.add_function :rb_obj_id
      <<-END
        rb_define_method(rb_mKernel, "object_id", rb_obj_id, 0);
      END
    end
    
    def oct
      $mc.add_function :rb_str_oct
      <<-END
        rb_define_method(rb_cString, "oct", rb_str_oct, 0);
      END
    end
    
    def odd?
      $mc.add_function :int_odd_p, :fix_odd_p
      <<-END
        rb_define_method(rb_cInteger, "odd?", int_odd_p, 0);
        rb_define_method(rb_cFixnum, "odd?", fix_odd_p, 0);
      END
    end
    
    def one?
      $mc.add_function :enum_one
      <<-END
        rb_define_method(rb_mEnumerable, "one?", enum_one, 0);
      END
    end
    
    def ord
      $mc.add_function :int_ord
      <<-END
        rb_define_method(rb_cInteger, "ord", int_ord, 0);
      END
    end
    
    def owner
      $mc.add_function :method_owner
      <<-END
        rb_define_method(rb_cUnboundMethod, "owner", method_owner, 0);
        rb_define_method(rb_cMethod, "owner", method_owner, 0);
      END
    end
    
    def pack
      $mc.add_function :pack_pack
      <<-END
        rb_define_method(rb_cArray, "pack", pack_pack, 1);
      END
    end
    
    def page
      $mc.add_function :event_page
      <<-END
        rb_define_method(rb_cEvent, "page", event_page, 0);
      END
    end
    
    def parent
      $mc.add_function :elem_parent
      <<-END
        rb_define_method(rb_cElement, "parent", elem_parent, 0);
      END
    end
    
    def parents
      $mc.add_function :elem_parents
      <<-END
        rb_define_method(rb_cElement, "parents", elem_parents, 0);
      END
    end
    
    def partition
      $mc.add_function :enum_partition, :rb_str_partition
      <<-END
        rb_define_method(rb_mEnumerable, "partition", enum_partition, 0);
        rb_define_method(rb_cString, "partition", rb_str_partition, -1);
      END
    end
    
    def permutation
      $mc.add_function :rb_ary_permutation
      <<-END
        rb_define_method(rb_cArray, "permutation", rb_ary_permutation, -1);
      END
    end
    
    def platform
      $mc.add_function :rb_define_module_function, :browser_platform
      <<-END
        rb_define_module_function(rb_mBrowser, "platform", browser_platform, 0);
      END
    end
    
    def prec
      $mc.add_function :prec_prec
      <<-END
        rb_define_method(rb_mPrecision, "prec", prec_prec, 1);
      END
    end
    
    def prec_f
      $mc.add_function :prec_prec_f
      <<-END
        rb_define_method(rb_mPrecision, "prec_f", prec_prec_f, 0);
      END
    end
    
    def prec_i
      $mc.add_function :prec_prec_i
      <<-END
        rb_define_method(rb_mPrecision, "prec_i", prec_prec_i, 0);
      END
    end
    
    def pop
      $mc.add_function :rb_ary_pop_m
      <<-END
        rb_define_method(rb_cArray, "pop", rb_ary_pop_m, -1);
      END
    end
    
    def pred
      $mc.add_function :int_pred
      <<-END
        rb_define_method(rb_cInteger, "pred", int_pred, 0);
      END
    end
    
    def presto?
      $mc.add_function :rb_f_presto_p, :rb_define_global_function
      <<-END
        rb_define_global_function("presto?", rb_f_presto_p, -1);
      END
    end
    
    def previous_element
      $mc.add_function :elem_previous_element
      <<-END
        rb_define_method(rb_cElement, "previous_element", elem_previous_element, 0);
      END
    end
    
    def previous_elements
      $mc.add_function :elem_previous_elements
      <<-END
        rb_define_method(rb_cElement, "previous_element", elem_previous_elements, 0);
      END
    end
    
    def prevent_default
      $mc.add_function :event_prevent_default
      <<-END
        rb_define_method(rb_cEvent, "prevent_default", event_prevent_default, 0);
      END
    end
    
    def private
      $mc.add_function :rb_mod_private, :rb_define_private_method
      <<-END
        rb_define_private_method(rb_cModule, "private", rb_mod_private, -1);
      END
    end
    
    def private_class_method
      $mc.add_function :rb_mod_private_method
      <<-END
        rb_define_method(rb_cModule, "private_class_method", rb_mod_private_method, -1);
      END
    end
    
    def private_instance_methods
      $mc.add_function :rb_class_private_instance_methods
      <<-END
        rb_define_method(rb_cModule, "private_instance_methods", rb_class_private_instance_methods, -1);
      END
    end
    
    def private_method_defined?
      $mc.add_function :rb_mod_private_method_defined
      <<-END
        rb_define_method(rb_cModule, "private_method_defined?", rb_mod_private_method_defined, 1);
      END
    end
    
    def private_methods
      $mc.add_function :rb_obj_private_methods
      <<-END
        rb_define_method(rb_mKernel, "private_methods", rb_obj_private_methods, -1);
      END
    end
    
    def proc
      $mc.add_functions :proc_lambda, :rb_define_global_function
      <<-END
        rb_define_global_function("proc", proc_lambda, 0);
      END
    end
    
    def product
      $mc.add_function :rb_ary_product
      <<-END
        rb_define_method(rb_cArray, "product", rb_ary_product, -1);
      END
    end
    
    def protected
      $mc.add_function :rb_mod_protected, :rb_define_private_method
      <<-END
        rb_define_private_method(rb_cModule, "protected", rb_mod_protected, -1);
      END
    end
    
    def protected_instance_methods
      $mc.add_function :rb_class_protected_instance_methods
      <<-END
        rb_define_method(rb_cModule, "protected_instance_methods", rb_class_protected_instance_methods, -1);
      END
    end
    
    def protected_method_defined?
      $mc.add_function :rb_mod_protected_method_defined
      <<-END
        rb_define_method(rb_cModule, "protected_method_defined?", rb_mod_protected_method_defined, 1);
      END
    end
    
    def protected_methods
      $mc.add_function :rb_obj_protected_methods
      <<-END
        rb_define_method(rb_mKernel, "protected_methods", rb_obj_protected_methods, -1);
      END
    end
    
    def public
      $mc.add_function :rb_mod_public, :rb_define_private_method
      <<-END
        rb_define_private_method(rb_cModule, "public", rb_mod_public, -1);
      END
    end
    
    def public_class_method
      $mc.add_function :rb_mod_public_method
      <<-END
        rb_define_method(rb_cModule, "public_class_method", rb_mod_public_method, -1);
      END
    end
    
    def public_instance_methods
      $mc.add_function :rb_class_public_instance_methods
      <<-END
        rb_define_method(rb_cModule, "public_instance_methods", rb_class_public_instance_methods, -1);
      END
    end
    
    def public_method_defined?
      $mc.add_function :rb_mod_public_method_defined
      <<-END
        rb_define_method(rb_cModule, "public_method_defined?", rb_mod_public_method_defined, 1);
      END
    end
    
    def public_methods
      $mc.add_function :rb_obj_public_methods
      <<-END
        rb_define_method(rb_mKernel, "public_methods", rb_obj_public_methods, -1);
      END
    end
    
    def push
      $mc.add_function :rb_ary_push_m
      <<-END
        rb_define_method(rb_cArray, "push", rb_ary_push_m, -1);
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
        rb_define_global_function("query?", rb_f_query_p, 0);
      END
    end
    
    def quo
      $mc.add_function :num_quo, :fix_quo
      <<-END
        rb_define_method(rb_cNumeric, "quo", num_quo, 1);
        rb_define_method(rb_cFixnum, "quo", fix_quo, 1);
      END
    end
    
    def rassoc
      $mc.add_function :rb_ary_rassoc
      <<-END
        rb_define_method(rb_cArray, "rassoc", rb_ary_rassoc, 1);
      END
    end
    
    def ready?
      $mc.add_function :doc_ready_p
      <<-END
        rb_define_module_function(rb_mDocument, "ready?", doc_ready_p, 0);
      END
    end
    
    def reason
      $mc.add_function :localjump_reason
      <<-END
        rb_define_method(rb_eLocalJumpError, "reason", localjump_reason, 0);
      END
    end
    
    def receiver
      $mc.add_function :method_receiver
      <<-END
        rb_define_method(rb_cMethod, "receiver", method_receiver, 0);
      END
    end
    
    def reduce
      $mc.add_function :enum_inject
      <<-END
        rb_define_method(rb_mEnumerable, "reduce", enum_inject, -1);
      END
    end
    
    def rehash
      $mc.add_function :rb_hash_rehash
      <<-END
        rb_define_method(rb_cHash,"rehash", rb_hash_rehash, 0);
      END
    end
    
    def reject
      $mc.add_function :enum_reject, :rb_hash_reject, :rb_ary_reject
      <<-END
        rb_define_method(rb_cArray, "reject", rb_ary_reject, 0);
        rb_define_method(rb_mEnumerable, "reject", enum_reject, 0);
        rb_define_method(rb_cHash,"reject", rb_hash_reject, 0);
      END
    end
    
    def reject!
      $mc.add_function :rb_hash_reject_bang, :rb_ary_reject_bang
      <<-END
        rb_define_method(rb_cHash,"reject!", rb_hash_reject_bang, 0);
        rb_define_method(rb_cArray, "reject!", rb_ary_reject_bang, 0);
      END
    end
    
    def related_target
      $mc.add_function :event_related_target
      <<-END
        rb_define_method(rb_cEvent, "related_target", event_related_target, 0);
      END
    end
    
    def remainder
      $mc.add_function :num_remainder
      <<-END
        rb_define_method(rb_cNumeric, "remainder", num_remainder, 1);
      END
    end
    
    def remove_class_variable
      $mc.add_function :rb_mod_remove_cvar, :rb_define_private_method
      <<-END
        rb_define_private_method(rb_cModule, "remove_class_variable", rb_mod_remove_cvar, 1);
      END
    end
    
    def remove_const
      $mc.add_function :rb_mod_remove_const, :rb_define_private_method
      <<-END
        rb_define_private_method(rb_cModule, "remove_const", rb_mod_remove_const, 1);
      END
    end
    
    def remove_instance_variable
      $mc.add_function :rb_obj_remove_instance_variable, :rb_define_private_method
      <<-END
        rb_define_private_method(rb_mKernel, "remove_instance_variable", rb_obj_remove_instance_variable, 1);
      END
    end
    
    def replace
      $mc.add_function :rb_hash_replace, :rb_str_replace, :rb_ary_replace
      <<-END
        rb_define_method(rb_cString, "replace", rb_str_replace, 1);
        rb_define_method(rb_cHash,"replace", rb_hash_replace, 1);
        rb_define_method(rb_cArray, "replace", rb_ary_replace, 1);
      END
    end
    
    def respond_to?
      <<-END
        console.log('missing respond_to?');
      END
    end
    
    def reverse
      $mc.add_function :rb_str_reverse, :rb_ary_reverse_m
      <<-END
        rb_define_method(rb_cArray, "reverse", rb_ary_reverse_m, 0);
        rb_define_method(rb_cString, "reverse", rb_str_reverse, 0);
      END
    end
    
    def reverse!
      $mc.add_function :rb_str_reverse_bang, :rb_ary_reverse_bang
      <<-END
        rb_define_method(rb_cString, "reverse!", rb_str_reverse_bang, 0);
        rb_define_method(rb_cArray, "reverse!", rb_ary_reverse_bang, 0);
      END
    end
    
    def reverse_each
      $mc.add_function :enum_reverse_each, :rb_ary_reverse_each
      <<-END
        rb_define_method(rb_mEnumerable, "reverse_each", enum_reverse_each, -1);
        rb_define_method(rb_cArray, "reverse_each", rb_ary_reverse_each, 0);
      END
    end
    
    def rewind
      $mc.add_function :enumerator_rewind
      <<-END
        rb_define_method(rb_cEnumerator, "rewind", enumerator_rewind, 0);
      END
    end
    
    def right_click?
      $mc.add_function :event_right_click
      <<-END
        rb_define_method(rb_cEvent, "right_click?", event_right_click, 0);
      END
    end
    
    def rindex
      $mc.add_function :rb_str_rindex_m, :rb_ary_index
      <<-END
        rb_define_method(rb_cString, "rindex", rb_str_rindex_m, -1);
        rb_define_method(rb_cArray, "rindex", rb_ary_rindex, -1);
      END
    end
    
    def rjust
      $mc.add_function :rb_str_rjust
      <<-END
        rb_define_method(rb_cString, "rjust", rb_str_rjust, -1);
      END
    end
    
    def round
      $mc.add_function :num_round, :int_to_i, :flo_round
      <<-END
        rb_define_method(rb_cNumeric, "round", num_round, 0);
        rb_define_method(rb_cFloat, "round", flo_round, 0);
        rb_define_method(rb_cInteger, "round", int_to_i, 0);
      END
    end
    
    def rpartition
      $mc.add_function :rb_str_rpartition
      <<-END
        rb_define_method(rb_cString, "rpartition", rb_str_rpartition, 1);
      END
    end
    
    def rstrip
      $mc.add_function :rb_rstrip
      <<-END
        rb_define_method(rb_cString, "rstrip", rb_str_rstrip, 0);
      END
    end
    
    def rstrip!
      $mc.add_function :rb_rstrip_bang
      <<-END
        rb_define_method(rb_cString, "rstrip!", rb_str_rstrip_bang, 0);
      END
    end
    
    def scan
      $mc.add_function :rb_str_scan, :rb_f_scan
      <<-END
        rb_define_method(rb_cString, "scan", rb_str_scan, 1);
        rb_define_global_function("scan", rb_f_scan, 1);
      END
    end
    
    def select
      $mc.add_function :enum_find_all, :rb_hash_select, :rb_ary_select, :rb_struct_select
      <<-END
        rb_define_method(rb_cStruct, "select", rb_struct_select, -1);
        rb_define_method(rb_mEnumerable, "select", enum_find_all, 0);
        rb_define_method(rb_cHash,"select", rb_hash_select, 0);
        rb_define_method(rb_cArray, "select", rb_ary_select, 0);
      END
    end
    
    def set_backtrace
      $mc.add_function :exc_set_backtrace
      <<-END
        rb_define_method(rb_eException, "set_backtrace", exc_set_backtrace, 1);
      END
    end
    
    def shift
      $mc.add_function :rb_hash_shift, :rb_ary_shift_m
      <<-END
        rb_define_method(rb_cHash,"shift", rb_hash_shift, 0);
        rb_define_method(rb_cArray, "shift", rb_ary_shift_m, -1);
      END
    end
    
    def shift?
      $mc.add_function :event_shift
      <<-END
        rb_define_method(rb_cEvent, "shift?", event_shift, 0);
      END
    end
    
    def shuffle
      $mc.add_function :rb_ary_shuffle
      <<-END
        rb_define_method(rb_cArray, "shuffle", rb_ary_shuffle, 0);
      END
    end
    
    def shuffle!
      $mc.add_function :rb_ary_shuffle_bang
      <<-END
        rb_define_method(rb_cArray, "shuffle!", rb_ary_shuffle_bang, 0);
      END
    end
    
    def singleton_method_added(*x)
      return unless $mc
      $mc.add_function :rb_obj_dummy, :rb_define_private_method, :num_sadded
      <<-END
        rb_define_private_method(rb_mKernel, "singleton_method_added", rb_obj_dummy, 1);
        rb_define_method(rb_cNumeric, "singleton_method_added", num_sadded, 1);
      END
    end
    
    def singleton_method_removed
      $mc.add_function :rb_obj_dummy, :rb_define_private_method
      <<-END
        rb_define_private_method(rb_mKernel, "singleton_method_removed", rb_obj_dummy, 1);
      END
    end
    
    def singleton_method_undefined
      $mc.add_function :rb_obj_dummy, :rb_define_private_method
      <<-END
        rb_define_private_method(rb_mKernel, "singleton_method_undefined", rb_obj_dummy, 1);
      END
    end
    
    def singleton_methods
      $mc.add_function :rb_obj_singleton_methods
      <<-END
        rb_define_method(rb_mKernel, "singleton_methods", rb_obj_singleton_methods, -1);
      END
    end
    
    def size
      $mc.add_function :rb_hash_size, :rb_str_length, :fix_size, :rb_struct_size
      $mc.add_method :rb_ary_length
      <<-END
        rb_define_method(rb_cStruct, "size", rb_struct_size, 0);
        rb_define_method(rb_cHash,"size", rb_hash_size, 0);
        rb_define_method(rb_cString, "size", rb_str_length, 0);
        rb_define_alias(rb_cArray,  "size", "length");
        rb_define_method(rb_cFixnum, "size", fix_size, 0);
      END
    end
    
    def slice
      $mc.add_function :rb_str_aref_m, :rb_ary_aref
      <<-END
        rb_define_method(rb_cString, "slice", rb_str_aref_m, -1);
        rb_define_method(rb_cArray, "slice", rb_ary_aref, -1);
      END
    end
    
    def slice!
      $mc.add_function :rb_str_slice_bang, :rb_ary_slice_bang
      <<-END
        rb_define_method(rb_cString, "slice!", rb_str_slice_bang, -1);
        rb_define_method(rb_cArray, "slice!", rb_ary_slice_bang, -1);
      END
    end
    
    def sort
      $mc.add_function :enum_sort, :rb_hash_sort, :rb_ary_sort
      <<-END
        rb_define_method(rb_mEnumerable, "sort", enum_sort, 0);
        rb_define_method(rb_cHash,"sort", rb_hash_sort, 0);  
        rb_define_method(rb_cArray, "sort", rb_ary_sort, 0);
      END
    end
    
    def sort!
      $mc.add_function :rb_ary_sort_bang
      <<-END
        rb_define_method(rb_cArray, "sort!", rb_ary_sort_bang, 0);
      END
    end
    
    def sort_by
      $mc.add_function :enum_sort_by
      <<-END
        rb_define_method(rb_mEnumerable, "sort_by", enum_sort_by, 0);
      END
    end
    
    def split
      $mc.add_function :rb_str_split_m, :rb_define_global_function
      <<-END
        rb_define_method(rb_cString, "split", rb_str_split_m, -1);
        rb_define_global_function("split", rb_f_split, -1);
      END
    end
    
    def sprintf
      $mc.add_function :rb_f_sprintf, :rb_define_global_function
      <<-END
        rb_define_global_function("sprintf", rb_f_sprintf, -1);
      END
    end
    
    def squeeze
      $mc.add_function :rb_str_squeeze
      <<-END
        rb_define_method(rb_cString, "squeeze", rb_str_squeeze, -1);
      END
    end
    
    def squeeze!
      $mc.add_function :rb_str_squeeze_bang
      <<-END
        rb_define_method(rb_cString, "squeeze!", rb_str_squeeze_bang, -1);
      END
    end
    
    def start_with?
      $mc.add_function :rb_str_start_with
      <<-END
        rb_define_method(rb_cString, "start_with?", rb_str_start_with, -1);
      END
    end
    
    def status
      $mc.add_function :exit_status
      <<-END
        rb_define_method(rb_eSystemExit, "status", exit_status, 0);
      END
    end
    
    def step
      $mc.add_function :range_step, :num_step
      <<-END
        rb_define_method(rb_cRange, "step", range_step, -1);
        rb_define_method(rb_cNumeric, "step", num_step, -1);
      END
    end
    
    def stop_propagation
      $mc.add_function :event_stop_propagation
      <<-END
        rb_define_method(rb_cEvent, "stop_propagation", event_stop_propagation, 0);
      END
    end
    
    def store
      $mc.add_function :rb_hash_aset
      <<-END
        rb_define_method(rb_cHash,"store", rb_hash_aset, 2);
      END
    end
    
    def String
      $mc.add_function :rb_f_string, :rb_define_global_function
      <<-END
        rb_define_global_function("String", rb_f_string, 1);
      END
    end
    
    def strip
      $mc.add_function :rb_str_strip
      <<-END
        rb_define_method(rb_cString, "strip", rb_str_strip, 0);
      END
    end
    
    def strip!
      $mc.add_function :rb_str_strip_bang
      <<-END
        rb_define_method(rb_cString, "strip!", rb_str_strip_bang, 0);
      END
    end
    
    def sub
      $mc.add_function :rb_str_sub, :rb_f_sub, :rb_define_global_function
      <<-END
        rb_define_method(rb_cString, "sub", rb_str_sub, -1);
        rb_define_global_function("sub", rb_f_sub, -1);
      END
    end
    
    def sub!
      $mc.add_function :rb_str_sub_bang, :rb_f_sub_bang,
                       :rb_define_global_function
      <<-END
        rb_define_method(rb_cString, "sub!", rb_str_sub_bang, -1);
        rb_define_global_function("sub!", rb_f_sub_bang, -1);
      END
    end
    
    def succ
      $mc.add_function :rb_str_succ, :int_succ
      <<-END
        rb_define_method(rb_cString, "succ", rb_str_succ, 0);
        rb_define_method(rb_cInteger, "succ", int_succ, 0);
      END
    end
    
    def succ!
      $mc.add_function :rb_str_succ_bang
      <<-END
        rb_define_method(rb_cString, "succ!", rb_str_succ_bang, 0);
      END
    end
    
    def success?
      $mc.add_function :exit_success_p
      <<-END
        rb_define_method(rb_eSystemExit, "success?", exit_success_p, 0);
      END
    end
    
    def sum
      $mc.add_function :rb_str_sum
      <<-END
        rb_define_method(rb_cString, "sum", rb_str_sum, -1);
      END
    end
    
    def superclass
      $mc.add_function :rb_class_superclass
      <<-END
        rb_define_method(rb_cClass, "superclass", rb_class_superclass, 0);
      END
    end
    
    def swapcase
      $mc.add_function :rb_str_swapcase
      <<-END
        rb_define_method(rb_cString, "swapcase", rb_str_swapcase, 0);
      END
    end
    
    def swapcase!
      $mc.add_function :rb_str_swapcase_bang
      <<-END
        rb_define_method(rb_cString, "swapcase!", rb_str_swapcase_bang, 0);
      END
    end
    
    def taint
      $mc.add_function :rb_obj_taint
      <<-END
        rb_define_method(rb_mKernel, "taint", rb_obj_taint, 0);
      END
    end
    
    def tainted?
      $mc.add_function :rb_obj_tainted
      <<-END
        rb_define_method(rb_mKernel, "tainted?", rb_obj_tainted, 0);
      END
    end
    
    def take
      $mc.add_function :enum_take, :rb_ary_take
      <<-END
        rb_define_method(rb_mEnumerable, "take", enum_take, 1);
        rb_define_method(rb_cArray, "take", rb_ary_take, 1);
      END
    end
    
    def take_while
      $mc.add_function :enum_take_while, :rb_ary_take_while
      <<-END
        rb_define_method(rb_mEnumerable, "take_while", enum_take_while, 0);
        rb_define_method(rb_cArray, "take_while", rb_ary_take_while, 0);
      END
    end
    
    def tap
      $mc.add_function :rb_obj_tap
      <<-END
        rb_define_method(rb_mKernel, "tap", rb_obj_tap, 0);
      END
    end
    
    def target
      $mc.add_function :event_target
      <<-END
        rb_define_method(rb_cEvent, "target", event_target, 0);
      END
    end
    
    def times
      $mc.add_function :int_dotimes
      <<-END
        rb_define_method(rb_cInteger, "times", int_dotimes, 0);
      END
    end
    
    def title
      $mc.add_function :doc_title
      <<-END
        rb_define_module_function(rb_mDocument, "title", doc_title, 0);
      END
    end
    
    def to_a
      $mc.add_function :nil_to_a, :enum_to_a, :rb_hash_to_a, :rb_ary_to_a,
                       :rb_struct_to_a
      <<-END
        rb_define_method(rb_cStruct, "to_a", rb_struct_to_a, 0);
        rb_define_method(rb_mEnumerable, "to_a", enum_to_a, -1);
        rb_define_method(rb_cHash,"to_a", rb_hash_to_a, 0);
        rb_define_method(rb_cNilClass, "to_a", nil_to_a, 0);
        rb_define_method(rb_cArray, "to_a", rb_ary_to_a, 0);
      END
    end
    
    def to_ary
      $mc.add_function :rb_ary_to_ary_m
      <<-END
        rb_define_method(rb_cArray, "to_ary", rb_ary_to_ary_m, 0);
      END
    end
    
    def to_enum
      $mc.add_function :obj_to_enum
      <<-END
        rb_define_method(rb_mKernel, "to_enum", obj_to_enum, -1);
      END
    end
    
    def to_f
      $mc.add_function :nil_to_f, :rb_str_to_f, :fix_to_f, :flo_to_f
      <<-END
        rb_define_method(rb_cNilClass, "to_f", nil_to_f, 0);
        rb_define_method(rb_cFixnum, "to_f", fix_to_f, 0);
        rb_define_method(rb_cFloat, "to_f", flo_to_f, 0);
        rb_define_method(rb_cString, "to_f", rb_str_to_f, 0);
      END
    end
    
    def to_hash
      $mc.add_function :rb_hash_to_hash
      <<-END
        rb_define_method(rb_cHash,"to_hash", rb_hash_to_hash, 0);
      END
    end
    
    def to_i
      $mc.add_function :nil_to_i, :sym_to_i, :rb_str_to_i, :int_to_i,
                       :flo_truncate
      <<-END
        rb_define_method(rb_cNilClass, "to_i", nil_to_i, 0);
        rb_define_method(rb_cFloat, "to_i", flo_truncate, 0);
        rb_define_method(rb_cInteger, "to_i", int_to_i, 0);
        rb_define_method(rb_cString, "to_i", rb_str_to_i, -1);
        rb_define_method(rb_cSymbol, "to_i", sym_to_i, 0);
      END
    end
    
    def to_int
      $mc.add_function :sym_to_int, :num_to_int, :int_to_i, :flo_truncate
      <<-END
        rb_define_method(rb_cSymbol, "to_int", sym_to_int, 0);
        rb_define_method(rb_cInteger, "to_int", int_to_i, 0);
        rb_define_method(rb_cFloat, "to_int", flo_truncate, 0);
        rb_define_method(rb_cNumeric, "to_int", num_to_int, 0);
      END
    end
    
    def to_proc
      $mc.add_function :sym_to_proc, :method_proc, :proc_to_self
      <<-END
        rb_define_method(rb_cSymbol, "to_proc", sym_to_proc, 0);
      //rb_define_method(rb_cMethod, "to_proc", method_proc, 0);
        rb_define_method(rb_cProc, "to_proc", proc_to_self, 0);
      END
    end
    
    def to_s
      $mc.add_functions :rb_ary_to_s, :exc_to_s, :false_to_s, :rb_hash_to_s,
                        :rb_mod_to_s, :nil_to_s, :fix_to_s, :rb_any_to_s,
                        :sym_to_s, :true_to_s, :method_inspect, :proc_to_s,
                        :range_to_s, :rb_str_to_s, :name_err_to_s, :flo_to_s,
                        :rb_struct_inspect, :elem_to_s
      <<-END
        rb_define_method(rb_cElement, "to_s", elem_to_s, 0);
        rb_define_method(rb_cArray, "to_s", rb_ary_to_s, 0);
        rb_define_method(rb_cStruct, "to_s", rb_struct_inspect, 0);
        rb_define_method(rb_eException, "to_s", exc_to_s, 0);
        rb_define_method(rb_cFloat, "to_s", flo_to_s, 0);
        rb_define_method(rb_cFalseClass, "to_s", false_to_s, 0);
        rb_define_method(rb_cHash,"to_s", rb_hash_to_s, 0);
        rb_define_method(rb_cMethod, "to_s", method_inspect, 0);
        rb_define_method(rb_cModule, "to_s", rb_mod_to_s, 0);
        rb_define_method(rb_cNilClass, "to_s", nil_to_s, 0);
        rb_define_method(rb_cFixnum, "to_s", fix_to_s, -1);
        rb_define_method(rb_mKernel, "to_s", rb_any_to_s, 0);
        rb_define_method(rb_cRange, "to_s", range_to_s, 0);
        rb_define_method(rb_cString, "to_s", rb_str_to_s, 0);
        rb_define_method(rb_cSymbol, "to_s", sym_to_s, 0);
        rb_define_method(rb_cTrueClass, "to_s", true_to_s, 0);
        rb_define_method(rb_cUnboundMethod, "to_s", method_inspect, 0);
        rb_define_method(rb_eNameError, "to_s", name_err_to_s, 0);
      END
    end
    
    def to_str
      $mc.add_function :rb_str_to_s, :name_err_mesg_to_str, :exc_to_str
      <<-END
        rb_define_method(rb_cString, "to_str", rb_str_to_s, 0);
        rb_define_method(rb_cNameErrorMesg, "to_str", name_err_mesg_to_str, 0);
        rb_define_method(rb_eException, "to_str", exc_to_str, 0);
      END
    end
    
    def to_sym
      $mc.add_function :sym_to_sym, :rb_str_intern, :fix_to_sym
      <<-END
        rb_define_method(rb_cSymbol, "to_sym", sym_to_sym, 0);
        rb_define_method(rb_cString, "to_sym", rb_str_intern, 0);
        rb_define_method(rb_cFixnum, "to_sym", fix_to_sym, 0);
      END
    end
    
    def tr
      $mc.add_function :rb_str_tr
      <<-END
        rb_define_method(rb_cString, "tr", rb_str_tr, 2);
      END
    end
    
    def tr!
      $mc.add_function :rb_str_tr_bang
      <<-END
        rb_define_method(rb_cString, "tr!", rb_str_tr_bang, 2);
      END
    end
    
    def tr_s
      $mc.add_function :rb_str_tr_s
      <<-END
        rb_define_method(rb_cString, "tr_s", rb_str_tr_s, 2);
      END
    end
    
    def tr_s!
      $mc.add_function :rb_str_t_s_bang
      <<-END
        rb_define_method(rb_cString, "tr_s!", rb_str_tr_s_bang, 2);
      END
    end
    
    def transpose
      $mc.add_function :rb_ary_transpose
      <<-END
        rb_define_method(rb_cArray, "transpose", rb_ary_transpose, 0);
      END
    end
    
    def trident?
      $mc.add_function :rb_f_trident_p, :rb_define_global_function
      <<-END
        rb_define_global_function("trident?", rb_f_trident_p, -1);
      END
    end
    
    def truncate
      $mc.add_function :num_truncate, :int_to_i, :flo_truncate
      <<-END
        rb_define_method(rb_cFloat, "truncate", flo_truncate, 0);
        rb_define_method(rb_cNumeric, "truncate", num_truncate, 0);
        rb_define_method(rb_cInteger, "truncate", int_to_i, 0);
      END
    end
    
    def unbind
      $mc.add_function :method_unbind
      <<-END
        rb_define_method(rb_cMethod, "unbind", method_unbind, 0);
      END
    end
    
    def uniq
      $mc.add_function :rb_ary_uniq
      <<-END
        rb_define_method(rb_cArray, "uniq", rb_ary_uniq, 0);
      END
    end
    
    def uniq!
      $mc.add_function :rb_ary_uniq_bang
      <<-END
        rb_define_method(rb_cArray, "uniq!", rb_ary_uniq_bang, 0);
      END
    end
    
    def unpack
      $mc.add_function :pack_unpack
      <<-END
        rb_define_method(rb_cString, "unpack", pack_unpack, 1);
      END
    end
    
    def unshift
      $mc.add_function :rb_ary_unshift_m
      <<-END
        rb_define_method(rb_cArray, "unshift", rb_ary_unshift_m, -1);
      END
    end
    
    def untaint
      $mc.add_function :rb_obj_untaint
      <<-END
        rb_define_method(rb_mKernel, "untaint", rb_obj_untaint, 0);
      END
    end
    
    def upcase
      $mc.add_function :rb_str_upcase
      <<-END
        rb_define_method(rb_cString, "upcase", rb_str_upcase, 0);
      END
    end
    
    def upcase!
      $mc.add_function :rb_str_upcase_bang
      <<-END
        rb_define_method(rb_cString, "upcase!", rb_str_upcase_bang, 0);
      END
    end
    
    def update
      $mc.add_function :rb_hash_update
      <<-END
        rb_define_method(rb_cHash,"update", rb_hash_update, 1);
      END
    end
    
    def upto
      $mc.add_function :rb_str_upto_m, :int_upto
      <<-END
        rb_define_method(rb_cString, "upto", rb_str_upto_m, -1);
        rb_define_method(rb_cInteger, "upto", int_upto, 1);
      END
    end
    
    def value
      $mc.add_function :rb_hash_has_value
      <<-END
        rb_define_method(rb_cHash,"value?", rb_hash_has_value, 1);
      END
    end
    
    def values
      $mc.add_function :rb_hash_values, :rb_struct_to_a
      <<-END
        rb_define_method(rb_cHash,"values", rb_hash_values, 0);
        rb_define_method(rb_cStruct, "values", rb_struct_to_a, 0);
      END
    end
    
    def values_at
      $mc.add_function :rb_hash_values_at, :rb_ary_values_at, :rb_struct_values_at
      <<-END
        rb_define_method(rb_cStruct, "values_at", rb_struct_values_at, -1);
        rb_define_method(rb_cHash,"values_at", rb_hash_values_at, -1);
        rb_define_method(rb_cArray, "values_at", rb_ary_values_at, -1);
      END
    end
    
    def warn
      $mc.add_function :rb_warn_m
      <<-END
        rb_define_global_function("warn", rb_warn_m, 1);
      END
    end
    
    def webkit?
      $mc.add_function :rb_f_webkit_p, :rb_define_global_function
      <<-END
        rb_define_global_function("webkit?", rb_f_webkit_p, -1);
      END
    end
    
    def wheel
      $mc.add_function :event_wheel
      <<-END
        rb_define_method(rb_cEvent, "wheel", event_wheel, 0);
      END
    end
    
    def window
      $mc.add_function :doc_window, :rb_define_module_function
      <<-END
        rb_define_module_function(rb_mDocument, "window", doc_window, 0);
      END
    end
    
    def with_index
      $mc.add_function :enumerator_with_index
      <<-END
        rb_define_method(rb_cEnumerator, "with_index", enumerator_with_index, 0);
      END
    end
    
    def write
      $mc.add_function :io_write
      <<-END
        rb_define_method(rb_cIO, "write", io_write, 1);
      END
    end
    
    def xpath?
      $mc.add_function :rb_define_global_function, :rb_f_xpath_p
      <<-END
        rb_define_global_function("xpath?", rb_f_xpath_p, 0);
      END
    end
    
    def zero?
      $mc.add_function :num_zero_p, :fix_zero_p, :flo_zero_p
      <<-END
        rb_define_method(rb_cNumeric, "zero?", num_zero_p, 0);
        rb_define_method(rb_cFixnum, "zero?", fix_zero_p, 0);
        rb_define_method(rb_cFloat, "zero?", flo_zero_p, 0);
      END
    end
    
    def zip
      $mc.add_function :enum_zip, :rb_ary_zip
      <<-END
        rb_define_method(rb_mEnumerable, "zip", enum_zip, -1);
        rb_define_method(rb_cArray, "zip", rb_ary_zip, -1);
      END
    end
  end
  
  module Array
    # CHECK
    def ary_alloc
      <<-END
        function ary_alloc(klass) {
          var ary = NEWOBJ();
          OBJSETUP(ary, klass, T_ARRAY);
          ary.ptr = [];
          return ary;
        }
      END
    end
    
    # CHECK
    def inspect_ary
      add_function :rb_inspect, :rb_str_cat, :rb_str_append
      <<-END
        function inspect_ary(ary) {
          var str = rb_str_new("[");
          for (var i = 0, l = ary.ptr.length; i < l; ++i) {
            s = rb_inspect(ary.ptr[i]);
            if (i > 0) { rb_str_cat(str, ", "); }
            rb_str_append(str, s);
          }
          rb_str_cat(str, "]");
          return str;
        }
      END
    end
    
    # verbatim
    def inspect_call
      <<-END
        function inspect_call(arg) {
          return (arg.func)(arg.arg1, arg.arg2);
        }
      END
    end
    
    # verbatim
    def inspect_ensure
      add_function :rb_ary_pop, :get_inspect_tbl
      <<-END
        function inspect_ensure(obj) {
          var inspect_tbl = get_inspect_tbl(Qfalse);
          if (!NIL_P(inspect_tbl)) { rb_ary_pop(inspect_tbl); }
          return 0;
        }
      END
    end
    
    # CHECK
    def rb_Array
      add_function :rb_check_array_type, :rb_intern, :search_method, :rb_raise, :rb_funcall, :rb_ary_new3
      add_method :to_a
      <<-END
        function rb_Array(val) {
          var tmp = rb_check_array_type(val);
          if (NIL_P(tmp)) {
            var id = rb_intern('to_a');
            var m = search_method(CLASS_OF(val), id);
            var body = m[0];
            var origin = m[1];
            if (body && origin.m_tbl != rb_mKernel.m_tbl) {
              val = rb_funcall(val, id, 0);
              if (TYPE(val) != T_ARRAY) { rb_raise(rb_eTypeError, "'to_a' did not return Array"); }
              return val;
            } else {
              return rb_ary_new3(1, val);
            }
          }
          return tmp;
        }
      END
    end
    
    # EMPTY
    def rb_ary_equal
      <<-END
        function rb_ary_equal() {}
      END
    end
    
    # verbatim
    def rb_ary_includes
      add_function :rb_equal
      <<-END
        function rb_ary_includes(ary, item) {
          for (var i = 0, p = ary.ptr, l = p.length; i < l; ++i) {
            if (rb_equal(p[i], item)) { return Qtrue; }
          }
          return Qfalse;
        }
      END
    end
    
    # removed capacity handler and multiple warnings, NEED TO CHECK HOW MEMFILL WORKS
    def rb_ary_initialize
      add_function :rb_scan_args, :rb_check_array_type, :rb_ary_replace, :rb_raise, :rb_block_given_p, :rb_ary_store, :rb_yield, :memfill
      <<-END
        function rb_ary_initialize(argc, argv, ary) {
          var len;
        //rb_ary_modify(ary);
          var tmp = rb_scan_args(argc, argv, "02");
          var size = tmp[1];
          var val = tmp[2];
          if (tmp[0] === 0) { return ary; } // removed "RARRAY(ary)->len = 0" and warning
          if ((argc == 1) && !FIXNUM_P(size)) {
            val = rb_check_array_type(size);
            if (!NIL_P(val)) {
              rb_ary_replace(ary, val);
              return ary;
            }
          }
          len = NUM2LONG(size);
          if (len < 0) { rb_raise(rb_eArgError, "negative array size"); }
          if (len > ARY_MAX_SIZE) { rb_raise(rb_eArgError, "array size too big"); }
          // removed capacity handler
          if (rb_block_given_p()) {
            // removed warning
            for (var i = 0; i < len; i++) {
              rb_ary_store(ary, i, rb_yield(LONG2NUM(i)));
            // removed "RARRAY(ary)->len = i + 1"
            }
          } else {
            console.log('find out how memfill works in rb_ary_initialize');
            memfill(ary.ptr, len, val);
            // removed "RARRAY(ary)->len = len"
          }
          return ary;
        }
      END
    end
    
    # CHECK
    def rb_ary_inspect
      add_function :rb_str_new, :rb_inspecting_p, :rb_protect_inspect
      <<-END
        function rb_ary_inspect(ary) {
          if (!ary.ptr.length) { return rb_str_new("[]"); }
          if (rb_inspecting_p(ary)) { rb_str_new("[...]"); }
          return rb_protect_inspect(inspect_ary, ary, 0);
        }
      END
    end
    
    # CHECK
    def rb_ary_new
      add_function :ary_alloc
      <<-END
        function rb_ary_new() {
          return ary_alloc(rb_cArray);
        }
      END
    end
    
    # CHECK
    def rb_ary_push
      <<-END
        function rb_ary_push(ary, item) {
          ary.ptr.push(item); // was rb_ary_store(ary, RARRAY(ary)->len, item);
          return ary;
        }
      END
    end
    
    # EMPTY
    def rb_ary_replace
      <<-END
        function rb_ary_replace() {}
      END
    end
    
    # changed rb_ary_new2 to rb_ary_new
    def rb_ary_to_a
      add_function :rb_obj_class, :rb_ary_new, :rb_ary_replace
      <<-END
        function rb_ary_to_a(ary) {
          if (rb_obj_class(ary) != rb_cArray) {
            var dup = rb_ary_new();
            rb_ary_replace(dup, ary);
            return dup;
          }
          return ary;
        }
      END
    end
    
    # verbatim
    def rb_ary_to_s
      add_function :rb_str_new, :rb_ary_join
      <<-END
        function rb_ary_to_s(ary) {
          if (ary.ptr.length === 0) { return rb_str_new(0); }
          return rb_ary_join(ary, rb_output_fs);
        }
      END
    end
    
    # CHECK
    def rb_check_array_type
      add_function :rb_check_convert_type
      <<-END
        function rb_check_array_type(ary) {
          return rb_check_convert_type(ary, T_ARRAY, "Array", "to_ary");
        }
      END
    end
    
    # verbatim
    def rb_inspecting_p
      add_function :get_inspect_tbl, :rb_ary_includes, :rb_obj_id
      <<-END
        function rb_inspecting_p(obj) {
          var inspect_tbl = get_inspect_tbl(Qfalse);
          if (NIL_P(inspect_tbl)) { return Qfalse; }
          return rb_ary_includes(inspect_tbl, rb_obj_id(obj));
        }
      END
    end
    
    # CHECK
    def rb_protect_inspect
      add_function :rb_ary_new, :rb_obj_id, :rb_ary_includes, :rb_ary_push, :rb_ensure, :inspect_call, :inspect_ensure
      <<-END
        function rb_protect_inspect(func, obj, arg) {
          var iarg = {};
          var inspect_tbl = rb_ary_new(); // get_inspect_tbl(Qtrue);
          var id = rb_obj_id(obj);
          return func(obj, arg);
          if (rb_ary_includes(inspect_tbl, id)) { return func(obj, arg); }
          rb_ary_push(inspect_tbl, id);
          var iarg = { func: func, arg1: obj, arg2: arg };
          return rb_ensure(inspect_call, iarg, inspect_ensure, obj); // &iarg
        }
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
    
    # verbatim
    def Init_Array
      $mc.add_function :rb_define_class, :rb_include_module,
                       :rb_define_alloc_func
      <<-END
        function Init_Array() {
          rb_cArray = rb_define_class("Array", rb_cObject);
          rb_include_module(rb_cArray, rb_mEnumerable);
          rb_define_alloc_func(rb_cArray, ary_alloc);
        }
      END
    end
    
    # verbatim
    def Init_Binding
      add_function :rb_define_class, :rb_undef_alloc_func, :rb_undef_method
      <<-END
        function Init_Binding() {
          rb_cBinding = rb_define_class("Binding", rb_cObject);
          rb_undef_alloc_func(rb_cBinding);
          rb_undef_method(CLASS_OF(rb_cBinding), "new");
        }
      END
    end
    
    # pulled verbatim from Init_Object
    def Init_boot
      add_function :boot_defclass, :rb_make_metaclass, :rb_define_private_method
      <<-END
        function Init_boot() {
          var metaclass;
          rb_cObject = boot_defclass("Object", 0);
          rb_cModule = boot_defclass("Module", rb_cObject);
          rb_cClass  = boot_defclass("Class",  rb_cModule);
          metaclass = rb_make_metaclass(rb_cObject, rb_cClass);
          metaclass = rb_make_metaclass(rb_cModule, metaclass);
          metaclass = rb_make_metaclass(rb_cClass, metaclass);
          rb_define_private_method(rb_cClass, "inherited", rb_obj_dummy, 1);
        }
      END
    end
    
    # 
    def Init_Browser
      add_function :rb_define_module, :rb_init_engine
      <<-END
        function Init_Browser() {
          rb_mBrowser = rb_define_module("Browser");
          ruby_air   = (window.runtime) ? Qtrue : Qfalse;
          ruby_platform = rb_str_new((typeof(window.orientation) == "undefined") ? (navigator.platform.match(/mac|win|linux/i) || ['other'])[0].toLowerCase() : 'ipod');
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
          rb_undef_method(rb_cClass, "extend_object");
          rb_undef_method(rb_cClass, "append_features");
        }
      END
    end
    
    # CHECK
    def Init_Comparable
      add_function :rb_define_module
      <<-END
        function Init_Comparable() {
          rb_mComparable = rb_define_module("Comparable");
        }
      END
    end
    
    # verbatim
    def Init_Data
      add_function :rb_define_class, :rb_undef_alloc_func
      <<-END
        function Init_Data() {
          rb_cData = rb_define_class("Data", rb_cObject);
          rb_undef_alloc_func(rb_cData);
        }
      END
    end
    
    # 
    def Init_Document
      add_function :rb_define_module, :Init_sizzle
      <<-END
        function Init_Document() {
          rb_mDocument = rb_define_module("Document");
          document.head = document.getElementsByTagName('head')[0];
          document.html = document.getElementsByTagName('html')[0];
          document.window = document.defaultView || document.parentWindow;
          Sizzle = Init_sizzle();
        }
      END
    end
    
    # need to move method defs to class << Ruby
    def Init_Element
      add_function :rb_define_class, :rb_include_module
      <<-END
        function Init_Element() {
          rb_cElement = rb_define_class("Element", rb_cObject);
          rb_include_module(rb_cElement, rb_mUserEvent);
        }
      END
    end
    
    # verbatim
    def Init_Enumerable
      add_function :rb_define_module
      <<-END
        function Init_Enumerable() {
          rb_mEnumerable = rb_define_module("Enumerable");
        }
      END
    end
    
    # removed "rb_provide('enumerator.so')"
    def Init_Enumerator
      add_function :rb_define_class_under, :rb_include_module, :rb_define_alloc_func, :rb_define_class, :rb_intern, :enumerator_allocate
      <<-END
        function Init_Enumerator() {
          rb_cEnumerator = rb_define_class_under(rb_mEnumerable, "Enumerator", rb_cObject);
          rb_include_module(rb_cEnumerator, rb_mEnumerable);
          rb_define_alloc_func(rb_cEnumerator, enumerator_allocate);
          rb_eStopIteration = rb_define_class("StopIteration", rb_eIndexError);
          sym_each = ID2SYM(rb_intern("each"));
        }
      END
    end
    
    # CHECK
    def Init_eval
      add_function :rb_define_global_function, :rb_method_node, :rb_f_raise
      <<-END
        function Init_eval() {
        //rb_global_variable((void *)&top_scope);
        //rb_global_variable((void *)&ruby_eval_tree_begin);

        //rb_global_variable((void *)&ruby_eval_tree);
        //rb_global_variable((void *)&ruby_dyna_vars);

        //rb_define_virtual_variable("$@", errat_getter, errat_setter);
        //rb_define_hooked_variable("$!", &ruby_errinfo, 0, errinfo_setter);

        //rb_define_global_function("eval", rb_f_eval, -1);
        //rb_define_global_function("iterator?", rb_f_block_given_p, 0);
        //rb_define_global_function("block_given?", rb_f_block_given_p, 0);
        //rb_define_global_function("loop", rb_f_loop, 0);

        //rb_define_method(rb_mKernel, "respond_to?", obj_respond_to, -1);
        //rb_global_variable((void *)&basic_respond_to);
          basic_respond_to = rb_method_node(rb_cObject, respond_to);

          rb_define_global_function("raise", rb_f_raise, -1);
          rb_define_global_function("fail", rb_f_raise, -1);

        //rb_define_global_function("caller", rb_f_caller, -1);

        //rb_define_global_function("exit", rb_f_exit, -1);
        //rb_define_global_function("abort", rb_f_abort, -1);

        //rb_define_global_function("at_exit", rb_f_at_exit, 0);

        //rb_define_global_function("catch", rb_f_catch, 1);
        //rb_define_global_function("throw", rb_f_throw, -1);
        //rb_define_global_function("global_variables", rb_f_global_variables, 0); /* in variable.c */
        //rb_define_global_function("local_variables", rb_f_local_variables, 0);

        //rb_define_global_function("__method__", rb_f_method_name, 0);

        //rb_define_method(rb_mKernel, "send", rb_f_send, -1);
        //rb_define_method(rb_mKernel, "__send__", rb_f_send, -1);
        //rb_define_method(rb_mKernel, "instance_eval", rb_obj_instance_eval, -1);
        //rb_define_method(rb_mKernel, "instance_exec", rb_obj_instance_exec, -1);

        //rb_undef_method(rb_cClass, "module_function");

        //rb_define_private_method(rb_cModule, "remove_method", rb_mod_remove_method, -1);
        //rb_define_private_method(rb_cModule, "undef_method", rb_mod_undef_method, -1);
        //rb_define_private_method(rb_cModule, "alias_method", rb_mod_alias_method, 2);
        //rb_define_private_method(rb_cModule, "define_method", rb_mod_define_method, -1);

        //rb_define_singleton_method(rb_cModule, "nesting", rb_mod_nesting, 0);
        //rb_define_singleton_method(rb_cModule, "constants", rb_mod_s_constants, 0);

        //rb_define_singleton_method(ruby_top_self, "include", top_include, -1);
        //rb_define_singleton_method(ruby_top_self, "public", top_public, -1);
        //rb_define_singleton_method(ruby_top_self, "private", top_private, -1);

        //rb_define_method(rb_mKernel, "extend", rb_obj_extend, -1);

        //rb_define_global_function("trace_var", rb_f_trace_var, -1); /* in variable.c */
        //rb_define_global_function("untrace_var", rb_f_untrace_var, -1); /* in variable.c */

        //rb_define_global_function("set_trace_func", set_trace_func, 1);
        //rb_global_variable(&trace_func);

        //rb_define_virtual_variable("$SAFE", safe_getter, safe_setter);
        }
      END
    end
    
    # 
    def Init_Event
      <<-END
        function Init_Event() {
          rb_cEvent = rb_define_class("Event", rb_cObject);
          rb_undef_method(CLASS_OF(rb_cEvent), "new");
          sym_x = ID2SYM(rb_intern("x"));
          sym_y = ID2SYM(rb_intern("y"));
        }
      END
    end
    
    # verbatim
    def Init_Exception
      $mc.add_function :rb_define_class, :rb_define_module
      <<-END
        function Init_Exception() {
          rb_eException = rb_define_class("Exception", rb_cObject);
          rb_eSystemExit  = rb_define_class("SystemExit", rb_eException);
          rb_eFatal       = rb_define_class("fatal", rb_eException);
          rb_eSignal      = rb_define_class("SignalException", rb_eException);
          rb_eInterrupt   = rb_define_class("Interrupt", rb_eSignal);
          rb_eStandardError = rb_define_class("StandardError", rb_eException);
          rb_eTypeError     = rb_define_class("TypeError", rb_eStandardError);
          rb_eArgError      = rb_define_class("ArgumentError", rb_eStandardError);
          rb_eIndexError    = rb_define_class("IndexError", rb_eStandardError);
          rb_eRangeError    = rb_define_class("RangeError", rb_eStandardError);
          rb_eNameError     = rb_define_class("NameError", rb_eStandardError);
          rb_cNameErrorMesg = rb_define_class_under(rb_eNameError, "message", rb_cData);
          rb_eNoMethodError = rb_define_class("NoMethodError", rb_eNameError);
          rb_eScriptError = rb_define_class("ScriptError", rb_eException);
          rb_eSyntaxError = rb_define_class("SyntaxError", rb_eScriptError);
          rb_eLoadError   = rb_define_class("LoadError", rb_eScriptError);
          rb_eNotImpError = rb_define_class("NotImplementedError", rb_eScriptError);
          rb_eRuntimeError = rb_define_class("RuntimeError", rb_eStandardError);
          rb_eSecurityError = rb_define_class("SecurityError", rb_eStandardError);
          rb_eNoMemError = rb_define_class("NoMemoryError", rb_eException);
          syserr_tbl = {}; // was st_init_numtable
          rb_eSystemCallError = rb_define_class("SystemCallError", rb_eStandardError);
          rb_mErrno = rb_define_module("Errno");
        }
      END
    end
    
    # pulled from Init_Object
    def Init_FalseClass
      add_function :rb_define_class, :rb_undef_alloc_func, :rb_undef_method, :rb_define_global_const
      <<-END
        function Init_FalseClass() {
          rb_cFalseClass = rb_define_class("FalseClass", rb_cObject);
          rb_undef_alloc_func(rb_cFalseClass);
          rb_undef_method(CLASS_OF(rb_cFalseClass), "new");
          rb_define_global_const("FALSE", Qfalse);
        }
      END
    end
    
    # CHECK
    def Init_Hash
      add_function :rb_define_class, :rb_include_module,
                   :rb_define_alloc_func, :rb_hash_s_new,
                   :rb_define_global_const, :hash_alloc
      <<-END
        function Init_Hash() {
          rb_cHash = rb_define_class("Hash", rb_cObject);
          rb_include_module(rb_cHash, rb_mEnumerable);
          rb_define_alloc_func(rb_cHash, hash_alloc);
        //envtbl = rb_hash_s_new(0, NULL, rb_cHash);
        //rb_define_global_const("ENV", envtbl);
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
          
          missing    = rb_intern("method_missing");
          respond_to = rb_intern("respond_to?");
          init       = rb_intern("initialize");
          bt         = rb_intern("backtrace");
          
          id_coerce    = rb_intern("coerce");
          id_to_s      = rb_intern("to_s");
          id_to_i      = rb_intern("to_i");
          id_eq        = rb_intern("==");
          id_eql       = rb_intern("eql?");
          id_eqq       = rb_intern("===");
          id_inspect   = rb_intern("inspect");
          id_init_copy = rb_intern("initialize_copy");
          id_hash      = rb_intern("hash");
          id_call      = rb_intern("call");
          id_default   = rb_intern("default");
          id_write     = rb_intern("write");
          id_read      = rb_intern("read");
          id_getc      = rb_intern("getc");
          id_top       = rb_intern("top");
          id_bottom    = rb_intern("bottom");
          id_inside    = rb_intern("inside");
          id_after     = rb_intern("after");
          id_before    = rb_intern("before");
          
          each  = rb_intern("each");
          eqq   = rb_intern("===");
          aref  = rb_intern("[]");
          aset  = rb_intern("[]=");
          match = rb_intern("=~");
          cmp   = rb_intern("<=>");
          
          prc_pr = rb_intern("prec");
          prc_if = rb_intern("induced_from");
          
          id_cmp  = rb_intern("<=>");
          id_each = rb_intern("each");
          id_succ = rb_intern("succ");
          id_beg  = rb_intern("begin");
          id_end  = rb_intern("end");
          id_excl = rb_intern("excl");
          id_size = rb_intern("size");
          
          added               = rb_intern("method_added");
          singleton_added     = rb_intern("singleton_method_added");
          removed             = rb_intern("method_removed");
          singleton_removed   = rb_intern("singleton_method_removed");
          undefined           = rb_intern("method_undefined");
          singleton_undefined = rb_intern("singleton_method_undefined");
          
          __id__   = rb_intern("__id__");
          __send__ = rb_intern("__send__");
        }
      END
    end
    
    # need to decide which methods to implement and which to scrap
    def Init_IO
      add_function :rb_define_class, :rb_define_global_const, :rb_include_module, :rb_f_puts, :io_alloc, :rb_io_s_new, :rb_io_initialize, :rb_str_new, :rb_io_puts, :prep_stdio
      <<-END
        function Init_IO() {
          CONSOLE_LOG_BUFFER = '';
          
          rb_eIOError = rb_define_class("IOError", rb_eStandardError);
          rb_eEOFError = rb_define_class("EOFError", rb_eIOError);
          
        //rb_define_global_function("syscall", rb_f_syscall, -1);
        
        //rb_define_global_function("open", rb_f_open, -1);
        //rb_define_global_function("printf", rb_f_printf, -1);
        //rb_define_global_function("print", rb_f_print, -1);
        //rb_define_global_function("putc", rb_f_putc, 1);
          rb_define_global_function("puts", rb_f_puts, -1);
        //rb_define_global_function("gets", rb_f_gets, -1);
        //rb_define_global_function("readline", rb_f_readline, -1);
        //rb_define_global_function("getc", rb_f_getc, 0);
        //rb_define_global_function("select", rb_f_select, -1);
        
        //rb_define_global_function("readlines", rb_f_readlines, -1);
        
        //rb_define_global_function("`", rb_f_backquote, 1);
        
        //rb_define_global_function("p", rb_f_p, -1);
        //rb_define_method(rb_mKernel, "display", rb_obj_display, -1);
        
          rb_cIO = rb_define_class("IO", rb_cObject);
          rb_include_module(rb_cIO, rb_mEnumerable);
          
          rb_define_alloc_func(rb_cIO, io_alloc);
        //rb_define_singleton_method(rb_cIO, "open",  rb_io_s_open, -1);
        //rb_define_singleton_method(rb_cIO, "sysopen",  rb_io_s_sysopen, -1);
        //rb_define_singleton_method(rb_cIO, "for_fd", rb_io_s_for_fd, -1);
        //rb_define_singleton_method(rb_cIO, "popen", rb_io_s_popen, -1);
        //rb_define_singleton_method(rb_cIO, "foreach", rb_io_s_foreach, -1);
        //rb_define_singleton_method(rb_cIO, "readlines", rb_io_s_readlines, -1);
        //rb_define_singleton_method(rb_cIO, "read", rb_io_s_read, -1);
        //rb_define_singleton_method(rb_cIO, "select", rb_f_select, -1);
        //rb_define_singleton_method(rb_cIO, "pipe", rb_io_s_pipe, 0);
        
          rb_define_method(rb_cIO, "initialize", rb_io_initialize, -1);
          
        //rb_output_fs = Qnil;
        //rb_define_hooked_variable("$,", &rb_output_fs, 0, rb_str_setter);
        
        //rb_global_variable(&rb_default_rs);
          rb_rs = rb_default_rs = rb_str_new("\\n");
        //rb_output_rs = Qnil;
        //OBJ_FREEZE(rb_default_rs);	/* avoid modifying RS_default */
        //rb_define_hooked_variable("$/", &rb_rs, 0, rb_str_setter);
        //rb_define_hooked_variable("$-0", &rb_rs, 0, rb_str_setter);
        //rb_define_hooked_variable("$\\", &rb_output_rs, 0, rb_str_setter);
        
        //rb_define_hooked_variable("$.", &lineno, 0, lineno_setter);
        //rb_define_virtual_variable("$_", rb_lastline_get, rb_lastline_set);
        
        //rb_define_method(rb_cIO, "initialize_copy", rb_io_init_copy, 1);
        //rb_define_method(rb_cIO, "reopen", rb_io_reopen, -1);
        
        //rb_define_method(rb_cIO, "print", rb_io_print, -1);
        //rb_define_method(rb_cIO, "putc", rb_io_putc, 1);
          rb_define_method(rb_cIO, "puts", rb_io_puts, -1);
        //rb_define_method(rb_cIO, "printf", rb_io_printf, -1);
        
        //rb_define_method(rb_cIO, "each",  rb_io_each_line, -1);
        //rb_define_method(rb_cIO, "each_line",  rb_io_each_line, -1);
        //rb_define_method(rb_cIO, "each_byte",  rb_io_each_byte, 0);
        //rb_define_method(rb_cIO, "each_char",  rb_io_each_char, 0);
        //rb_define_method(rb_cIO, "lines",  rb_io_lines, -1);
        //rb_define_method(rb_cIO, "bytes",  rb_io_bytes, 0);
        //rb_define_method(rb_cIO, "chars",  rb_io_each_char, 0);
        
        //rb_define_method(rb_cIO, "syswrite", rb_io_syswrite, 1);
        //rb_define_method(rb_cIO, "sysread",  rb_io_sysread, -1);
        
        //rb_define_method(rb_cIO, "fileno", rb_io_fileno, 0);
        //rb_define_alias(rb_cIO, "to_i", "fileno");
        //rb_define_method(rb_cIO, "to_io", rb_io_to_io, 0);
        
        //rb_define_method(rb_cIO, "fsync",   rb_io_fsync, 0);
        //rb_define_method(rb_cIO, "sync",   rb_io_sync, 0);
        //rb_define_method(rb_cIO, "sync=",  rb_io_set_sync, 1);
        
        //rb_define_method(rb_cIO, "lineno",   rb_io_lineno, 0);
        //rb_define_method(rb_cIO, "lineno=",  rb_io_set_lineno, 1);
        
        //rb_define_method(rb_cIO, "readlines",  rb_io_readlines, -1);
        
        //rb_define_method(rb_cIO, "read_nonblock",  io_read_nonblock, -1);
        //rb_define_method(rb_cIO, "write_nonblock", rb_io_write_nonblock, 1);
        //rb_define_method(rb_cIO, "readpartial",  io_readpartial, -1);
        //rb_define_method(rb_cIO, "read",  io_read, -1);
        //rb_define_method(rb_cIO, "gets",  rb_io_gets_m, -1);
        //rb_define_method(rb_cIO, "readline",  rb_io_readline, -1);
        //rb_define_method(rb_cIO, "getc",  rb_io_getc, 0);
        //rb_define_method(rb_cIO, "getbyte",  rb_io_getc, 0);
        //rb_define_method(rb_cIO, "readchar",  rb_io_readchar, 0);
        //rb_define_method(rb_cIO, "readbyte",  rb_io_readchar, 0);
        //rb_define_method(rb_cIO, "ungetc",rb_io_ungetc, 1);
        //rb_define_method(rb_cIO, "<<",    rb_io_addstr, 1);
        //rb_define_method(rb_cIO, "flush", rb_io_flush, 0);
        //rb_define_method(rb_cIO, "tell", rb_io_tell, 0);
        //rb_define_method(rb_cIO, "seek", rb_io_seek_m, -1);
        //rb_define_const(rb_cIO, "SEEK_SET", INT2FIX(SEEK_SET));
        //rb_define_const(rb_cIO, "SEEK_CUR", INT2FIX(SEEK_CUR));
        //rb_define_const(rb_cIO, "SEEK_END", INT2FIX(SEEK_END));
        //rb_define_method(rb_cIO, "rewind", rb_io_rewind, 0);
        //rb_define_method(rb_cIO, "pos", rb_io_tell, 0);
        //rb_define_method(rb_cIO, "pos=", rb_io_set_pos, 1);
        //rb_define_method(rb_cIO, "eof", rb_io_eof, 0);
        //rb_define_method(rb_cIO, "eof?", rb_io_eof, 0);
        
        //rb_define_method(rb_cIO, "close", rb_io_close_m, 0);
        //rb_define_method(rb_cIO, "closed?", rb_io_closed, 0);
        //rb_define_method(rb_cIO, "close_read", rb_io_close_read, 0);
        //rb_define_method(rb_cIO, "close_write", rb_io_close_write, 0);
        
        //rb_define_method(rb_cIO, "isatty", rb_io_isatty, 0);
        //rb_define_method(rb_cIO, "tty?", rb_io_isatty, 0);
        //rb_define_method(rb_cIO, "binmode",  rb_io_binmode, 0);
        //rb_define_method(rb_cIO, "sysseek", rb_io_sysseek, -1);
        
        //rb_define_method(rb_cIO, "ioctl", rb_io_ioctl, -1);
        //rb_define_method(rb_cIO, "fcntl", rb_io_fcntl, -1);
        //rb_define_method(rb_cIO, "pid", rb_io_pid, 0);
        //rb_define_method(rb_cIO, "inspect",  rb_io_inspect, 0);
        
        //rb_define_variable("$stdin", &rb_stdin);
        //rb_stdin = prep_stdio(stdin, FMODE_READABLE, rb_cIO);
        //rb_define_hooked_variable("$stdout", &rb_stdout, 0, stdout_setter);
          rb_stdout = prep_stdio(console, 0, rb_cIO);
        //rb_define_hooked_variable("$stderr", &rb_stderr, 0, stdout_setter);
        //rb_stderr = prep_stdio(stderr, FMODE_WRITABLE, rb_cIO);
        //rb_define_hooked_variable("$>", &rb_stdout, 0, stdout_setter);
          orig_stdout = rb_stdout;
        //rb_deferr = orig_stderr = rb_stderr;
        
        ///* constants to hold original stdin/stdout/stderr */
        //rb_define_global_const("STDIN", rb_stdin);
          rb_define_global_const("STDOUT", rb_stdout);
        //rb_define_global_const("STDERR", rb_stderr);
        
        //rb_define_readonly_variable("$<", &argf);
        //argf = rb_obj_alloc(rb_cObject);
        //rb_extend_object(argf, rb_mEnumerable);
        //rb_define_global_const("ARGF", argf);
        
        //rb_define_singleton_method(argf, "to_s", argf_to_s, 0);
        
        //rb_define_singleton_method(argf, "fileno", argf_fileno, 0);
        //rb_define_singleton_method(argf, "to_i", argf_fileno, 0);
        //rb_define_singleton_method(argf, "to_io", argf_to_io, 0);
        //rb_define_singleton_method(argf, "each",  argf_each_line, -1);
        //rb_define_singleton_method(argf, "each_line",  argf_each_line, -1);
        //rb_define_singleton_method(argf, "each_byte",  argf_each_byte, 0);
        //rb_define_singleton_method(argf, "each_char",  argf_each_char, 0);
        //rb_define_singleton_method(argf, "lines",  argf_each_line, -1);
        //rb_define_singleton_method(argf, "bytes",  argf_each_byte, 0);
        //rb_define_singleton_method(argf, "chars",  argf_each_char, 0);
        
        //rb_define_singleton_method(argf, "read",  argf_read, -1);
        //rb_define_singleton_method(argf, "readlines", rb_f_readlines, -1);
        //rb_define_singleton_method(argf, "to_a", rb_f_readlines, -1);
        //rb_define_singleton_method(argf, "gets", rb_f_gets, -1);
        //rb_define_singleton_method(argf, "readline", rb_f_readline, -1);
        //rb_define_singleton_method(argf, "getc", argf_getc, 0);
        //rb_define_singleton_method(argf, "getbyte", argf_getc, 0);
        //rb_define_singleton_method(argf, "readchar", argf_readchar, 0);
        //rb_define_singleton_method(argf, "readbyte", argf_readchar, 0);
        //rb_define_singleton_method(argf, "tell", argf_tell, 0);
        //rb_define_singleton_method(argf, "seek", argf_seek_m, -1);
        //rb_define_singleton_method(argf, "rewind", argf_rewind, 0);
        //rb_define_singleton_method(argf, "pos", argf_tell, 0);
        //rb_define_singleton_method(argf, "pos=", argf_set_pos, 1);
        //rb_define_singleton_method(argf, "eof", argf_eof, 0);
        //rb_define_singleton_method(argf, "eof?", argf_eof, 0);
        //rb_define_singleton_method(argf, "binmode", argf_binmode, 0);
        
        //rb_define_singleton_method(argf, "filename", argf_filename, 0);
        //rb_define_singleton_method(argf, "path", argf_filename, 0);
        //rb_define_singleton_method(argf, "file", argf_file, 0);
        //rb_define_singleton_method(argf, "skip", argf_skip, 0);
        //rb_define_singleton_method(argf, "close", argf_close_m, 0);
        //rb_define_singleton_method(argf, "closed?", argf_closed, 0);
        
        //rb_define_singleton_method(argf, "lineno",   argf_lineno, 0);
        //rb_define_singleton_method(argf, "lineno=",  argf_set_lineno, 1);
        
        //rb_global_variable(&current_file);
        //rb_define_readonly_variable("$FILENAME", &filename);
        //filename = rb_str_new2("-");
        
        //rb_define_virtual_variable("$-i", opt_i_get, opt_i_set);
        }
      END
    end
    
    # pulled from Init_Regexp, EMPTY
    def Init_MatchData
      <<-END
        function Init_MatchData() {}
      END
    end
    
    # pulled from Init_Proc
    def Init_Method
      add_function :rb_define_class, :rb_undef_alloc_func, :rb_undef_method
      <<-END
        function Init_Method() {
          rb_cMethod = rb_define_class("Method", rb_cObject);
          rb_undef_alloc_func(rb_cMethod);
          rb_undef_method(CLASS_OF(rb_cMethod), "new");
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
          rb_cNilClass = rb_define_class("NilClass", rb_cObject);
          rb_undef_alloc_func(rb_cNilClass);
          rb_undef_method(CLASS_OF(rb_cNilClass), "new");
          rb_define_global_const("NIL", Qnil);
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
          rb_eZeroDivError = rb_define_class("ZeroDivisionError", rb_eStandardError);
          rb_eFloatDomainError = rb_define_class("FloatDomainError", rb_eRangeError);
          rb_cNumeric = rb_define_class("Numeric", rb_cObject);
          rb_include_module(rb_cNumeric, rb_mComparable);
          rb_cInteger = rb_define_class("Integer", rb_cNumeric);
          rb_undef_alloc_func(rb_cInteger);
          rb_undef_method(CLASS_OF(rb_cInteger), "new");
          rb_include_module(rb_cInteger, rb_mPrecision);
          rb_cFixnum = rb_define_class("Fixnum", rb_cInteger);
          rb_include_module(rb_cFixnum, rb_mPrecision);
          rb_cFloat = rb_define_class("Float", rb_cNumeric);
          rb_undef_alloc_func(rb_cFloat);
          rb_undef_method(CLASS_OF(rb_cFloat), "new");
          rb_include_module(rb_cFloat, rb_mPrecision);
          rb_define_const(rb_cFloat, "ROUNDS", INT2FIX(FLT_ROUNDS));
          rb_define_const(rb_cFloat, "RADIX", INT2FIX(FLT_RADIX));
          rb_define_const(rb_cFloat, "MANT_DIG", INT2FIX(DBL_MANT_DIG));
          rb_define_const(rb_cFloat, "DIG", INT2FIX(DBL_DIG));
          rb_define_const(rb_cFloat, "MIN_EXP", INT2FIX(DBL_MIN_EXP));
          rb_define_const(rb_cFloat, "MAX_EXP", INT2FIX(DBL_MAX_EXP));
          rb_define_const(rb_cFloat, "MIN_10_EXP", INT2FIX(DBL_MIN_10_EXP));
          rb_define_const(rb_cFloat, "MAX_10_EXP", INT2FIX(DBL_MAX_10_EXP));
        //rb_define_const(rb_cFloat, "MIN", rb_float_new(DBL_MIN));
        //rb_define_const(rb_cFloat, "MAX", rb_float_new(DBL_MAX));
        //rb_define_const(rb_cFloat, "EPSILON", rb_float_new(DBL_EPSILON));
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
        rb_mKernel = rb_define_module("Kernel");
        rb_include_module(rb_cObject, rb_mKernel);
        rb_define_alloc_func(rb_cObject, rb_class_allocate_instance);
        ruby_top_self = rb_obj_alloc(rb_cObject);
        rb_define_singleton_method(ruby_top_self, "to_s", main_to_s, 0);
      }
      END
    end
    
    # verbatim
    def Init_Precision
      add_function :rb_define_module
      <<-END
        function Init_Precision() {
          rb_mPrecision = rb_define_module("Precision");
        }
      END
    end
    
    # changed rb_str_new2 to rb_str_new, CHECK
    def Init_Proc
      add_function :rb_define_class, :rb_exc_new3, :rb_obj_freeze, :rb_str_new, :rb_undef_alloc_func
      <<-END
        function Init_Proc() {
          rb_eLocalJumpError = rb_define_class("LocalJumpError", rb_eStandardError);
        //exception_error = rb_exc_new3(rb_eFatal, rb_obj_freeze(rb_str_new("exception reentered")));
        //OBJ_TAINT(exception_error);
        //OBJ_FREEZE(exception_error);
          
          rb_eSysStackError = rb_define_class("SystemStackError", rb_eStandardError);
        //sysstack_error = rb_exc_new3(rb_eSysStackError, rb_obj_freeze(rb_str_new("stack level too deep")));
        //OBJ_TAINT(sysstack_error);
        //OBJ_FREEZE(sysstack_error);
          
          rb_cProc = rb_define_class("Proc", rb_cObject);
          rb_undef_alloc_func(rb_cProc);
        }
      END
    end
    
    # verbatim
    def Init_Range
      $mc.add_function :rb_define_class, :rb_include_module
      <<-END
        function Init_Range() {
          rb_cRange = rb_define_class("Range", rb_cObject);
          rb_include_module(rb_cRange, rb_mEnumerable);
        }
      END
    end
    
    # EMPTY
    def Init_Regexp
      <<-END
        function Init_Regexp() {}
      END
    end
    
    # Sizzle
    def Init_sizzle
      <<-END
        function Init_sizzle() {
          var l=/((?:\\((?:\\([^()]+\\)|[^()]+)+\\)|\\[(?:\\[[^[\\]]*\\]|[^[\\]]+)+\\]|\\\\.|[^ >+~,(\\[]+)+|[>+~])(\\s*,\\s*)?/g,g=0,c=Object.prototype.toString;var b=function(B,p,x,s){x=x||[];p=p||document;if(p.nodeType!==1&&p.nodeType!==9){return[]}if(!B||typeof B!=="string"){return x}var y=[],z,v,E,D,w,o,n=true;l.lastIndex=0;while((z=l.exec(B))!==null){y.push(z[1]);if(z[2]){o=RegExp.rightContext;break}}if(y.length>1&&d.match.POS.exec(B)){if(y.length===2&&d.relative[y[0]]){var r="",u;while((u=d.match.POS.exec(B))){r+=u[0];B=B.replace(d.match.POS,"")}v=b.filter(r,b(/\\s$/.test(B)?B+"*":B,p))}else{v=d.relative[y[0]]?[p]:b(y.shift(),p);while(y.length){var e=[];B=y.shift();if(d.relative[B]){B+=y.shift()}for(var C=0,A=v.length;C<A;C++){b(B,v[C],e)}v=e}}}else{var F=s?{expr:y.pop(),set:a(s)}:b.find(y.pop(),y.length===1&&p.parentNode?p.parentNode:p);v=b.filter(F.expr,F.set);if(y.length>0){E=a(v)}else{n=false}while(y.length){var q=y.pop(),t=q;if(!d.relative[q]){q=""}else{t=y.pop()}if(t==null){t=p}d.relative[q](E,t,k(p))}}if(!E){E=v}if(!E){throw"Syntax error, unrecognized expression: "+(q||B)}if(c.call(E)==="[object Array]"){if(!n){x.push.apply(x,E)}else{if(p.nodeType===1){for(var C=0;E[C]!=null;C++){if(E[C]&&(E[C]===true||E[C].nodeType===1&&f(p,E[C]))){x.push(v[C])}}}else{for(var C=0;E[C]!=null;C++){if(E[C]&&E[C].nodeType===1){x.push(v[C])}}}}}else{a(E,x)}if(o){b(o,p,x,s)}return x};b.matches=function(e,n){return b(e,null,null,n)};b.find=function(s,p){var t,n;if(!s){return[]}for(var o=0,e=d.order.length;o<e;o++){var q=d.order[o],n;if((n=d.match[q].exec(s))){var r=RegExp.leftContext;if(r.substr(r.length-1)!=="\\\\"){n[1]=(n[1]||"").replace(/\\\\/g,"");t=d.find[q](n,p);if(t!=null){s=s.replace(d.match[q],"");break}}}}if(!t){t=p.getElementsByTagName("*")}return{set:t,expr:s}};b.filter=function(p,z,A,q){var n=p,v=[],E=z,s,y;while(p&&z.length){for(var r in d.filter){if((s=d.match[r].exec(p))!=null){var w=d.filter[r],o=null,u=0,x,D;y=false;if(E==v){v=[]}if(d.preFilter[r]){s=d.preFilter[r](s,E,A,v,q);if(!s){y=x=true}else{if(s===true){continue}else{if(s[0]===true){o=[];var t=null,C;for(var B=0;(C=E[B])!==undefined;B++){if(C&&t!==C){o.push(C);t=C}}}}}}if(s){for(var B=0;(D=E[B])!==undefined;B++){if(D){if(o&&D!=o[u]){u++}x=w(D,s,u,o);var e=q^!!x;if(A&&x!=null){if(e){y=true}else{E[B]=false}}else{if(e){v.push(D);y=true}}}}}if(x!==undefined){if(!A){E=v}p=p.replace(d.match[r],"");if(!y){return[]}break}}}p=p.replace(/\\s*,\\s*/,"");if(p==n){if(y==null){throw"Syntax error, unrecognized expression: "+p}else{break}}n=p}return E};var d=b.selectors={order:["ID","NAME","TAG"],match:{ID:/#((?:[\\w\\u00c0-\\uFFFF_-]|\\\\.)+)/,CLASS:/\\.((?:[\\w\\u00c0-\\uFFFF_-]|\\\\.)+)/,NAME:/\\[name=['"]*((?:[\\w\\u00c0-\\uFFFF_-]|\\\\.)+)['"]*\\]/,ATTR:/\\[\\s*((?:[\\w\\u00c0-\\uFFFF_-]|\\\\.)+)\\s*(?:(\\S?=)\\s*(['"]*)(.*?)\\3|)\\s*\\]/,TAG:/^((?:[\\w\\u00c0-\\uFFFF\\*_-]|\\\\.)+)/,CHILD:/:(only|nth|last|first)-child(?:\\((even|odd|[\\dn+-]*)\\))?/,POS:/:(nth|eq|gt|lt|first|last|even|odd)(?:\\((\\d*)\\))?(?=[^-]|$)/,PSEUDO:/:((?:[\\w\\u00c0-\\uFFFF_-]|\\\\.)+)(?:\\((['"]*)((?:\\([^\\)]+\\)|[^\\2\\(\\)]*)+)\\2\\))?/},attrMap:{"class":"className","for":"htmlFor"},attrHandle:{href:function(e){return e.getAttribute("href")}},relative:{"+":function(q,n){for(var o=0,e=q.length;o<e;o++){var p=q[o];if(p){var r=p.previousSibling;while(r&&r.nodeType!==1){r=r.previousSibling}q[o]=typeof n==="string"?r||false:r===n}}if(typeof n==="string"){b.filter(n,q,true)}},">":function(r,n,s){if(typeof n==="string"&&!/\\W/.test(n)){n=s?n:n.toUpperCase();for(var o=0,e=r.length;o<e;o++){var q=r[o];if(q){var p=q.parentNode;r[o]=p.nodeName===n?p:false}}}else{for(var o=0,e=r.length;o<e;o++){var q=r[o];if(q){r[o]=typeof n==="string"?q.parentNode:q.parentNode===n}}if(typeof n==="string"){b.filter(n,r,true)}}},"":function(p,n,r){var o="done"+(g++),e=m;if(!n.match(/\\W/)){var q=n=r?n:n.toUpperCase();e=j}e("parentNode",n,o,p,q,r)},"~":function(p,n,r){var o="done"+(g++),e=m;if(typeof n==="string"&&!n.match(/\\W/)){var q=n=r?n:n.toUpperCase();e=j}e("previousSibling",n,o,p,q,r)}},find:{ID:function(n,o){if(o.getElementById){var e=o.getElementById(n[1]);return e?[e]:[]}},NAME:function(e,n){return n.getElementsByName?n.getElementsByName(e[1]):null},TAG:function(e,n){return n.getElementsByTagName(e[1])}},preFilter:{CLASS:function(p,n,o,e,r){p=" "+p[1].replace(/\\\\/g,"")+" ";for(var q=0;n[q];q++){if(r^(" "+n[q].className+" ").indexOf(p)>=0){if(!o){e.push(n[q])}}else{if(o){n[q]=false}}}return false},ID:function(e){return e[1].replace(/\\\\/g,"")},TAG:function(n,e){for(var o=0;!e[o];o++){}return k(e[o])?n[1]:n[1].toUpperCase()},CHILD:function(e){if(e[1]=="nth"){var n=/(-?)(\\d*)n((?:\\+|-)?\\d*)/.exec(e[2]=="even"&&"2n"||e[2]=="odd"&&"2n+1"||!/\\D/.test(e[2])&&"0n+"+e[2]||e[2]);e[2]=(n[1]+(n[2]||1))-0;e[3]=n[3]-0}e[0]="done"+(g++);return e},ATTR:function(n){var e=n[1];if(d.attrMap[e]){n[1]=d.attrMap[e]}if(n[2]==="~="){n[4]=" "+n[4]+" "}return n},PSEUDO:function(q,n,o,e,r){if(q[1]==="not"){if(q[3].match(l).length>1){q[3]=b(q[3],null,null,n)}else{var p=b.filter(q[3],n,o,true^r);if(!o){e.push.apply(e,p)}return false}}else{if(d.match.POS.test(q[0])){return true}}return q},POS:function(e){e.unshift(true);return e}},filters:{enabled:function(e){return e.disabled===false&&e.type!=="hidden"},disabled:function(e){return e.disabled===true},checked:function(e){return e.checked===true},selected:function(e){e.parentNode.selectedIndex;return e.selected===true},parent:function(e){return !!e.firstChild},empty:function(e){return !e.firstChild},has:function(o,n,e){return !!b(e[3],o).length},header:function(e){return/h\\d/i.test(e.nodeName)},text:function(e){return"text"===e.type},radio:function(e){return"radio"===e.type},checkbox:function(e){return"checkbox"===e.type},file:function(e){return"file"===e.type},password:function(e){return"password"===e.type},submit:function(e){return"submit"===e.type},image:function(e){return"image"===e.type},reset:function(e){return"reset"===e.type},button:function(e){return"button"===e.type||e.nodeName.toUpperCase()==="BUTTON"},input:function(e){return/input|select|textarea|button/i.test(e.nodeName)}},setFilters:{first:function(n,e){return e===0},last:function(o,n,e,p){return n===p.length-1},even:function(n,e){return e%2===0},odd:function(n,e){return e%2===1},lt:function(o,n,e){return n<e[3]-0},gt:function(o,n,e){return n>e[3]-0},nth:function(o,n,e){return e[3]-0==n},eq:function(o,n,e){return e[3]-0==n}},filter:{CHILD:function(e,p){var s=p[1],t=e.parentNode;var r="child"+t.childNodes.length;if(t&&(!t[r]||!e.nodeIndex)){var q=1;for(var n=t.firstChild;n;n=n.nextSibling){if(n.nodeType==1){n.nodeIndex=q++}}t[r]=q-1}if(s=="first"){return e.nodeIndex==1}else{if(s=="last"){return e.nodeIndex==t[r]}else{if(s=="only"){return t[r]==1}else{if(s=="nth"){var v=false,o=p[2],u=p[3];if(o==1&&u==0){return true}if(o==0){if(e.nodeIndex==u){v=true}}else{if((e.nodeIndex-u)%o==0&&(e.nodeIndex-u)/o>=0){v=true}}return v}}}}},PSEUDO:function(s,o,p,t){var n=o[1],q=d.filters[n];if(q){return q(s,p,o,t)}else{if(n==="contains"){return(s.textContent||s.innerText||"").indexOf(o[3])>=0}else{if(n==="not"){var r=o[3];for(var p=0,e=r.length;p<e;p++){if(r[p]===s){return false}}return true}}}},ID:function(n,e){return n.nodeType===1&&n.getAttribute("id")===e},TAG:function(n,e){return(e==="*"&&n.nodeType===1)||n.nodeName===e},CLASS:function(n,e){return e.test(n.className)},ATTR:function(q,o){var e=d.attrHandle[o[1]]?d.attrHandle[o[1]](q):q[o[1]]||q.getAttribute(o[1]),r=e+"",p=o[2],n=o[4];return e==null?false:p==="="?r===n:p==="*="?r.indexOf(n)>=0:p==="~="?(" "+r+" ").indexOf(n)>=0:!o[4]?e:p==="!="?r!=n:p==="^="?r.indexOf(n)===0:p==="$="?r.substr(r.length-n.length)===n:p==="|="?r===n||r.substr(0,n.length+1)===n+"-":false},POS:function(q,n,o,r){var e=n[2],p=d.setFilters[e];if(p){return p(q,o,n,r)}}}};for(var i in d.match){d.match[i]=RegExp(d.match[i].source+/(?![^\\[]*\\])(?![^\\(]*\\))/.source)}var a=function(n,e){n=Array.prototype.slice.call(n);if(e){e.push.apply(e,n);return e}return n};try{Array.prototype.slice.call(document.documentElement.childNodes)}catch(h){a=function(q,p){var n=p||[];if(c.call(q)==="[object Array]"){Array.prototype.push.apply(n,q)}else{if(typeof q.length==="number"){for(var o=0,e=q.length;o<e;o++){n.push(q[o])}}else{for(var o=0;q[o];o++){n.push(q[o])}}}return n}}(function(){var n=document.createElement("form"),o="script"+(new Date).getTime();n.innerHTML="<input name='"+o+"'/>";var e=document.documentElement;e.insertBefore(n,e.firstChild);if(!!document.getElementById(o)){d.find.ID=function(q,r){if(r.getElementById){var p=r.getElementById(q[1]);return p?p.id===q[1]||p.getAttributeNode&&p.getAttributeNode("id").nodeValue===q[1]?[p]:undefined:[]}};d.filter.ID=function(r,p){var q=r.getAttributeNode&&r.getAttributeNode("id");return r.nodeType===1&&q&&q.nodeValue===p}}e.removeChild(n)})();(function(){var e=document.createElement("div");e.appendChild(document.createComment(""));if(e.getElementsByTagName("*").length>0){d.find.TAG=function(n,r){var q=r.getElementsByTagName(n[1]);if(n[1]==="*"){var p=[];for(var o=0;q[o];o++){if(q[o].nodeType===1){p.push(q[o])}}q=p}return q}}e.innerHTML="<a href='#'></a>";if(e.firstChild.getAttribute("href")!=="#"){d.attrHandle.href=function(n){return n.getAttribute("href",2)}}})();if(document.querySelectorAll){(function(){var e=b;b=function(q,p,n,o){p=p||document;if(!o&&p.nodeType===9){try{return a(p.querySelectorAll(q),n)}catch(r){}}return e(q,p,n,o)};b.find=e.find;b.filter=e.filter;b.selectors=e.selectors;b.matches=e.matches})()}if(document.documentElement.getElementsByClassName){d.order.splice(1,0,"CLASS");d.find.CLASS=function(e,n){return n.getElementsByClassName(e[1])}}function j(n,t,s,w,u,v){for(var q=0,o=w.length;q<o;q++){var e=w[q];if(e){e=e[n];var r=false;while(e&&e.nodeType){var p=e[s];if(p){r=w[p];break}if(e.nodeType===1&&!v){e[s]=q}if(e.nodeName===t){r=e;break}e=e[n]}w[q]=r}}}function m(n,s,r,v,t,u){for(var p=0,o=v.length;p<o;p++){var e=v[p];if(e){e=e[n];var q=false;while(e&&e.nodeType){if(e[r]){q=v[e[r]];break}if(e.nodeType===1){if(!u){e[r]=p}if(typeof s!=="string"){if(e===s){q=true;break}}else{if(b.filter(s,[e]).length>0){q=e;break}}}e=e[n]}v[p]=q}}}var f=document.compareDocumentPosition?function(n,e){return n.compareDocumentPosition(e)&16}:function(n,e){return n!==e&&(n.contains?n.contains(e):true)};var k=function(e){return e.documentElement&&!e.body||e.tagName&&e.ownerDocument&&!e.ownerDocument.body}; return b;
        }
      END
    end
    
    # verbatim
    def Init_String
      add_functions :rb_define_class, :rb_include_module,
                    :rb_define_alloc_func, :rb_define_variable
      <<-END
        function Init_String() {
          rb_cString = rb_define_class("String", rb_cObject);
          rb_include_module(rb_cString, rb_mComparable);
          rb_include_module(rb_cString, rb_mEnumerable);
          rb_define_alloc_func(rb_cString, str_alloc);
          rb_fs = Qnil;
          rb_define_variable("$;", rb_fs);
          rb_define_variable("$-F", rb_fs);
        }
      END
    end
    
    # verbatim
    def Init_Struct
      add_function :rb_define_class, :rb_include_module, :rb_undef_alloc_func
      <<-END
        function Init_Struct() {
          rb_cStruct = rb_define_class("Struct", rb_cObject);
          rb_include_module(rb_cStruct, rb_mEnumerable);
          rb_undef_alloc_func(rb_cStruct);
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
          rb_cSymbol = rb_define_class("Symbol", rb_cObject);
          rb_undef_alloc_func(rb_cSymbol);
          rb_undef_method(CLASS_OF(rb_cSymbol), "new");
        }
      END
    end
    
    # pulled from Init_Object
    def Init_TrueClass
      add_function :rb_define_class, :rb_undef_alloc_func, :rb_undef_method, :rb_define_global_const
      <<-END
        function Init_TrueClass() {
          rb_cTrueClass = rb_define_class("TrueClass", rb_cObject);
          rb_undef_alloc_func(rb_cTrueClass);
          rb_undef_method(CLASS_OF(rb_cTrueClass), "new");
          rb_define_global_const("TRUE", Qtrue);
        }
      END
    end
    
    # pulled from Init_Proc
    def Init_UnboundMethod
      add_functions :rb_define_class, :rb_undef_alloc_func, :rb_undef_method
      <<-END
        function Init_UnboundMethod() {
          rb_cUnboundMethod = rb_define_class("UnboundMethod", rb_cObject);
          rb_undef_alloc_func(rb_cUnboundMethod);
          rb_undef_method(CLASS_OF(rb_cUnboundMethod), "new");
        }
      END
    end
    
    # need to move method defs to class << Ruby
    def Init_UserEvent
      add_function :rb_define_module, :init_custom_events, :rb_intern
      <<-END
        function Init_UserEvent() {
          rb_mUserEvent = rb_define_module("UserEvent");
          sym_base       = ID2SYM(rb_intern("base"));
          sym_condition  = ID2SYM(rb_intern("condition"));
          sym_onlisten   = ID2SYM(rb_intern("on_listen"));
          sym_onunlisten = ID2SYM(rb_intern("on_unlisten"));
          init_custom_events();
        }
      END
    end
    
    # moved id definitions to Init_ids and changed st tables
    def Init_var_tables
      <<-END
        function Init_var_tables() {
          rb_global_tbl = {}; // was st_init_numtable
          rb_class_tbl  = {}; // was st_init_numtable
        }
      END
    end
    
    # need to move method defs to class << Ruby
    def Init_Window
      add_function :rb_define_module, :win_document, :win_window
      <<-END
        function Init_Window() {
          rb_mWindow = rb_define_module("Window");
          
          rb_define_module_function(rb_mWindow, "document", win_document, 0);
          rb_define_module_function(rb_mWindow, "window", win_window, 0);
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
                    :Init_syserr, :Init_Array, :Init_Hash, :Init_Struct,
                    :Init_Regexp, :Init_Range, :Init_IO, :Init_Time,
                    :Init_Random, :Init_Proc, :Init_Binding, :Init_Math,
                    :Init_Enumerator, :Init_version, :Init_UserEvent,
                    :Init_Document, :Init_Element, :Init_Window, :Init_Method,
                    :Init_UnboundMethod, :Init_MatchData, :Init_Event,
                    :Init_Browser
      <<-END
        function rb_call_inits() {
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
        //Init_Bignum();
        //Init_syserr();
          Init_Array();
          Init_Hash();
          Init_Struct();
          Init_Regexp();
          Init_MatchData();
          Init_Range();
          Init_IO();
        //Init_Time();
        //Init_Random();
          Init_Proc();
          Init_Method();
          Init_UnboundMethod();
          Init_Binding();
        //Init_Math();
          Init_Enumerator();
        //Init_version();
          
          Init_Browser();
          Init_UserEvent();
          Init_Document();
          Init_Element();
          Init_Event();
          Init_Window();
        }
      END
    end
    
    # CHECK CHECK CHECK
    def ruby_init
      add_functions :rb_call_inits, :rb_define_global_const, :rb_f_binding, :rb_node_newnode, :top_local_init
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
          //rb_define_global_const("TOPLEVEL_BINDING", rb_f_binding(ruby_top_self));
          //ruby_prog_init();
          //ALLOW_INTS();
          } catch (x) {
            if (typeof(state = x) != "number") { throw(state); }
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
  
  module Class
    # verbatim
    def include_class_new
      <<-END
        function include_class_new(module, superclass) {
          var klass = NEWOBJ();
          OBJSETUP(klass, rb_cClass, T_ICLASS);
          if (BUILTIN_TYPE(module) == T_ICLASS) { module = module.basic.klass; }
          if (!module.iv_tbl) { module.iv_tbl = {}; } // was st_init_numtable
          klass.iv_tbl = module.iv_tbl;
          klass.m_tbl = module.m_tbl;
          klass.superclass = superclass;
          klass.basic.klass = (TYPE(module) == T_ICLASS) ? module.basic.klass : module;
          OBJ_INFECT(klass, module);
          OBJ_INFECT(klass, superclass);
          return klass;
        }
      END
    end
    
    # verbatim
    def rb_check_inheritable
      add_function :rb_raise, :rb_obj_classname
      <<-END
        function rb_check_inheritable(superclass) {
          if (TYPE(superclass) != T_CLASS) { rb_raise(rb_eTypeError, "superclass must be a Class (%s given)", rb_obj_classname(superclass)); }
          if (superclass.basic.flags & FL_SINGLETON) { rb_raise(rb_eTypeError, "can't make subclass of virtual class"); }
        }
      END
    end
    
    # verbatim
    def rb_class_allocate_instance
      <<-END
        function rb_class_allocate_instance(klass) {
          var obj = NEWOBJ();
          OBJSETUP(obj, klass, T_OBJECT);
          return obj;
        }
      END
    end
    
    # verbatim
    def rb_class_boot
      <<-END
        function rb_class_boot(superclass) {
          var klass = NEWOBJ();
          OBJSETUP(klass, rb_cClass, T_CLASS);
          klass.superclass = superclass;
          klass.iv_tbl = 0;
          klass.m_tbl = {};
          OBJ_INFECT(klass, superclass);
          return klass;
        }
      END
    end
    
    # verbatim
    def rb_class_inherited
      add_function :rb_funcall, :rb_intern
      add_method :inherited
      <<-END
        function rb_class_inherited(superclass, klass) {
          if (!superclass) { superclass = rb_cObject; }
          return rb_funcall(superclass, rb_intern("inherited"), 1, klass);
        }
      END
    end
    
    # verbatim
    def rb_class_init_copy
      add_function :rb_raise, :rb_mod_init_copy
      <<-END
        function rb_class_init_copy(clone, orig)
        {
          if (clone.superclass !== 0) { rb_raise(rb_eTypeError, "already initialized class"); }
          if (FL_TEST(orig, FL_SINGLETON)) { rb_raise(rb_eTypeError, "can't copy singleton class"); }
          return rb_mod_init_copy(clone, orig);
        }
      END
    end
    
    # expanded rb_scan_args
    def rb_class_initialize
      add_function :rb_raise, :rb_scan_args, :rb_check_inheritable, :rb_make_metaclass, :rb_mod_initialize, :rb_class_inherited
      <<-END
        function rb_class_initialize(argc, argv, klass) {
          var superclass;
          if (klass.superclass !== 0) { rb_raise(rb_eTypeError, "already initialized class"); }
          var tmp = rb_scan_args(argc, argv, "01");
          superclass = tmp[1];
          if (tmp[0] === 0) {
            superclass = rb_cObject;
          } else {
            rb_check_inheritable(superclass);
          }
          klass.superclass = superclass;
          rb_make_metaclass(klass, superclass.basic.klass);
          rb_mod_initialize(klass);
          rb_class_inherited(super, klass);
          return klass;
        }
      END
    end
    
    # verbatim
    def rb_class_new
      add_function :rb_raise, :rb_class_boot, :rb_check_type
      <<-END
        function rb_class_new(superclass) {
          Check_Type(superclass, T_CLASS);
          if (superclass == rb_cClass) { rb_raise(rb_eTypeError, "can't make a subclass of Class"); }
          if (FL_TEST(superclass, FL_SINGLETON)) { rb_raise(rb_eTypeError, "can't make subclass of virtual class"); }
          return rb_class_boot(superclass);
        }
      END
    end
    
    # verbatim
    def rb_class_new_instance
      add_function :rb_obj_alloc, :rb_obj_call_init
      <<-END
        function rb_class_new_instance(argc, argv, klass) {
          var obj = rb_obj_alloc(klass);
          rb_obj_call_init(obj, argc, argv);
          return obj;
        }
      END
    end
    
    # verbatim
    def rb_class_s_alloc
      add_function :rb_class_boot
      <<-END
        function rb_class_s_alloc(klass) {
          return rb_class_boot(0);
        }
      END
    end
    
    # verbatim
    def rb_class_superclass
      add_function :rb_raise
      <<-END
        function rb_class_superclass(klass) {
          var superclass = klass.superclass;
          if (!superclass) { rb_raise(rb_eTypeError, "uninitialized class"); }
          if (FL_TEST(klass, FL_SINGLETON)) { superclass = klass.basic.klass; }
          while (TYPE(superclass) == T_ICLASS) { superclass = superclass.superclass; }
          return superclass || Qnil;
        }
      END
    end
    
    # verbatim
    def rb_define_class
      add_function :rb_const_defined, :rb_const_get, :rb_raise,
                   :rb_class_real, :rb_name_error, :rb_define_class_id,
                   :rb_name_class, :rb_const_set, :rb_class_inherited
      <<-END
        function rb_define_class(name, superclass) {
          var klass;
          var id = rb_intern(name);
          if (rb_const_defined(rb_cObject, id)) {
            klass = rb_const_get(rb_cObject, id);
            if (TYPE(klass) != T_CLASS) { rb_raise(rb_eTypeError, "%s is not a class", name); }
            if (rb_class_real(klass.superclass) != superclass) { rb_name_error(id, "%s is already defined", name); }
            return klass;
          }
          // removed warning
          klass = rb_define_class_id(id, superclass);
          rb_class_tbl[id] = klass; // changed from st_add_direct
          rb_name_class(klass, id);
          rb_const_set(rb_cObject, id, klass);
          rb_class_inherited(superclass, klass);
          return klass;
        }
      END
    end
    
    # verbatim
    def rb_define_class_id
      add_function :rb_class_new, :rb_make_metaclass
      <<-END
        function rb_define_class_id(id, superclass) {
          if (!superclass) { superclass = rb_cObject; }
          var klass = rb_class_new(superclass);
          rb_make_metaclass(klass, superclass.basic.klass);
          return klass;
        }
      END
    end
    
    # verbatim
    def rb_define_class_under
      add_function :rb_const_defined_at, :rb_const_get_at, :rb_raise,
                   :rb_class_real, :rb_name_error, :rb_define_class_id,
                   :rb_set_class_path, :rb_const_set, :rb_class_inherited
      <<-END
        function rb_define_class_under(outer, name, superclass) {
          var klass;
          var id = rb_intern(name);
          if (rb_const_defined_at(outer, id)) {
            klass = rb_const_get_at(outer, id);
            if (TYPE(klass) != T_CLASS) { rb_raise(rb_eTypeError, "%s is not a class", name); }
            if (rb_class_real(klass.superclass) != superclass) { rb_name_error(id, "%s is already defined", name); }
            return klass;
          }
          // removed warning
          klass = rb_define_class_id(id, superclass);
          rb_set_class_path(klass, outer, name);
          rb_const_set(outer, id, klass);
          rb_class_inherited(superclass, klass);
          return klass;
        }
      END
    end
    
    # verbatim
    def rb_define_global_function
      add_function :rb_define_module_function
      <<-END
        function rb_define_global_function(name, func, argc) {
          rb_define_module_function(rb_mKernel, name, func, argc);
        }
      END
    end
    
    # verbatim
    def rb_define_method
      add_function :rb_add_method
      <<-END
        function rb_define_method(klass, name, func, argc) {
          rb_add_method(klass, rb_intern(name), NEW_CFUNC(func, argc), NOEX_PUBLIC);
        }
      END
    end
    
    # verbatim
    def rb_define_module
      add_function :rb_const_defined, :rb_const_get, :rb_raise,
                   :rb_obj_classname, :rb_define_module_id, :rb_const_set
      <<-END
        function rb_define_module(name) {
          var module;
          var id = rb_intern(name);
          if (rb_const_defined(rb_cObject, id)) {
            module = rb_const_get(rb_cObject, id);
            if (TYPE(module) == T_MODULE) { return module; }
            rb_raise(rb_eTypeError, "%s is not a module", rb_obj_classname(module));
          }
          module = rb_define_module_id(id);
          rb_class_tbl[id] = module; // was st_add_direct
          rb_const_set(rb_cObject, id, module);
          return module;
        }
      END
    end
    
    # verbatim
    def rb_define_module_function
      add_function :rb_define_private_method, :rb_define_singleton_method
      <<-END
        function rb_define_module_function(module, name, func, argc) {
          rb_define_private_method(module, name, func, argc);
          rb_define_singleton_method(module, name, func, argc);
        }
      END
    end
    
    # verbatim
    def rb_define_module_id
      add_function :rb_name_class, :rb_module_new
      <<-END
        function rb_define_module_id(id) {
          var mdl = rb_module_new();
          rb_name_class(mdl, id);
          return mdl;
        }
      END
    end
    
    # verbatim
    def rb_define_private_method
      add_function :rb_add_method
      <<-END
        function rb_define_private_method(klass, name, func, argc) {
          rb_add_method(klass, rb_intern(name), NEW_CFUNC(func, argc), NOEX_PRIVATE);
        }
      END
    end
    
    # verbatim
    def rb_define_singleton_method
      add_function :rb_define_method, :rb_singleton_class
      <<-END
        function rb_define_singleton_method(obj, name, func, argc) {
          rb_define_method(rb_singleton_class(obj), name, func, argc);
        }
      END
    end
    
    # reworked "goto" architecture using variable
    def rb_include_module
      add_function :rb_frozen_class_p, :rb_secure, :rb_raise, :include_class_new, :rb_clear_cache, :rb_check_type
      <<-END
        function rb_include_module(klass, module) {
          var changed = 0;
          rb_frozen_class_p(klass);
          if (!OBJ_TAINTED(klass)) { rb_secure(4); }
          if (TYPE(module) != T_MODULE) { Check_Type(module, T_MODULE); }
          OBJ_INFECT(klass, module);
          var c = klass;
          var goto_skip = 0; // added
          while (module) {
            var superclass_seen = Qfalse;
            if (klass.m_tbl == module.m_tbl) { rb_raise(rb_eArgError, "cyclic include detected"); }
            /* ignore if the module included already in superclasses */
            for (var p = klass.superclass; p; p = p.superclass) {
              switch (BUILTIN_TYPE(p)) {
                case T_ICLASS:
                  if (p.m_tbl == module.m_tbl) {
                    if (!superclass_seen) { c = p; } /* move insertion point */
                    goto_skip = 1; // changed to variable
                  }
                  break;
                case T_CLASS:
                  superclass_seen = Qtrue;
                  break;
              }
              if (goto_skip) { break; } // added
            }
            if (!goto_skip) { // added
              c = c.superclass = include_class_new(module, c.superclass);
              changed = 1;
            }
            module = module.superclass;
          }
          if (changed) { rb_clear_cache(); }
        }
      END
    end
    
    # verbatim
    def rb_make_metaclass
      add_function :rb_class_boot, :rb_singleton_class_attached, :rb_class_real
      <<-END
        function rb_make_metaclass(obj, superclass) {
          var klass = rb_class_boot(superclass);
          FL_SET(klass, FL_SINGLETON);
          obj.basic.klass = klass;
          rb_singleton_class_attached(klass, obj);
          if (BUILTIN_TYPE(obj) == T_CLASS && FL_TEST(obj, FL_SINGLETON)) {
            klass.basic.klass = klass;
            klass.superclass = rb_class_real(obj.superclass).basic.klass;
          } else {
            var metasuper = rb_class_real(superclass).basic.klass;
            if (metasuper) { klass.basic.klass = metasuper; }
          }
          return klass;
        }
      END
    end
    
    # changed st table to object
    def rb_module_new
      <<-END
        function rb_module_new() {
          var mdl = NEWOBJ();
          OBJSETUP(mdl, rb_cModule, T_MODULE);
          mdl.superclass = 0;
          mdl.iv_tbl = 0;
          mdl.m_tbl = {}; // was st_init_numtable
          return mdl;
        }
      END
    end
    
    # verbatim
    def rb_module_s_alloc
      add_function :rb_module_new
      <<-END
        function rb_module_s_alloc(klass) {
          var mod = rb_module_new();
          mod.basic.klass = klass;
          return mod;
        }
      END
    end
    
    # verbatim
    def rb_undef_method
      add_function :rb_add_method, :rb_intern
      <<-END
        function rb_undef_method(klass, name) {
          rb_add_method(klass, rb_intern(name), 0, NOEX_UNDEF);
        }
      END
    end
    
    # unpacked SPECIAL_SINGLETON macro
    def rb_singleton_class
      add_function :rb_raise, :rb_special_const_p, :rb_iv_get, :rb_make_metaclass
      <<-END
        function rb_singleton_class(obj) {
          var klass;
          if (FIXNUM_P(obj) || SYMBOL_P(obj)) { rb_raise(rb_eTypeError, "can't define singleton"); }
          if (rb_special_const_p(obj)) {
            if (obj == Qnil)   { return rb_cNilClass; } // was SPECIAL_SINGLETON(Qnil, rb_cNilClass)
            if (obj == Qfalse) { return rb_cFalseClass; } // was SPECIAL_SINGLETON(Qfalse, rb_cFalseClass)
            if (obj == Qtrue)  { return rb_cTrueClass; } // was SPECIAL_SINGLETON(Qtrue, rb_cTrueClass)
          }
        //DEFER_INTS();
          if (FL_TEST(obj.basic.klass, FL_SINGLETON) && (rb_iv_get(obj.basic.klass, "__attached__") == obj)) {
            klass = obj.basic.klass;
          } else {
            klass = rb_make_metaclass(obj, obj.basic.klass);
          }
          if (OBJ_TAINTED(obj)) { OBJ_TAINT(klass); } else { FL_UNSET(klass, FL_TAINT); }
          if (OBJ_FROZEN(obj)) { OBJ_FREEZE(klass); }
        //ALLOW_INTS();
          return klass;
        }
      END
    end
    
    # changed st tables to js objects
    def rb_singleton_class_attached
      <<-END
        function rb_singleton_class_attached(klass, obj) {
          if (FL_TEST(klass, FL_SINGLETON)) {
            if (!klass.iv_tbl) { klass.iv_tbl = {}; } // {} was st_init_numtable
            klass.iv_tbl[rb_intern('__attached__')] = obj; // was st_insert
          }
        }
      END
    end
    
    # unwound "goto" architecture, modified va_arg handling
    # instead of getting pointers in vargs gets "true" values
    # returns array of values instead of setting pointers: [argc, val1, val2, ...]
    def rb_scan_args
      add_function :rb_raise, :rb_fatal, :rb_ary_new, :rb_block_given_p, :rb_block_proc
      <<-END
        function rb_scan_args(argc, argv, fmt) {
          var n;
          var p = 0;
          var vars;
          var ary = [argc];
          var goto_error = 0;
          var goto_rest_arg = 0;
          var vargs = 0;
          if (fmt[p] == '*') { goto_rest_arg = 1; }
          if (!goto_rest_arg) { // added to handle "goto rest_arg"
            if (ISDIGIT(fmt[p])) {
              n = fmt[p] - '0';
              if (argc < n) { rb_raise(rb_eArgError, "wrong number of arguments (%d for %d)", argc, n); }
              for (var i = 0; i < n; i++) {
                vars = argv[vargs++]; // just getting next argument out; was "vars = va_arg(vargs, VALUE*);"
                if (vars) { ary.push(argv[i]); } // was "*vars = argv[i]"
              }
              p++;
            } else {
              rb_fatal("bad scan arg format: %s", fmt);
              return [0];
            }
            if (ISDIGIT(fmt[p])) {
              n = i + fmt[p] - '0';
              for (; i < n; i++) {
                vars = argv[vargs++]; // was "vars = va_arg(vargs, VALUE*);"
                if (argc > i) {
                  if (vars) { ary.push(argv[i]); } // was "*vars = argv[i]"
                } else {
                  if (vars) { ary.push(Qnil); } // was "*vars = Qnil"
                }
              }
              p++;
            }
          } // added to handle "goto rest_arg"
          if (goto_rest_arg || (fmt[p] == '*')) { // added "goto_rest_arg ||" in condition
            vars = arguments[vargs++]; // was "vars = va_arg(vargs, VALUE*);"
            if (argc > i) {
              if (vars) { // was "*vars = rb_ary_new4(argc - i, argv + i)"
                var ary4 = rb_ary_new();
                MEMCPY(ary4, argv.slice(1), argc - 1);
                ary.push(ary4);
              }
              i = argc;
            } else {
              if (vars) { ary.push(rb_ary_new()); } // was "*vars = rb_ary_new()"
            }
            p++;
          }
          if (fmt[p] == '&') {
            vars = arguments[vargs++]; // was "vars = va_arg(vargs, VALUE*);"
            ary.push(rb_block_given_p() ? rb_block_proc() : Qnil); // was "*vars = rb_block_given_p() ? rb_block_proc() : Qnil"
            p++;
          }
          if (typeof(fmt[p]) != "undefined") {
            rb_fatal("bad scan arg format: %s", fmt);
            return [0];
          }
          if (argc > i) { rb_raise(rb_eArgError, "wrong number of arguments (%d for %d)", argc, i); }
          return ary;
        }
      END
    end
  end
  
  module Comparable
    # CHECK
    def cmp_between
      add_function :cmp_lt, :cmp_gt
      <<-END
        function cmp_between(x, y) {
          if (RTEST(cmp_lt(x, min))) { return Qfalse; }
          if (RTEST(cmp_gt(x, max))) { return Qfalse; }
          return Qtrue;
        }
      END
    end
    
    # CHECK
    def cmp_equal
      add_function :rb_rescue, :cmp_failed
      <<-END
        function cmp_equal(x, y) {
          if (x == y) { return Qtrue; }
          return rb_rescue(cmp_eq, [x, y], cmp_failed, 0);
        }
      END
    end
    
    # verbatim
    def cmp_failed
      <<-END
        function cmp_failed() {
          return Qnil;
        }
      END
    end
    
    # CHECK
    def cmp_ge
      add_function :rb_funcall, :rb_cmpint, :cmperr
      add_method :'<=>'
      <<-END
        function cmp_ge(x, y) {
          var c = rb_funcall(x, cmp, 1, y);
          if (NIL_P(c)) { return cmperr(); }
          return (rb_cmpint(c, x, y) >= 0) ? Qtrue : Qfalse;
        }
      END
    end
    
    # CHECK
    def cmp_gt
      add_function :rb_funcall, :rb_cmpint, :cmperr
      add_method :'<=>'
      <<-END
        function cmp_gt(x, y) {
          var c = rb_funcall(x, cmp, 1, y);
          if (NIL_P(c)) { return cmperr(); }
          return (rb_cmpint(c, x, y) > 0) ? Qtrue : Qfalse;
        }
      END
    end
    
    # CHECK
    def cmp_le
      add_function :rb_funcall, :rb_cmpint, :cmperr
      add_method :'<=>'
      <<-END
        function cmp_le(x, y) {
          var c = rb_funcall(x, cmp, 1, y);
          if (NIL_P(c)) { return cmperr(); }
          return (rb_cmpint(c, x, y) <= 0) ? Qtrue : Qfalse;
        }
      END
    end
    
    # CHECK
    def cmp_lt
      add_function :rb_funcall, :rb_cmpint, :cmperr
      add_method :'<=>'
      <<-END
        function cmp_lt(x, y) {
          var c = rb_funcall(x, cmp, 1, y);
          if (NIL_P(c)) { return cmperr(); }
          return (rb_cmpint(c, x, y) < 0) ? Qtrue : Qfalse;
        }
      END
    end
  end
  
  module Rb
    def rb_attr_get
      
    end
    
    # verbatim
    def rb_true
      <<-END
        function rb_true() {
          return Qtrue;
        }
      END
    end
  end
  
  module Data
    # CHECK
    def rb_data_object_alloc
      add_function :rb_check_type
      <<-END
        function rb_data_object_alloc(klass, datap) {
          var data = NEWOBJ();
          if (klass) { Check_Type(klass, T_CLASS); }
          OBJSETUP(data, klass, T_DATA);
          data.data = datap;
          return data;
        }
      END
    end
  end
  
  module Enumerable
    # verbatim
    def collect_all
      add_function :rb_ary_push
      <<-END
        function collect_all(i, ary) {
          rb_ary_push(ary, i);
          return Qnil;
        }
      END
    end
    
    # EMPTY
    def enum_find
      <<-END
        function enum_find() {}
      END
    end
    
    # verbatim
    def enum_to_a
      add_function :rb_block_call, :collect_all, :rb_ary_new
      <<-END
        function enum_to_a(argc, argv, obj) {
          var ary = rb_ary_new();
          rb_block_call(obj, id_each, argc, argv, collect_all, ary);
          return ary;
        }
      END
    end
  end
  
  module Enumerator
    # EMPTY
    def enumerator_allocate
      <<-END
        function enumerator_allocate() {}
      END
    end
    
    # EMPTY
    def enumerator_init_copy
      <<-END
        function enumerator_init_copy() {}
      END
    end
    
    # EMPTY
    def enumerator_initialize
      <<-END
        function enumerator_initialize() {}
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
      add_function :ruby_set_current_source, :jsprintf, :rb_id2name,
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
            } else if (ruby_sourceline == 0) {
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
            tmp = []; // was "ALLOC_N(struct BLOCK, 1)"
            console.log('check blk_copy_prev');
            MEMCPY(tmp, block.prev, 1); // SHOULD THIS BE "[block.prev]" OR IS block.prev ALREADY AN ARRAY
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
            var b = rb_check_convert_type(proc, T_DATA, "Proc", "to_proc");
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
              if (typeof(state = x) != "number") { throw(state); }
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
    
    # expanded rb_ary_new4
    def call_cfunc
      add_function :rb_raise, :rb_ary_new, :rb_ary_new4
      <<-END
        function call_cfunc(func, recv, len, argc, argv) {
          if (len >= 0 && argc != len) { rb_raise(rb_eArgError, "wrong number of arguments (%d for %d)", argc, len); }
          switch (len) {
            case -2:
              var ary = rb_ary_new();
              MEMCPY(ary.ptr, argv, argc);
              return func(recv, ary); // changed rb_ary_new4(argc, argv) to ary
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
    
    # added console.log command here, as in io_puts
    def error_print
      add_function :get_backtrace, :ruby_set_current_source, :warn_printf,
                   :error_pos, :rb_write_error, :rb_intern, :rb_class_name,
                   :rb_funcall
      add_method :message
      <<-END
        function error_print() {
          var errat = Qnil;
          var eclass;
          var e;
          var einfo;
          var elen;
          if (NIL_P(ruby_errinfo)) { return; }
          PUSH_TAG(PROT_NONE);
          try { // was EXEC_TAG
            errat = get_backtrace(ruby_errinfo);
          } catch (x) {
            if (typeof(state = x) != "number") { throw(state); }
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
            } else if (errat.ptr.length == 0) {
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
          } catch (x) { // was "goto error"
            if (typeof(state = x) != "number") { throw(state); }
            prot_tag = _tag.prev; 
            return; // exits TAG_MACRO wrapper function
          }
          try { // was EXEC_TAG
            e = rb_funcall(ruby_errinfo, rb_intern("message"), 0, 0);
          //StringValue(e);
            einfo = e.ptr;
            elen = einfo.length;
          } catch (x) {
            if (typeof(state = x) != "number") { throw(state); }
            einfo = "";
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
                if ((tail = einfo.indexOf('\\n')) != 0) {
                  len = tail - einfo;
                  tail++ /* skip newline */
                }
                rb_write_error(": " + einfo);
                if (epath) { rb_write_error(" (" + epath.ptr + ")\\n"); }
                if (tail && (elen > len + 1)) {
                  rb_write_error(tail);
                  if (einfo[elen-1] != '\\n') { rb_write_error("\\n"); }
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
          } catch (x) { // was "goto error"
            if (typeof(state = x) != "number") { throw(state); }
          }
          POP_TAG();
          console.log(CONSOLE_LOG_BUFFER); // added
          CONSOLE_LOG_BUFFER = ''; // added
        }
      END
    end
    
    # removed "autoload" call
    def ev_const_get
      add_function :rb_const_get
      <<-END
        function ev_const_get(cref, id, self) {
          var cbase = cref;
          var result;
          while (cbase && cbase.nd_next) {
            var klass = cbase.nd_clss;
            if (!NIL_P(klass)) {
              while (klass.iv_tbl && (result = klass.iv_tbl[id])) { // was st_lookup
                if (result == Qundef) { continue; } // removed "autoload" call
                return result;
              }
            }
            cbase = cbase.nd_next;
          }
          return rb_const_get(NIL_P(cref.nd_clss) ? CLASS_OF(self) : cref.nd_clss, id);
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
          rb_iv_set(exc, "@exit_value", value);
          switch (reason) {
            case TAG_BREAK:
              id = rb_intern("break");
              break;
            case TAG_REDO:
              id = rb_intern("redo");
              break;
            case TAG_RETRY:
              id = rb_intern("retry");
              break;
            case TAG_NEXT:
              id = rb_intern("next");
              break;
            case TAG_RETURN:
              id = rb_intern("return");
              break;
            default:
              id = rb_intern("noreason");
              break;
          }
          rb_iv_set(exc, "@reason", ID2SYM(id));
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
            nargv = []; // was "nargv = ALLOCA_N(VALUE, argc + RARRAY(tmp)->len + 1)"
            MEMCPY(nargv, argv, argc, 1);
            MEMCPY(nargv, tmp.ptr, tmp.ptr.length, 1 + argc);
            argc += tmp.ptr.length;
          } else {
            nargv = []; // was "nargv = ALLOCA_N(VALUE, argc+1)"
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
            if (typeof(state) != "number") { throw(state); }
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
    
    # verbatim
    def rb_add_method
      add_function :rb_raise, :rb_intern, :rb_error_frozen, :rb_clear_cache_by_id, :rb_funcall, :rb_iv_get
      add_method :singleton_method_added, :method_added
      <<-END
        function rb_add_method(klass, mid, node, noex) {
          var body;
          if (NIL_P(klass)) { klass = rb_cObject; }
          if (ruby_safe_level >= 4 && (klass == rb_cObject || !OBJ_TAINTED(klass))) { rb_raise(rb_eSecurityError, "Insecure: can't define method"); }
          if (!FL_TEST(klass, FL_SINGLETON) && node && (nd_type(node) != NODE_ZSUPER) && (mid == rb_intern("initialize") || mid == rb_intern("initialize_copy"))) {
            noex = NOEX_PRIVATE | noex;
          } else if (FL_TEST(klass, FL_SINGLETON) && node && (nd_type(node) == NODE_CFUNC) && (mid == rb_intern("allocate"))) {
            // removed warning about defining "allocate"
            mid = ID_ALLOCATOR;
          }
          if (OBJ_FROZEN(klass)) { rb_error_frozen("class/module"); }
          rb_clear_cache_by_id(mid);
          body = NEW_METHOD(node, NOEX_WITH_SAFE(noex));
          klass.m_tbl[mid] = body; // was st_insert
          if (node && (mid != ID_ALLOCATOR) && ruby_running) {
            if (FL_TEST(klass, FL_SINGLETON)) {
              rb_funcall(rb_iv_get(klass, "__attached__"), singleton_added, 1, ID2SYM(mid));
            } else {
              rb_funcall(klass, added, 1, ID2SYM(mid));
            }
          }
        }
      END
    end
    
    # expanded search_method
    def rb_alias
      add_function :rb_frozen_class_p, :search_method, :print_undef, :rb_iv_get, :rb_clear_cache_by_id, :rb_funcall
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
          klass.m_tbl[name] = NEW_METHOD(NEW_FBODY(body, def, origin), NOEX_WITH_SAFE(orig.nd_noex)); // was st_insert
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
          var name;
          var attriv;
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
          name = rb_id2name(id);
          if (!name) { rb_raise(rb_eArgError, "argument needs to be symbol or string"); }
          // removed string buf computation
          attriv = rb_intern('@' + name);
          if (read) { rb_add_method(klass, id, NEW_IVAR(attriv), noex); }
          if (write) { rb_add_method(klass, rb_id_attrset(id), NEW_ATTRSET(attriv), noex); }
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
          if (!klass) { rb_raise(rb_eNotImpError, "method `%s' called on terminated object (0x%lx)", rb_id2name(mid), recv); }
          /* is it in the method cache? */
          ent = cache[EXPR1(klass, mid)] || {}; // was "ent = cache + EXPR1(klass, mid)"
          if ((ent.mid == mid) && (ent.klass == klass)) {
            if (!ent.method) { return method_missing(recv, mid, argc, argv, scope == 2 ? CSTAT_VCALL : 0); }
            body  = ent.method;
            klass = ent.origin;
            id    = ent.mid0;
            noex  = ent.noex;
          } else {
            var tmp = rb_get_method_body(klass, id, noex); // ff. was "body = rb_get_method_body(&klass, &id, &noex)"
            body  = tmp[0];
            klass = tmp[1];
            id    = tmp[2];
            noex  = tmp[3];
            if (body === 0) {
              if (scope == 3) { return method_missing(recv, mid, argc, argv, CSTAT_SUPER); }
              console.log(klass, recv, mid, argc, argv, scope, self);
              throw('fail in method_missing');
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
      add_function :rb_raise, :call_cfunc
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
        //removed GC "tick" process
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
          
          var _iter = {}; // ff. was PUSH_ITER(itr)
          _iter.prev = ruby_iter;
          _iter.iter = itr;
          ruby_iter = _iter; // ^^
          
          var _frame = {}; // ff. was PUSH_FRAME
          _frame.prev  = ruby_frame;
          _frame.tmp   = 0;
          _frame.node  = ruby_current_node;
          _frame.iter  = ruby_iter.iter;
          _frame.argc  = 0;
          _frame.flags = 0;
          _frame.uniq  = frame_unique++;
          ruby_frame = _frame; // ^^
          ruby_frame.last_func = id;
          ruby_frame.orig_func = oid;
          ruby_frame.last_class = (flags & NOEX_NOSUPER) ? 0 : klass;
          ruby_frame.self = recv;
          ruby_frame.argc = argc;
          ruby_frame.flags = 0;
          
          switch(nd_type(body)) {
            case NODE_CFUNC:
              // removed bug warning
              // removed event hooks handler
              result = call_cfunc(body.nd_cfnc, recv, body.nd_argc, argc, argv);
              break;
              
            // skipped other types of nodes for now
            
            case NODE_SCOPE:
              var local_vars;
              var state = 0;
              var saved_cref = 0;
              
              var _vmode = scope_vmode; // ff. was PUSH_SCOPE
              var _scope = NEWOBJ();
              OBJSETUP(_scope, 0, T_SCOPE);
              _scope.local_tbl = 0;
              _scope.local_vars = 0;
              _scope.flags = 0;
              var _old = ruby_scope;
              ruby_scope = _scope;
              scope_vmode = SCOPE_PUBLIC; // ^^
              
              if (body.nd_rval) {
                saved_cref = ruby_cref;
                ruby_cref = body.nd_rval;
              }
              
              var _class = ruby_class; // ff. was PUSH_CLASS(ruby_cbase)
              ruby_class = ruby_cbase; // ^^
              
              if (body.nd_tbl) {
                local_vars = []; // was "local_vars = TMP_ALLOC(body->nd_tbl[0]+1)"
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
              
              var _old_vars = ruby_dyna_vars; // ff. was PUSH_VARS
              ruby_dyna_vars = 0; // ^^
              
              var _tag = {}; // ff. was PUSH_TAG(PROT_FUNC)
              _tag.retval = Qnil;
              _tag.frame = ruby_frame;
              _tag.iter = ruby_iter;
              _tag.prev = prot_tag;
              _tag.scope = ruby_scope;
              _tag.tag = PROT_FUNC;
              _tag.dst = 0;
              _tag.blkid = 0;
              prot_tag = _tag; // ^^
              
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
              prot_tag = _tag.prev; // was POP_TAG();
              if (_old_vars && (ruby_scope.flags & SCOPE_DONT_RECYCLE)) { // ff. was POP_VARS
                if (_old_vars.basic.flags) /* unless it's already recycled */ { FL_SET(_old_vars, DVAR_DONT_RECYCLE); }
              }
              ruby_dyna_vars = _old_vars; // ^^
              ruby_class = _class; // was POP_CLASS
              if (ruby_scope.flags & SCOPE_DONT_RECYCLE) { if (_old) { scope_dup(_old); } } // ff. was POP_SCOPE
              if (!(ruby_scope.flags & SCOPE_MALLOC)) {
                ruby_scope.local_vars = 0;
                ruby_scope.local_tbl  = 0;
              //if (!(ruby_scope.flags & SCOPE_DONT_RECYCLE) && ruby_scope != top_scope) { rb_gc_force_recycle(ruby_scope); }
              }
              ruby_scope.flags |= SCOPE_NOSTACK;
              ruby_scope = _old;
              scope_vmode = _vmode; // ^^
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
              console.log('unimplemented node type in rb_call: %x', nd_type(body));
          }
          ruby_current_node = _frame.node; // ff. was POP_FRAME
          ruby_frame = _frame.prev;
          ruby_iter = _iter.prev; // was POP_ITER
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
    
    # changed cache handling
    def rb_clear_cache_by_id
      <<-END
        function rb_clear_cache_by_id(id) {
          if (!ruby_running) { return; }
          for (var x in cache) { if (cache[x].mid == id) { cache[x].mid = 0; } }
        }
      END
    end
    
    # CHECK THIS; IT'S WEIRD
    def rb_copy_node_scope
      <<-END
        function rb_copy_node_scope(node, rval) {
          var copy = NEW_NODE(NODE_SCOPE, 0, rval, node.nd_next);
          if (node.nd_tbl) {
            copy.u1 = []; // was "copy->nd_tbl = ALLOC_N(ID, node->nd_tbl[0]+1)"
            copy.nd_tbl.zero = node.nd_tbl; // added... but why?
            MEMCPY(copy.nd_tbl, node.nd_tbl, node.nd_tbl.length); // was "MEMCPY(copy->nd_tbl, node->nd_tbl, ID, node->nd_tbl[0]+1)"
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
      add_function :return_value
      <<-END
        function rb_ensure(b_proc, data1, e_proc, data2) {
          var state;
          var result = Qnil;
          var retval;
          PUSH_TAG(PROT_NONE);
          try { // was EXEC_TAG
            result = b_proc(data1);
          } catch (x) {
            if (typeof(state = x) != "number") { throw(state); }
          }
          POP_TAG();
          retval = (prot_tag) ? prot_tag.retval : Qnil; /* save retval */
          e_proc(data2); // was "if (!thread_no_ensure()) { (*e_proc)(data2); }"
          if (prot_tag) { return_value(retval); }
          if (state) { JUMP_TAG(state); }
          return result;
        }
      END
    end
    
    # CHECK
    def rb_eval
      add_function :ev_const_get, :rb_dvar_ref, :block_pass, :rb_hash_new, :rb_hash_aset
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
                case NODE_BEGIN:
                  node = node.nd_body;
                  throw({ goto_flag: again_flag }); // was "goto again"

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
                  throw({ goto_flag: again_flag }); // was "goto again"

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
                    if (nd_type(node) != NODE_WHEN) { throw({ goto_flag: again_flag }); } // was "goto again"
                    tag = node.nd_head;
                    while (tag) {
                      // removed event hook
                      if (tag.nd_head && (nd_type(tag.nd_head) == NODE_WHEN)) {
                        var v = rb_eval(self, tag.nd_head.nd_head);
                        if (TYPE(v) != T_ARRAY) { v = rb_ary_to_ary(v); }
                        for (var i = 0, p = v.ptr, l = v.ptr.length; i < l; ++i) {
                          if (RTEST(rb_funcall2(p[i], eqq, 1, [val]))) { // changed &val to [val]
                            node = node.nd_body;
                            throw({ goto_flag: again_flag }); // was "goto again"
                          }
                        }
                        tag = tag.nd_next;
                        continue;
                      }
                      if (RTEST(rb_funcall2(rb_eval(self, tag.nd_head), eqq, 1, [val]))) { // changed &val to [val]
                        node = node.nd_body;
                        throw({ goto_flag: again_flag }); // was "goto again"
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
                    if ((data = klass.m_tbl[node.nd_mid])) {
                      body = data;
                      if (ruby_safe_level >= 4) { rb_raise(rb_eSecurityError, "redefining method prohibited"); }
                    }
                    var defn = rb_copy_node_scope(node.nd_defn, ruby_cref);
                    rb_add_method(klass, node.nd_mid, defn, NOEX_PUBLIC|(body?body.nd_noex&NOEX_UNDEF:0));
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
                    if (typeof(state = x) != "number") { throw(state); }
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

                case NODE_GASGN:
                  result = rb_eval(self, node.nd_value);
                  rb_gvar_set(node.nd_entry, result);
                  break;

                case NODE_GVAR:
                  result = rb_gvar_get(node.nd_entry);
                  break;

                case NODE_HASH:
                  var hash = rb_hash_new();
                  var ary = node.nd_head;
                  var key;
                  var val;

                  for (var i = 0, l = ary.length; i < l; ++i) {
                    key = rb_eval(self, ary[i]);
                    val = rb_eval(self, ary[++i]);
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
                  throw({ goto_flag: again_flag }); // was "goto again"

                // unwound "goto" architecture
                case NODE_ITER:
                case NODE_FOR:
                  PUSH_TAG(PROT_LOOP);
                  PUSH_BLOCK(node.nd_var, node.nd_body);
                  do { // added to handle "goto" architecture
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
                      if (typeof(state = x) != "number") { throw(state); }
                      if ((state == TAG_BREAK) && TAG_DST()) {
                        result = prot_tag.retval;
                        state = 0;
                      } else if (state == TAG_RETRY) {
                        state = 0;
                        goto_retry = 1;
                      }
                    }
                  } while (goto_retry); // added to handle "goto" architecture
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
                      if (typeof(state = x) != "number") { throw(state); }
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
                    throw({ goto_flag: again_flag }); // was "goto again"
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

                // unwound "goto" loop architecture
                case NODE_UNTIL:
                  PUSH_TAG(PROT_LOOP);
                  result = Qnil;
                  try { // was EXEC_TAG
                    if (!(node.nd_state && RTEST(rb_eval(self, node.nd_cond)))) {
                      do { rb_eval(self, node.nd_body); } while (!RTEST(rb_eval(self, node.nd_cond)));
                    }
                  } catch (x) {
                    if (typeof(state = x) != "number") { throw(state); }
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

                // unwound "goto" loop architecture
                case NODE_WHILE:
                  PUSH_TAG(PROT_LOOP);
                  result = Qnil;
                  try { // was EXEC_TAG
                    if (!(node.nd_state && !RTEST(rb_eval(self, node.nd_cond)))) {
                      do { rb_eval(self, node.nd_body); } while (RTEST(rb_eval(self, node.nd_cond)));
                    }
                  } catch (x) {
                    if (typeof(state = x) != "number") { throw(state); }
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
    
    # modified to return array including "pointers": [body, klassp, idp, noexp], changed cache handling
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
            ent = cache[EXPR1(klass, id)] = {}; // was "ent = cache + EXPR1(klass, id)"
            ent.klass = klass;
            ent.origin = klass;
            ent.mid = ent.mid0 = id;
            ent.noex = 0;
            ent.method = 0;
            return [0,klassp,idp,noexp];
          }
          if (ruby_running) {
            /* store in cache */
            ent = cache[EXPR1(klass, id)] = {}; // was "ent = cache + EXPR1(klass, id)"
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
          // removed "debug" section
          // removed "trap mask" call
          // removed event hook
          if (!prot_tag) { error_print(); }
          // removed thread handler
          JUMP_TAG(tag);
        }
      END
    end
    
    # unwound "goto" architecture
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
              // removed "goto exception_call" and duplicated code here
              exception = rb_intern("exception"); 
              if (!rb_respond_to(argv[0], exception)) { rb_raise(rb_eTypeError, "exception class/object expected"); }
              mesg = rb_funcall(argv[0], exception, n, argv[1]);
              break;
            case 2:
            case 3:
              n = 1;
              exception = rb_intern("exception");
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
          ent = cache[EXPR1(klass, id)] || {}; // was "ent = cache + EXPR1(klass, id)"
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
      add_function :rb_yield0
      <<-END
        function rb_yield(val) {
          return rb_yield_0(val, 0, 0, 0, Qfalse);
        }
      END
    end
    
    # CHECK
    def rb_yield0
      add_function :rb_need_block, :new_dvar, :rb_raise, :svalue_to_mrhs, :massign, :assign,
                   :rb_ary_new3, :svalue_to_avalue, :avalue_to_svalue, :rb_block_proc,
                   :rb_eval, :scope_dup, :proc_jump_error
      <<-END
        // unwound "goto" architecture, eliminated GC handlers
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
              do { // added to handled "goto block_var"
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
                } else { // unwound local "goto" architecture
                  var len = 0;
                  if (avalue) {
                    len = val.ptr.length;
                    if (len == 0) {
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
              } while (goto_block_var); // added to handled "goto block_var"
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
            do { // added to handle "goto redo"
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
            } while (goto_redo); // added to handle "goto redo"
            POP_TAG();
            POP_ITER();
          } // added to handle "goto pop_state"
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
            vars = []; // was "vars = ALLOC_N(VALUE, tbl[0]+1)"
            vars.zero = scope.local_vars.zero; // added... but why?
            MEMCPY(vars, scope.local_vars, tbl[0]); // IS THE [0] OF A LOCAL TBL ITS LENGTH?
            scope.local_vars = vars;
            scope.flags |= SCOPE_MALLOC;
          }
        }
      END
    end
    
    # modified to return array including "*origin": [body, origin]
    def search_method
      <<-END
        function search_method(klass, id, origin) {
          var body;
          if (!klass) { return [0,origin]; } // returning array
          while (!(body = klass.m_tbl[id])) { // was st_lookup
            klass = klass.superclass;
            if (!klass) { return [0,origin]; }
          }
          origin = klass;
          return [body, origin]; // returning array
        }
      END
    end
    
    # verbatim
    def set_backtrace
      add_function :rb_funcall, :rb_intern
      add_method :set_backtrace
      <<-END
        function set_backtrace(info, bt) {
          rb_funcall(info, rb_intern("set_backtrace"), 1, bt);
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
    
    # modified to use jsprintf instead of va_args
    def warn_printf
      add_function :jsprintf, :rb_write_error
      <<-END
        function warn_printf(fmt) {
          for (var i = 1, ary = []; typeof(arguments[i]) != 'undefined'; ++i) { ary.push(arguments[i]); }
          var buf = jsprintf(fmt,ary);
          rb_write_error(buf);
        }
      END
    end
  end
  
  module Exception
    # verbatim
    def exc_backtrace
      add_function :rb_attr_get, :rb_intern
      <<-END
        function exc_backtrace(exc) {
          return rb_attr_get(exc, rb_intern("bt"));
        }
      END
    end
    
    # verbatim
    def exc_exception
      add_function :rb_obj_clone, :exc_initialize
      <<-END
        function exc_exception(argc, argv, self) {
          var exc;
          if (argc === 0) { return self; }
          if ((argc == 1) && (self == argv[0])) { return self; }
          exc = rb_obj_clone(self);
          exc_initialize(argc, argv, exc);
          return exc;
        }
      END
    end
    
    # expanded rb_scan_args
    def exc_initialize
      add_function :rb_scan_args, :rb_iv_set
      <<-END
        function exc_initialize(argc, argv, exc) {
          var tmp = rb_scan_args(argc, argv, "01", true);
          var arg = tmp[1];
          rb_iv_set(exc, 'mesg', arg);
          rb_iv_set(exc, 'bt', Qnil);
          return exc;
        }
      END
    end
    
    # EMPTY
    def exc_inspect
      <<-END
        function exc_inspect() {}
      END
    end
    
    # verbatim
    def exc_set_backtrace
      add_function :rb_iv_set, :rb_check_backtrace
      <<-END
        function exc_set_backtrace(exc, bt) {
          return rb_iv_set(exc, "bt", rb_check_backtrace(bt));
        }
      END
    end
    
    # verbatim
    def exc_to_s
      add_functions :rb_attr_get, :rb_class_name
      <<-END
        function exc_to_s(exc) {
          var mesg = rb_attr_get(exc, rb_intern("mesg"));
          if (NIL_P(mesg)) { return rb_class_name(CLASS_OF(exc)); }
          if (OBJ_TAINTED(exc)) { OBJ_TAINT(mesg); }
          return mesg;
        }
      END
    end
    
    # verbatim
    def exc_to_str
      add_function :rb_funcall
      add_method :to_s
      <<-END
        function exc_to_str(exc) {
          return rb_funcall(exc, rb_intern("to_s"), 0, 0);
        }
      END
    end
    
    # EMPTY
    def exit_initialize
      <<-END
        function exit_initialize() {}
      END
    end
    
    # CHECK
    def name_err_initialize
      add_function :rb_call_super, :rb_iv_set
      <<-END
        function name_err_initialize(argc, argv, self) {
          var name = argc > 1 ? argv[--argc] : Qnil;
          rb_call_super(argc, argv);
          rb_iv_set(self, 'name', name);
          return self;
        }
      END
    end
    
    # unpacked Data_Wrap_Struct
    def name_err_mesg_new
      add_function :rb_data_object_alloc
      <<-END
        function name_err_mesg_new(obj, mesg, recv, method) {
          var ptr = [mesg, recv, method];
          rb_data_object_alloc(rb_cNameErrorMesg, ptr);
        }
      END
    end
    
    # EMPTY
    def name_err_mesg_to_str
      <<-END
        function name_err_mesg_to_str() {}
      END
    end
    
    # EMPTY
    def name_err_to_s
      <<-END
        function name_err_to_s() {}
      END
    end
    
    # CHECK
    def nometh_err_initialize
      add_function :name_err_initialize, :rb_iv_set
      <<-END
        function nometh_err_initialize(argc, argv, self) {
          var args = (argc < 2) ? argv[--argc] : Qnil;
          name_err_initialize(argc, argv, self);
          rb_iv_set(self, 'args', args);
          return self;
        }
      END
    end
    
    # verbatim
    def rb_check_backtrace
      add_functions :rb_ary_new3, :rb_raise
      <<-END
        function rb_check_backtrace(bt) {
          var err = "backtrace must be Array of String";
          if (!NIL_P(bt)) {
            var t = TYPE(bt);
            if (t == T_STRING) { return rb_ary_new3(1, bt); }
            if (t != T_ARRAY) { rb_raise(rb_eTypeError, err); }
            for (var i = 0, p = bt.ptr, l = p.length; i < l; ++i) {
              if (TYPE(p[i]) != T_STRING) { rb_raise(rb_eTypeError, err); }
            }
          }
          return bt;
        }
      END
    end
    
    # verbatim
    def rb_check_frozen
      add_functions :rb_error_frozen, :rb_obj_classname
      <<-END
        function rb_check_frozen(obj) {
          if (OBJ_FROZEN(obj)) { rb_error_frozen(rb_obj_classname(obj)); }
        }
      END
    end
    
    # removed bug warning for unknown type
    def rb_check_type
      add_functions :rb_special_const_p, :rb_obj_classname, :rb_raise
      <<-END
        function rb_check_type(x, t) {
          // removed bug warning
          if (TYPE(x) != t) {
            if (builtin_types[t]) {
              var etype;
              if (NIL_P(x)) { etype = "nil"; } else
              if (FIXNUM_P(x)) { etype = "Fixnum"; } else
              if (SYMBOL_P(x)) { etype = "Symbol"; } else
              if (rb_special_const_p(x)) { etype = rb_obj_as_string(x).ptr; } else { etype = rb_obj_classname(x); }
              rb_raise(rb_eTypeError, "wrong argument type %s (expected %s)", etype, builtin_types[t]);
            }
            // removed bug warning
          }
        }
      END
    end
    
    def rb_error_frozen
      add_function :rb_raise
      <<-END
        function rb_error_frozen(what) {
          rb_raise(rb_eTypeError, "can't modify frozen %s", what);
        }
      END
    end
    
    # CHECK
    def rb_exc_new
      add_function :rb_exc_new, :rb_funcall, :rb_str_new
      add_method :new
      <<-END
        function rb_exc_new(etype, ptr) {
          return rb_funcall(etype, rb_intern('new'), 1, rb_str_new(ptr));
        }
      END
    end
    
    # CHECK CHECK CHECK
    def rb_exc_new3
      add_function :rb_funcall
      add_method :new
      <<-END
        function rb_exc_new3(etype, str) {
        //StringValue(str);
          return rb_funcall(etype, rb_intern("new"), 1, str);
        }
      END
    end
    
    # CHECK
    def rb_exc_raise
      add_function :rb_longjmp
      <<-END
        function rb_exc_raise(mesg) {
          rb_longjmp(TAG_RAISE, mesg);
        }
      END
    end
    
    # CHECK
    def rb_raise
      add_function :rb_exc_raise, :rb_exc_new, :jsprintf
      <<-END
        function rb_raise(exc, fmt) {
          for (var i = 2, ary = []; typeof(arguments[i]) != 'undefined'; ++i) { ary.push(arguments[i]); }
          var buf = jsprintf(fmt,ary);
          rb_exc_raise(rb_exc_new(exc, buf));
        }
      END
    end
    
    # EMPTY
    def syserr_initialize
      <<-END
        function syserr_initialize() {}
      END
    end
  end
  
  module False
    # changed rb_str_new2 to rb_str_new
    def false_to_s
      add_functions :rb_str_new
      <<-END
        function false_to_s(obj) {
          return rb_str_new('false');
        }
      END
    end
    
    # verbatim
    def false_and
      <<-END
        function false_and(obj1, obj2) {
          return Qfalse;
        }
      END
    end
    
    # verbatim
    def false_or
      <<-END
        function false_or(obj1, obj2) {
          return RTEST(obj2) ? Qtrue : Qfalse;
        }
      END
    end
    
    # verbatim
    def false_xor
      <<-END
        function false_xor(obj1, obj2) {
          return RTEST(obj2) ? Qtrue : Qfalse;
        }
      END
    end
  end
  
  module Fixnum
    # CHECK
    def fix_cmp
      add_function :rb_num_coerce_cmp
      <<-END
        function fix_cmp(x, y) {
          if (x == y) return INT2FIX(0);
          if (FIXNUM_P(y)) {
            if (FIX2LONG(x) > FIX2LONG(y)) { return INT2FIX(1); }
            return INT2FIX(-1);
          } else {
            return rb_num_coerce_cmp(x, y);
          }
        }
      END
    end
    
    # CHECK
    def fix_equal
      add_function :num_equal
      <<-END
        function fix_equal(x, y) {
          if (x == y) { return Qtrue; }
          if (FIXNUM_P(y)) { return Qfalse; }
          return num_equal(x, y);
        }
      END
    end
    
    # CHECK
    def fix_even_p
      <<-END
        function fix_even_p(num) {
          return (num & 2) ? Qfalse : Qtrue;
        }
      END
    end
    
    # CHECK
    def fix_ge
      add_function :rb_num_coerce_relop
      <<-END
        function fix_ge(x, y) {
          if (FIXNUM_P(y)) {
            if (FIX2LONG(x) >= FIX2LONG(y)) { return Qtrue; }
            return Qfalse;
          } else {
            return rb_num_coerce_relop(x, y);
          }
        }
      END
    end
    
    # CHECK
    def fix_gt
      add_function :rb_num_coerce_relop
      <<-END
        function fix_gt(x, y) {
          if (FIXNUM_P(y)) {
            if (FIX2LONG(x) > FIX2LONG(y)) { return Qtrue; }
            return Qfalse;
          } else {
            return rb_num_coerce_relop(x, y);
          }
        }
      END
    end
    
    # CHECK
    def fix_le
      add_function :rb_num_coerce_relop
      <<-END
        function fix_le(x, y) {
          if (FIXNUM_P(y)) {
            if (FIX2LONG(x) <= FIX2LONG(y)) { return Qtrue; }
            return Qfalse;
          } else {
            return rb_num_coerce_relop(x, y);
          }
        }
      END
    end
    
    # CHECK
    def fix_lt
      add_function :rb_num_coerce_relop
      <<-END
        function fix_lt(x, y) {
          if (FIXNUM_P(y)) {
            if (FIX2LONG(x) < FIX2LONG(y)) { return Qtrue; }
            return Qfalse;
          } else {
            return rb_num_coerce_relop(x, y);
          }
        }
      END
    end
    
    # CHECK
    def fix_minus
      add_function :rb_float_new, :rb_num_coerce_bin
      <<-END
        function fix_minus(x, y) {
          if (FIXNUM_P(y)) { return LONG2NUM(FIX2LONG(x) - FIX2LONG(y)); }
          if (TYPE(y) == T_FLOAT) { return rb_float_new(FIX2LONG(x) - y.value); }
          return rb_num_coerce_bin(x, y);
        }
      END
    end
    
    # CHECK
    def fix_odd_p
      <<-END
        function fix_odd_p(num) {
          return (num & 2) ? Qtrue : Qfalse;
        }
      END
    end
    
    # CHECK
    def fix_plus
      add_function :rb_float_new, :rb_num_coerce_bin
      <<-END
        function fix_plus(x, y) { 
          if (FIXNUM_P(y)) { return LONG2NUM(FIX2LONG(x) + FIX2LONG(y)); }
          if (TYPE(y) == T_FLOAT) { return rb_float_new(FIX2LONG(x) + y.value); }
          return rb_num_coerce_bin(x, y);
        }
      END
    end
    
    # CHECK
    def fix_to_s
      add_functions :rb_scan_args, :rb_fix2str
      <<-END
        function fix_to_s(argc, argv, x) {
          var b = rb_scan_args(argc, argv, "01")[0];
          var base = (argc === 0) ? 10 : NUM2INT(b);
          return rb_fix2str(x, base);
        }
      END
    end
    
    # verbatim
    def fix_uminus
      <<-END
        function fix_uminus(num) {
          return LONG2NUM(-FIX2LONG(num));
        }
      END
    end
    
    # CHECK
    def fix_zero_p
      <<-END
        function fix_zero_p(num) {
          return (FIX2LONG(num) === 0) ? Qtrue : Qfalse
        }
      END
    end
    
    # CHECK
    def rb_fix2str
      add_function :rb_raise, :rb_str_new
      <<-END
        function rb_fix2str(x, base) {
          if (base < 2 || 36 < base) { rb_raise(rb_eArgError, "illegal radix %d", base); }
          return rb_str_new(FIX2LONG(x).toString(base));
        }
      END
    end
    
    # CHECK
    def rb_fix_new
      <<-END
        function rb_fix_new(v) {
          return INT2FIX(i);
        }
      END
    end
  end
  
  module Float
    # EMPTY
    def flo_eq
      <<-END
        function flo_eq() {}
      END
    end
    
    # EMPTY
    def flo_to_s
      <<-END
        function flo_to_s() {}
      END
    end
  end
  
  module Hash
    # CHECK
    def hash_alloc
      add_function :hash_alloc0
      <<-END
        function hash_alloc(klass) {
          var hash = hash_alloc0(klass);
          hash.tbl = {};
          return hash;
        }
      END
    end
    
    # CHECK
    def hash_alloc0
      <<-END
        function hash_alloc0(klass) {
          var hash = { ifnone: Qnil, val: last_value += 4 };
          OBJSETUP(hash, klass, T_HASH);
          return hash;
        }
      END
    end
    
    # CHECK
    def hash_foreach_ensure
      add_function :st_cleanup_safe
      <<-END
        function hash_foreach_ensure(hash) {
          RHASH(hash).iter_lev--;
          if (RHASH(hash).iter_lev === 0) {
            if (FL_TEST(hash, HASH_DELETED)) {
              st_cleanup_safe(RHASH(hash).tbl, Qundef);
              FL_UNSET(hash, HASH_DELETED);
            }
          }
          return 0;
        }
      END
    end
    
    # CHECK
    def hash_foreach_iter
      add_function :rb_raise, :st_delete_safe
      <<-END
        function hash_foreach_iter(key, value, arg) {
          var status;
          var tbl;
          tbl = RHASH(arg.hash).tbl;
          if (key == Qundef) { return ST_CONTINUE; }
          status = arg.func(key, value, arg.arg);
          if (RHASH(arg.hash).tbl != tbl) { rb_raise(rb_eRuntimeError, "rehash occurred during iteration"); }
          switch (status) {
            case ST_DELETE:
              st_delete_safe(tbl, key, 0, Qundef);
              FL_SET(arg.hash, HASH_DELETED);
            case ST_CONTINUE:
              break;
            case ST_STOP:
              return ST_STOP;
          }
          return ST_CHECK;
        }
      END
    end
    
    # CHECK
    def rb_hash_aref
      add_function :rb_funcall
      add_method :default
      <<-END
        function rb_hash_aref(hash, key) {
          var val;
          if (!(val = hash.tbl[key])) {
            return rb_funcall(hash, id_default, 1, key);
          }
          return val;
        }
      END
    end
    
    # CHECK
    def rb_hash_aset
      add_function :rb_hash_modify, :rb_str_new4
      <<-END
        function rb_hash_aset(hash, key, val) {
        //rb_hash_modify(hash);
          if (TYPE(key) != T_STRING || hash.tbl[key]) {
            hash.tbl[key] = val;
          } else {
            hash.tbl[rb_str_new4(key)] = val;
          }
          return val;
        }
      END
    end
    
    # expanded rb_scan_args
    def rb_hash_default
      add_function :rb_scan_args, :rb_funcall
      add_method :call
      <<-END
        function rb_hash_default(argc, argv, hash) {
          var tmp = rb_scan_args(argc, argv, "01");
          var key = tmp[1];
          if (FL_TEST(hash, HASH_PROC_DEFAULT)) {
            if (argc === 0) { return Qnil; }
            return rb_funcall(hash.ifnone, id_call, 2, hash, key);
          }
          return hash.ifnone;
        }
      END
    end
    
    # verbatim
    def rb_hash_equal
      add_function :hash_equal
      <<-END
        function rb_hash_equal(hash1, hash2) {
          return hash_equal(hash1, hash2, Qfalse);
        }
      END
    end
    
    # CHECK
    def rb_hash_foreach
      add_function :rb_ensure, :hash_foreach_call, :hash_foreach_ensure
      <<-END
        function rb_hash_foreach(hash, func, farg) {
          var arg = {};
          RHASH(hash).iter_lev++;
          arg.hash = hash;
          arg.func = func;
          arg.arg  = farg;
          rb_ensure(hash_foreach_call, arg, hash_foreach_ensure, hash);
        }
      END
    end
    
    # CHECK
    def rb_hash_foreach_call
      add_function :st_foreach, :hash_foreach_iter, :rb_raise
      <<-END
        function rb_hash_foreach_call(arg) {
          if (st_foreach(RHASH(arg.hash).tbl, hash_foreach_iter, arg)) { rb_raise(rb_eRuntimeError, "hash modified during iteration"); }
          return Qnil;
        }
      END
    end
    
    # CHECK
    def rb_hash_has_key
      <<-END
        function rb_hash_has_key(hash, key) {
          if (typeof(RHASH(hash).tbl[key]) == 'undefined') { return Qfalse; }
          return Qtrue;
        }
      END
    end
    
    # CHECK
    def rb_hash_has_value
      add_function :rb_hash_foreach, :rb_hash_search_value
      <<-END
        function rb_hash_has_value(hash, val) {
          var data = [Qfalse, val];
          rb_hash_foreach(hash, rb_hash_search_value, data);
          return data[0];
        }
      END
    end
    
    # expanded rb_scan_args
    def rb_hash_initialize
      add_function :rb_hash_modify, :rb_block_given_p, :rb_raise, :rb_block_proc, :rb_scan_args
      <<-END
        function rb_hash_initialize(argc, argv, hash) {
          var ifnone;
        //rb_hash_modify(hash);
          if (rb_block_given_p()) {
            if (argc > 0) { rb_raise(rb_eArgError, "wrong number of arguments"); }
            hash.ifnone = rb_block_proc();
            FL_SET(hash, HASH_PROC_DEFAULT);
          } else {
            var tmp = rb_scan_args(argc, argv, "01");
            ifnone = tmp[1];
            hash.ifnone = ifnone;
          }
          return hash;
        }
      END
    end
    
    # CHECK
    def rb_hash_inspect
      add_function :rb_str_new, :rb_inspecting_p, :rb_protect_inspect, :inspect_hash
      <<-END
        function rb_hash_inspect(hash) {
          if (hash.tbl === 0 || hash.tbl.length === 0) { return rb_str_new("{}"); }
          if (rb_inspecting_p(hash)) { return rb_str_new("{...}"); }
          return rb_protect_inspect(inspect_hash, hash, 0);
        }
      END
    end
    
    # CHECK
    def rb_hash_new
      add_function :hash_alloc
      <<-END
        function rb_hash_new() {
          return hash_alloc(rb_cHash);
        }
      END
    end
    
    # verbatim
    def rb_hash_replace
      add_function :to_hash, :rb_hash_clear, :rb_hash_foreach, :replace_i
      <<-END
        function rb_hash_replace(hash, hash2) {
          hash2 = to_hash(hash2);
          if (hash == hash2) { return hash; }
          rb_hash_clear(hash);
          rb_hash_foreach(hash2, replace_i, hash);
          hash.ifnone = hash2.ifnone;
          if (FL_TEST(hash2, HASH_PROC_DEFAULT)) {
            FL_SET(hash, HASH_PROC_DEFAULT);
          } else {
            FL_UNSET(hash, HASH_PROC_DEFAULT);
          }
          return hash;
        }
      END
    end
    
    # CHECK
    def rb_hash_s_create
      add_function :rb_check_convert_type, :hash_alloc0, :rb_check_array_type, :hash_alloc,
                   :rb_hash_aset, :rb_raise
      <<-END
        function rb_hash_s_create(argc, argv, klass) {
          var hash;
          var tmp;
          var i;
          if (argc == 1) {
            tmp = rb_check_convert_type(argv[0], T_HASH, "Hash", "to_hash");
            if (!NIL_P(tmp)) {
              hash = hash_alloc0(klass);
              RHASH(hash).tbl = RHASH(tmp).tbl;
              return hash;
            }
            tmp = rb_check_array_type(argv[0]);
            if (!NIL_P(tmp)) {
              hash = hash_alloc(klass);
              for (i = 0; i < RARRAY_LEN(tmp); ++i) {
                var v = rb_check_array_type(RARRAY_PTR(tmp)[i]);
                if (NIL_P(v)) { continue; }
                if (RARRAY_LEN(v) < 1 || 2 < RARRAY_LEN(v)) { continue; }
                rb_hash_aset(hash, RARRAY_PTR(v)[0], RARRAY_PTR(v)[1]);
              }
              return hash;
            }
          }
          if (argc % 2 != 0) { rb_raise(rb_eArgError, "odd number of arguments for Hash"); }
          hash = hash_alloc(klass);
          for (i = 0; i < argc; i += 2) {
            rb_hash_aset(hash, argv[i], argv[i + 1]);
          }
          return hash;
        }
      END
    end
    
    # CHECK
    def rb_hash_to_a
      add_function :rb_hash_foreach, :to_a_i
      <<-END
        function rb_hash_to_a(hash) {
          var ary = rb_ary_new();
          rb_hash_foreach(hash, to_a_i, ary);
          if (OBJ_TAINTED(hash)) { OBJ_TAINT(ary); }
          return ary;
        }
      END
    end
    
    # CHECK
    def rb_hash_to_hash
      <<-END
        function rb_hash_to_hash(hash) {
          return hash;
        }
      END
    end
    
    # CHECK
    def rb_hash_to_s
      add_functions :rb_inspecting_p, :rb_str_new, :rb_protect_inspect, :to_s_hash
      <<-END
        function rb_hash_to_s(hash) {
          if (rb_inspecting_p(hash)) { return rb_str_new("{...}"); };
          return rb_protect_inspect(to_s_hash, hash, 0);
        }
      END
    end
    
    # CHECK THIS ST_CONTINUE STUFF
    def to_a_i
      add_function :rb_ary_push, :rb_assoc_new
      <<-END
        function to_a_i(key, value, ary) {
          if (key == Qundef) { return ST_CONTINUE; }
          rb_ary_push(ary, rb_assoc_new(key, value));
          return ST_CONTINUE;
        }
      END
    end
    
    # verbatim
    def to_hash
      add_function :rb_convert_type
      <<-END
        function to_hash(hash) {
          return rb_convert_type(hash, T_HASH, "Hash", "to_hash");
        }
      END
    end
    
    # verbatim
    def to_s_hash
      add_function :rb_ary_to_s, :rb_hash_to_a
      <<-END
        function to_s_hash(hash) {
          return rb_ary_to_s(rb_hash_to_a(hash));
        }
      END
    end
  end
  
  module Integer
    # CHECK
    def int_dotimes
      add_function :rb_yield, :rb_funcall
      add_method :<, :+
      <<-END
        function int_dotimes(num) {
          RETURN_ENUMERATOR(num, 0, 0);
          if (FIXNUM_P(num)) {
            var end = FIX2LONG(num);
            for (var i = 0; i < end; i++) { rb_yield(LONG2FIX(i)); }
          } else {
            var i = INT2FIX(0);
            for (;;) {
              if (!RTEST(rb_funcall(i, '<', 1, num))) { break; }
              rb_yield(i);
              i = rb_funcall(i, '+', 1, INT2FIX(1));
            }
          }
          return num;
        }
      END
    end
    
    # CHECK
    def rb_int_new
      add_function :rb_int2inum
      <<-END
        function rb_int_new(v) {
          return rb_int2inum(v);
        }
      END
    end
    
    # CHECK
    def rb_int2inum
      add_function :rb_int2big
      <<-END
        function rb_int2inum(n) {
          if (FIXABLE(n)) { return LONG2FIX(n); }
          return rb_int2big(n);
        }
      END
    end
  end
  
  module IO
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
    
    # CHECK
    def io_write
      add_function :rb_obj_as_string
      <<-END
        function io_write(io, str) {
          var n;
          if (TYPE(str) != T_STRING) { str = rb_obj_as_string(str); }
          if (str.ptr.length == 0) { return INT2FIX(0); }
          n = str.ptr.length;
          CONSOLE_LOG_BUFFER += str.ptr;
        //return LONG2FIX(n);
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
                    :rb_obj_as_string, :rb_io_write
      <<-END
        function rb_io_puts(argc, argv, out) {
          var line;
          if (argc == 0) {
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
            if (line.ptr == '' || line.ptr[line.ptr.length - 1] != '\\n') {
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
    
    # merged rb_write_error and rb_write_error2 to eliminate "len", changed stderr to stdout
    def rb_write_error
      add_function :rb_io_write, :rb_str_new
      <<-END
        function rb_write_error(mesg) {
          rb_io_write(rb_stdout, rb_str_new(mesg));
        }
      END
    end
  end
  
  module Method
    # EMPTY
    def method_eq
      <<-END
        function method_eq() {}
      END
    end
    
    # EMPTY
    def method_inspect
      <<-END
        function method_inspect() {}
      END
    end
    
    # expanded Data_Make_Struct
    def mnew
      add_function :rb_get_method_body, :print_undef
      <<-END
        function mnew(klass, obj, id, mklass) {
          var method;
          var body;
          var noex;
          var data = {};
          var rklass = klass;
          var oid = id;
          do { // added to handle "goto again"
            var goto_again = 0;
            var tmp = rb_get_method_body(klass, id, noex);
            var body = tmp[0];
            var klass = tmp[1];
            var id = tmp[2];
            var noex = tmp[3];
            if (body === 0) { print_undef(rklass, oid); }
            if (nd_type(body) == NODE_ZSUPER) {
              klass = klass.superclass;
              goto_again = 1;
            }
          } while (goto_again); // added to handle "goto again"
          while ((rklass != klass) && (FL_TEST(rklass, FL_SINGLETON) || (TYPE(rklass) == T_ICLASS))) {
            rklass = rklass.superclass;
          }
          if (TYPE(klass) == T_ICLASS) { klass = klass.klass; }
          var method = NEWOBJ(); // was Data_Make_Struct
          OBJSETUP(method, mklass, T_DATA);
          method.data = {
            klass: klass,
            recv: obj,
            id: id,
            body: body,
            rklass: rklass,
            oid: oid,
            safe_level: NOEX_WITH_SAFE(noex)
          };
          OBJ_INFECT(method, klass);
          return method;
        }
      END
    end
  end
  
  module Module
    # verbatim
    def rb_mod_append_features
      add_function :rb_include_module, :rb_check_type
      <<-END
        function rb_mod_append_features(module, include) {
          switch (TYPE(include)) {
            case T_CLASS:
            case T_MODULE:
              break;
            default:
              Check_Type(include, T_CLASS);
              break;
          }
          rb_include_module(include, module);
          return module;
        }
      END
    end
    
    # verbatim
    def rb_mod_attr_accessor
      add_function :rb_attr, :rb_to_id
      <<-END
        function rb_mod_attr_accessor(argc, argv, klass) {
          for (var i = 0; i < argc; ++i) { rb_attr(klass, rb_to_id(argv[i]), 1, 1, Qtrue); }
          return Qnil;
        }
      END
    end
    
    # verbatim
    def rb_mod_attr_reader
      add_function :rb_attr, :rb_to_id
      <<-END
        function rb_mod_attr_reader(argc, argv, klass) {
          for (var i = 0; i < argc; ++i) { rb_attr(klass, rb_to_id(argv[i]), 1, 0, Qtrue); }
          return Qnil;
        }
      END
    end
    
    # verbatim
    def rb_mod_attr_writer
      add_function :rb_attr, :rb_to_id
      <<-END
        function rb_mod_attr_writer(argc, argv, klass) {
          for (var i = 0; i < argc; ++i) { rb_attr(klass, rb_to_id(argv[i]), 0, 1, Qtrue); }
          return Qnil;
        }
      END
    end
    
    # verbatim
    def rb_mod_eqq
      add_function :rb_obj_is_kind_of
      <<-END
        function rb_mod_eqq(mod, arg) {
          return rb_obj_is_kind_of(arg, mod);
        }
      END
    end
    
    # verbatim
    def rb_mod_include
      add_function :rb_check_type, :rb_funcall
      add_methods :append_features, :included
      <<-END
        function rb_mod_include(argc, argv, module) {
          for (var i = 0; i < argc; ++i) { Check_Type(argv[i], T_MODULE); }
          while (argc--) {
            rb_funcall(argv[argc], rb_intern("append_features"), 1, module);
            rb_funcall(argv[argc], rb_intern("included"), 1, module);
          }
          return module;
        }
      END
    end
    
    # INCOMPLETE -- CHECK ON ST FUNCTIONS
    def rb_mod_init_copy
      add_function :rb_obj_init_copy, :rb_singleton_class_clone, :clone_method
      <<-END
        function rb_mod_init_copy(clone, orig) {
          console.log('check on st_functions in rb_mod_init_copy');
          rb_obj_init_copy(clone, orig);
          if (!FL_TEST(CLASS_OF(clone), FL_SINGLETON)) {
            clone.basic.klass = orig.basic.klass;
            clone.basic.klass = rb_singleton_class_clone(clone);
          }
          clone.superclass = orig.superclass;
          if (orig.iv_tbl) {
            var id;
          //clone.iv_tbl = st_copy(RCLASS(orig)->iv_tbl);
            id = rb_intern("__classpath__");
          //st_delete(clone.iv_tbl, (st_data_t*)&id, 0);
            id = rb_intern("__classid__");
          //st_delete(clone.iv_tbl, (st_data_t*)&id, 0);
          }
          if (orig.m_tbl) {
            var data;
            data.tbl = clone.m_tbl = {}; // was st_init_numtable()
            data.klass = clone;
          //st_foreach(orig.m_tbl, clone_method, (st_data_t)&data);
          }
          return clone;
        }
      END
    end
    
    # verbatim
    def rb_mod_initialize
      add_function :rb_block_given_p, :rb_mod_module_eval
      <<-END
        function rb_mod_initialize(module) {
          if (rb_block_given_p()) { rb_mod_module_eval(0, 0, module); }
          return Qnil;
        }
      END
    end
    
    # verbatim
    def rb_mod_method
      add_function :rb_to_id, :mnew
      <<-END
        function rb_mod_method(mod, vid) {
          return mnew(mod, Qundef, rb_to_id(vid), rb_cUnboundMethod);
        }
      END
    end
    
    # CHECK
    def rb_mod_to_s
      add_function :rb_str_new, :rb_iv_get, :rb_str_cat, :rb_str_append,
                   :rb_inspect, :rb_str_dup, :rb_any_to_s, :rb_class_name
      <<-END
        function rb_mod_to_s(klass) {
          if (FL_TEST(klass, FL_SINGLETON)) {
            var s = rb_str_new("#<"); // changed from rb_str_new2
            var v = rb_iv_get(klass, "__attached__");
            rb_str_cat(s, "Class:"); // changed from rb_str_cat2
            switch (TYPE(v)) {
              case T_CLASS:
              case T_MODULE:
                rb_str_append(s, rb_inspect(v));
                break;
              default:
                rb_str_append(s, rb_any_to_s(v));
                break;
            }
            rb_str_cat(s, ">"); // changed from rb_str_cat2
            return s;
          }
          return rb_str_dup(rb_class_name(klass));
        }
      END
    end
  end
  
  module Nil
    # changed rb_str_new2 to rb_str_new
    def nil_inspect
      add_function :rb_str_new
      <<-END
        function nil_inspect(obj) {
          return rb_str_new("nil");
        }
      END
    end
    
    # verbatim
    def nil_to_f
      add_function :rb_float_new
      <<-END
        function nil_to_f(obj) {
          return rb_float_new(0.0);
        }
      END
    end
    
    # verbatim
    def nil_to_i
      <<-END
        function nil_to_i(obj) {
          return INT2FIX(0);
        }
      END
    end
    
    # changed rb_str_new2 to rb_str_new
    def nil_to_s
      add_function :rb_str_new
      <<-END
        function nil_to_s(obj) {
          return rb_str_new("");
        }
      END
    end
    
    # changed rb_ary_new2 to rb_ary_new
    def nil_to_a
      add_function :rb_ary_new
      <<-END
        function nil_to_a(obj) {
          return rb_ary_new();
        }
      END
    end
  end
  
  module Node
    # reduced nesting of "union" slots,
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
  end
  
  module Numeric
    # verbatim
    def num_init_copy
      add_function :rb_raise, :rb_obj_classname
      <<-END
        function num_init_copy(x, y) {
          /* Numerics are immutable values, which should not be copied */
          rb_raise(rb_eTypeError, "can't copy %s", rb_obj_classname(x));
          return Qnil; /* not reached */
        }
      END
    end
    
    # verbatim
    def num_sadded
      add_function :rb_raise, :rb_id2name, :rb_to_id, :rb_obj_classname
      <<-END
        function num_sadded(x, name) {
          ruby_frame = ruby_frame.prev; /* pop frame for "singleton_method_added" */
          /* Numerics should be values; singleton_methods should not be added to them */
          rb_raise(rb_eTypeError, "can't define singleton method '%s' for %s", rb_id2name(rb_to_id(name)), rb_obj_classname(x));
          return Qnil; /* not reached */
        }
      END
    end
  end
  
  module Object
    # verbatim
    def convert_type
      add_function :rb_intern, :rb_respond_to, :rb_raise, :rb_funcall
      <<-END
        function convert_type(val, tname, method, raise) {
          var m = rb_intern(method);
          if (!rb_respond_to(val, m)) {
            if (raise) {
              rb_raise(rb_eTypeError, "can't convert %s into %s", NIL_P(val) ? "nil" : val == Qtrue ? "true" : val == Qfalse ? "false" : rb_obj_classname(val), tname);
            } else {
              return Qnil;
            }
          }
          return rb_funcall(val, m, 0);
        }
      END
    end
    
    # removed st_free_table, removed bug warning
    def init_copy
      add_function :rb_raise, :rb_funcall, :rb_copy_generic_ivar
      add_method :initialize_copy
      <<-END
        function init_copy(dest, obj) {
        //if (OBJ_FROZEN(dest)) { rb_raise(rb_eTypeError, "[bug] frozen object (%s) allocated", rb_obj_classname(dest)); }
          dest.flags &= ~(T_MASK|FL_EXIVAR);
          dest.flags |= obj.basic.flags & (T_MASK|FL_EXIVAR|FL_TAINT);
          if (FL_TEST(obj, FL_EXIVAR)) { rb_copy_generic_ivar(dest, obj); }
        //rb_gc_copy_finalizer(dest, obj);
          switch (TYPE(obj)) {
            case T_OBJECT:
            case T_CLASS:
            case T_MODULE:
              if (dest.iv_tbl) { dest.iv_tbl = 0; } // removed st_free_table(ROBJECT(dest)->iv_tbl);
              if (obj.iv_tbl) { dest.iv_tbl = st_copy(obj.iv_tbl); }
          }
          rb_funcall(dest, id_init_copy, 1, obj);
        }
      END
    end
    
    # changed rb_str_new2 to rb_str_new
    def main_to_s
      add_function :rb_str_new
      <<-END
        function main_to_s(obj) {
          return rb_str_new("main");
        }
      END
    end
    
    # simplified string builder
    def rb_any_to_s
      add_function :rb_str_new, :rb_obj_classname
      <<-END
        function rb_any_to_s(obj) {
          var str = rb_str_new("#<" + rb_obj_classname(obj) + ":0x" + obj.rvalue.toString(16) + ">");
          if (OBJ_TAINTED(obj)) { OBJ_TAINT(str); }
          return str;
        }
      END
    end
    
    # verbatim
    def rb_check_convert_type
      add_function :convert_type, :rb_raise, :rb_obj_classname
      <<-END
        function rb_check_convert_type(val, type, tname, method) {
          /* always convert T_DATA */
          if ((TYPE(val) == type) && (type != T_DATA)) { return val; }
          var v = convert_type(val, tname, method, Qfalse);
          if (NIL_P(v)) { return Qnil; }
          if (TYPE(v) != type) { rb_raise(rb_eTypeError, "%s#%s should return %s", rb_obj_classname(val), method, tname); }
          return v;
        }
      END
    end
    
    # verbatim
    def rb_class_real
      <<-END
        function rb_class_real(klass) {
          while (FL_TEST(klass, FL_SINGLETON) || (TYPE(klass) == T_ICLASS)) { klass = klass.superclass; }
          return klass;
        }
      END
    end
    
    # verbatim
    def rb_equal
      add_function :rb_funcall
      add_method :==
      <<-END
        function rb_equal(obj1, obj2) {
          if (obj1 === obj2) { return Qtrue; }
          var result = rb_funcall(obj1, id_eq, 1, obj2);
          return RTEST(result) ? Qtrue : Qfalse;
        }
      END
    end
    
    # verbatim
    def rb_f_array
      add_function :rb_Array
      <<-END
        function rb_f_array(obj, arg) {
          return rb_Array(arg);
        }
      END
    end
    
    # verbatim
    def rb_f_float
      add_function :rb_Float
      <<-END
        function rb_f_float(obj, arg) {
          return rb_Float(arg);
        }
      END
    end
    
    # verbatim
    def rb_f_integer
      add_function :rb_Integer
      <<-END
        function rb_f_integer(obj, arg) {
          return rb_Integer(arg);
        }
      END
    end
    
    # verbatim
    def rb_f_string
      add_function :rb_String
      <<-END
        function rb_f_string(obj, arg) {
          return rb_String(arg);
        }
      END
    end
    
    # verbatim
    def rb_false
      <<-END
        function rb_false() {
          return Qfalse;
        }
      END
    end
    
    # verbatim
    def rb_inspect
      add_function :rb_obj_as_string, :rb_funcall
      add_method :inspect
      <<-END
        function rb_inspect(obj) {
          return rb_obj_as_string(rb_funcall(obj, id_inspect, 0, 0));
        }
      END
    end
    
    # CHECK
    def rb_method_missing
      add_function :rb_funcall, :rb_const_get, :rb_intern, :rb_str_new, :rb_class_new_instance,
                   :rb_exc_raise
      add_method :_!
      <<-END
        function rb_method_missing(argc, argv, obj) {
          var id;
          var exc = rb_eNoMethodError;
          var format = 0;
          var cnode = ruby_current_node;
          if ((argc === 0) || !SYMBOL_P(argv[0])) { rb_raise(rb_eArgError, "no id given"); }
          id = SYM2ID(argv[0]);
          if (last_call_status & CSTAT_PRIV) { format = "private method '%s' called for %s"; } else
          if (last_call_status & CSTAT_PROT) { format = "protected method '%s' called for %s"; } else
          if (last_call_status & CSTAT_VCALL) { format = "undefined local variable or method '%s' for %s"; exc = rb_eNameError } else
          if (last_call_status & CSTAT_SUPER) { format = "super: no superclass method '%s'"; }
          if (!format) { format = "undefined method '%s' for %s"; }
          ruby_current_node = cnode;
          var n = 0;
          var args = [];
          args[n++] = rb_funcall(rb_const_get(exc, rb_intern("message")), rb_intern("!"), 3, rb_str_new(format), obj, argv[0]); // changed rb_str_new2 to rb_str_new
          args[n++] = argv[0];
          if (exc == rb_eNoMethodError) { // expanded rb_ary_new4
            var ary4 = rb_ary_new();
            MEMCPY(ary4.ptr, argv.slice(1), argc - 1);
            args[n++] = ary4; // changed rb_ary_new4(argc - 1, argv) to ary4
          }
          exc = rb_class_new_instance(n, args, exc);
          ruby_frame = ruby_frame.prev; /* pop frame for "method_missing" */
          rb_exc_raise(exc);
          return Qnil; /* not reached */
        }
      END
    end
    
    # verbatim
    def rb_obj_alloc
      add_function :rb_raise, :rb_funcall, :rb_obj_class, :rb_class_real
      <<-END
        function rb_obj_alloc(klass) {
          if (klass.superclass == 0) { rb_raise(rb_eTypeError, "can't instantiate uninitialized class"); }
          if (FL_TEST(klass, FL_SINGLETON)) { rb_raise(rb_eTypeError, "can't create instance of virtual class"); }
          var obj = rb_funcall(klass, ID_ALLOCATOR, 0, 0);
          if (rb_obj_class(obj) != rb_class_real(klass)) { rb_raise(rb_eTypeError, "wrong instance allocation"); }
          return obj;
        }
      END
    end
    
    # verbatim
    def rb_obj_call_init
      add_function :rb_block_given_p, :rb_funcall2
      add_method :initialize
      <<-END
        function rb_obj_call_init(obj, argc, argv) {
          PUSH_ITER(rb_block_given_p() ? ITER_PRE : ITER_NOT);
          rb_funcall2(obj, init, argc, argv);
          POP_ITER();
        }
      END
    end
    
    # verbatim
    def rb_obj_class
      add_function :rb_class_real
      <<-END
        function rb_obj_class(obj) {
          return rb_class_real(CLASS_OF(obj));
        }
      END
    end
    
    # verbatim
    def rb_obj_clone
      add_function :rb_special_const_p, :rb_raise, :rb_obj_classname,
                    :rb_obj_alloc, :rb_obj_class, :rb_singleton_class_clone,
                    :init_copy
      <<-END
        function rb_obj_clone(obj) {
          var clone;
          if (rb_special_const_p(obj)) { rb_raise(rb_eTypeError, "can't clone %s", rb_obj_classname(obj)); }
          clone = rb_obj_alloc(rb_obj_class(obj));
          clone.basic.klass = rb_singleton_class_clone(obj);
          clone.basic.flags = (obj.basic.flags | FL_TEST(clone, FL_TAINT)) & ~(FL_FREEZE|FL_FINALIZE);
          init_copy(clone, obj);
          clone.basic.flags |= obj.basic.flags & FL_FREEZE;
          return clone;
        }
      END
    end
    
    # verbatim
    def rb_obj_dummy
      <<-END
        function rb_obj_dummy() {
          return Qnil;
        }
      END
    end
    
    # verbatim
    def rb_obj_dup
      add_function :rb_special_const_p, :rb_raise, :rb_obj_classname,
                   :rb_obj_alloc, :rb_obj_class, :init_copy
      <<-END
        function rb_obj_dup(obj) {
          var dup;
          if (rb_special_const_p(obj)) { rb_raise(rb_eTypeError, "can't dup %s", rb_obj_classname(obj)); }
          dup = rb_obj_alloc(rb_obj_class(obj));
          init_copy(dup, obj);
          return dup;
        }
      END
    end
    
    # verbatim
    def rb_obj_equal
      <<-END
        function rb_obj_equal(obj1, obj2) {
          return (obj1 === obj2) ? Qtrue : Qfalse;
        }
      END
    end
    
    # verbatim
    def rb_obj_freeze
      add_function :rb_raise
      <<-END
        function rb_obj_freeze(obj) {
          if (!OBJ_FROZEN(obj)) {
            if ((rb_safe_level() >= 4) && !OBJ_TAINTED(obj)) { rb_raise(rb_eSecurityError, "Insecure: can't freeze object"); }
            OBJ_FREEZE(obj);
          }
          return obj;
        }
      END
    end
    
    # modified symbol hash function
    def rb_obj_id
      <<-END
        function rb_obj_id(obj) {
          if (TYPE(obj) == T_SYMBOL) { return LONG2FIX(SYM2ID(obj) * 10 + 8); } // was "(SYM2ID(obj) * sizeof(RVALUE) + (4 << 2)) | FIXNUM_FLAG"
          if (SPECIAL_CONST_P(obj)) { return LONG2NUM(obj); }
          return obj.rvalue | FIXNUM_FLAG;
        }
      END
    end
    
    # verbatim
    def rb_obj_init_copy
      add_function :rb_check_frozen, :rb_obj_class, :rb_raise
      <<-END
        function rb_obj_init_copy(obj, orig) {
          if (obj === orig) { return obj; }
          rb_check_frozen(obj);
          if ((TYPE(obj) != TYPE(orig)) || (rb_obj_class(obj) != rb_obj_class(orig))) { rb_raise(rb_eTypeError, "initialize_copy should take same class object"); }
          return obj;
        }
      END
    end
    
    # changed string handling
    def rb_obj_inspect
      add_function :rb_obj_classname, :rb_inspecting_p, :rb_str_new, :rb_protect_inspect, :rb_funcall
      add_method :to_s
      <<-END
        function rb_obj_inspect(obj) {
          if ((TYPE(obj) == T_OBJECT) && obj.iv_tbl) {
            var str;
            var c = rb_obj_classname(obj);
            if (rb_inspecting_p(obj)) {
              str = rb_str_new();
              str.ptr = "#<" + c + ":0x" + obj.toString(16) + " ...>";
              return str;
            }
            str = rb_str_new();
            str.ptr = "-<" + c + ":0x" + obj.toString(16);
            return rb_protect_inspect(inspect_obj, obj, str);
          }
          return rb_funcall(obj, rb_intern("to_s"), 0, 0);
        }
      END
    end
    
    # verbatim
    def rb_obj_is_instance_of
      add_function :rb_raise, :rb_obj_class
      <<-END
        function rb_obj_is_instance_of(obj, c) {
          switch (TYPE(c)) {
            case T_MODULE:
            case T_CLASS:
            case T_ICLASS:
              break;
            default:
              rb_raise(rb_eTypeError, "class or module required");
          }
          return (rb_obj_class(obj) == c) ? Qtrue : Qfalse;
        }
      END
    end
    
    # verbatim
    def rb_obj_is_kind_of
      add_function :rb_raise
      <<-END
        function rb_obj_is_kind_of(obj, c) {
          var cl = CLASS_OF(obj);
          switch (TYPE(c)) {
            case T_MODULE:
            case T_CLASS:
            case T_ICLASS:
              break;
            default:
              rb_raise(rb_eTypeError, "class or module required");
          }
          while (cl) {
            if ((cl == c) || (cl.m_tbl == c.m_tbl)) { return Qtrue; }
            cl = cl.superclass;
          }
          return Qfalse;
        }
      END
    end
    
    # verbatim
    def rb_obj_method
      add_function :mnew, :rb_to_id
      <<-END
        function rb_obj_method(obj, vid) {
          return mnew(CLASS_OF(obj), obj, rb_to_id(vid), rb_cMethod);
        }
      END
    end
    
    # verbatim
    def rb_to_id
      add_function :str_to_id, :rb_id2name, :rb_raise, :rb_check_string_type, :rb_inspect
      <<-END
        function rb_to_id(name) {
          var tmp;
          var id;
          switch (TYPE(name)) {
            case T_STRING:
              return str_to_id(name);
            case T_FIXNUM:
              // removed warning
              id = FIX2LONG(name);
              if (!rb_id2name(id)) { rb_raise(rb_eArgError, "%d is not a symbol", id); }
              break;
            case T_SYMBOL:
              id = SYM2ID(name);
              break;
            default:
              tmp = rb_check_string_type(name);
              if (!NIL_P(tmp)) { return str_to_id(tmp); }
              rb_raise(rb_eTypeError, "%s is not a symbol", rb_inspect(name).ptr);
          }
          return id;
        }
      END
    end
  end
  
  module Parse
    # verbatim
    def is_attrset_id
      add_function :is_notop_id
      <<-END
        function is_attrset_id(id) {
          return is_notop_id(id) && ((id & ID_SCOPE_MASK) == ID_ATTRSET);
        }
      END
    end
    
    # verbatim
    def is_class_id
      adD_function :is_notop_id
      <<-END
        function is_class_id(id) {
          return is_notop_id(id) && ((id & ID_SCOPE_MASK) == ID_CLASS);
        }
      END
    end
    
    # verbatim
    def is_const_id
      add_function :is_notop_id
      <<-END
        function is_const_id(id) {
          return is_notop_id(id) && ((id & ID_SCOPE_MASK) == ID_CONST);
        }
      END
    end
    
    # verbatim
    def is_global_id
      add_function :is_notop_id
      <<-END
        function is_global_id(id) {
          return is_notop_id(id) && ((id & ID_SCOPE_MASK) == ID_GLOBAL);
        }
      END
    end
    
    # removed SIGN_EXTEND_CHAR and ismbchar
    def is_identchar
      <<-END
        function is_identchar(c) {
          return ISALNUM(c) || c == '_';
        }
      END
    end
    
    # verbatim
    def is_instance_id
      add_function :is_notop_id
      <<-END
        function is_instance_id(id) {
          return is_notop_id(id) && ((id & ID_SCOPE_MASK) == ID_INSTANCE);
        }
      END
    end
    
    # verbatim
    def is_junk_id
      add_function :is_notop_id
      <<-END
        function is_junk_id(id) {
          return is_notop_id(id) && ((id & ID_SCOPE_MASK) == ID_JUNK);
        }
      END
    end
    
    # verbatim
    def is_local_id
      add_function :is_notop_id
      <<-END
        function is_local_id(id) {
          return is_notop_id(id) && ((id & ID_SCOPE_MASK) == ID_LOCAL);
        }
      END
    end
    
    # verbatim
    def is_notop_id
      <<-END
        function is_notop_id(id) {
          return id > tLAST_TOKEN;
        }
      END
    end
    
    # changed allocation calls
    def local_append
      <<-END
        function local_append(id) {
          if (!lvtbl.tbl) { // was "if (lvtbl->tbl == 0)"
            lvtbl.tbl = []; // was "lvtbl->tbl = ALLOC_N(ID, 4)"
            lvtbl.tbl[0] = 0;
            lvtbl.tbl[1] = '_';
            lvtbl.tbl[2] = '~';
            lvtbl.cnt = 2;
            if (id == '_') { return 0; }
            if (id == '~') { return 1; }
          }
          // removed REALLOC_N else clause
          lvtbl.tbl[lvtbl.cnt + 1] = id;
          return lvtbl.cnt++;
        }
      END
    end
    
    # verbatim
    def local_cnt
      add_function :local_append
      <<-END
        function local_cnt(id) {
          if (id == 0) { return lvtbl.cnt; }
          for (var cnt = 1, max = lvtbl.cnt + 1; cnt < max; cnt++) {
            if (lvtbl.tbl[cnt] == id) { return cnt - 1; }
          }
          return local_append(id);
        }
      END
    end
    
    # changed "xfree" GC calls to "delete"
    def local_pop
      <<-END
        function local_pop() {
          var local = lvtbl.prev;
          if (lvtbl.tbl) {
            if (!lvtbl.nofree) {
              delete lvtbl.tbl // was xfree(lvtbl->tbl)
            } else {
              lvtbl.tbl[0] = lvtbl.cnt;
            }
          }
          ruby_dyna_vars = lvtbl.dyna_vars;
          lvtbl = local;
        }
      END
    end
    
    # verbatim
    def local_push
      add_function :rb_dvar_push
      <<-END
        function local_push(top) {
          var local = {};
          local.prev = lvtbl;
          local.nofree = 0;
          local.cnt = 0;
          local.tbl = 0;
          local.dlev = 0;
          local.dyna_vars = ruby_dyna_vars;
          lvtbl = local;
          if (!top) {
            rb_dvar_push(0, ruby_dyna_vars);
            ruby_dyna_vars.next = 0;
          }
        }
      END
    end
    
    # verbatim
    def local_tbl
      <<-END
        function local_tbl() {
          lvtbl.nofree = 1;
          return lvtbl.tbl;
        }
      END
    end
    
    # verbatim
    def rb_id_attrset
      <<-END
        function rb_id_attrset(id) {
          id &= ~ID_SCOPE_MASK;
          id |= ID_ATTRSET;
          return id;
        }
      END
    end
    
    # changed op_tbl loop, modified string buf handling
    def rb_id2name
      add_function :rb_id2name, :rb_intern, :is_local_id
      <<-END
        function rb_id2name(id) {
          var name;
          var data;
          var goto_again = 0;
          if (id < tLAST_TOKEN) {
            for (var s in op_tbl) { // modified
              if (op_tbl[s] == id) { return s; }
            }
          }
          if ((data = sym_rev_tbl[id])) { return data; } // was st_lookup
          if (is_attrset_id(id)) {
            var id2 = (id & ~ID_SCOPE_MASK) | ID_LOCAL;
            do { // was "again:" goto label
              name = rb_id2name(id2);
              if (name) {
                var buf = name + "=";
                rb_intern(buf);
                return rb_id2name(id);
              }
              if ((goto_again = is_local_id(id2))) {
                id2 = (id & ~ID_SCOPE_MASK) | ID_CONST;
              }
            } while (goto_again);
          }
          return 0;
        }
      END
    end
    
    # CHECK
    def rb_intern
      add_function :is_special_global_name, :rb_id_attrset, :is_attrset_id, :is_identchar
      <<-END
        function rb_intern(name) {
          var id;
          if ((id = sym_tbl[name])) { return id; } else { id = 0; }
            
          var last = name.length - 1;
          var m = 0;
          var skip_to_new_id = 0;
          var skip_to_id_regist = 0;
          
          switch (name[m]) {
            case '$':
              id |= ID_GLOBAL;
            //if (is_special_global_name(name[++m])) { skip_to_new_id = 1; }
              break;
            case '@':
              if (name[1] == '@') {
                m++;
                id |= ID_CLASS;
              } else {
                id |= ID_INSTANCE;
              }
              m++;
              break;
            default:
              if ((name[0] != '_') && ISASCII(name[0]) && !ISALNUM(name[0])) {
                var token;
                if ((token = op_tbl[name])) {
                  id = token;
                  skip_to_id_regist = 1;
                  break;
                }
              }
              if (name[last] == '=') {
                id = rb_intern(name.slice(0,last));
                if (id > tLAST_TOKEN && !is_attrset_id(id)) {
                  id = rb_id_attrset(id);
                  skip_to_id_regist = 1;
                  break;
                }
                id = ID_ATTRSET;
              } else if (ISUPPER(name[0])) {
                id = ID_CONST;
              } else {
                id = ID_LOCAL;
              }
          }
          
          if (!skip_to_id_regist) {
            if (!skip_to_new_id) {
              /* multibyte support not implemented */
              if (!ISDIGIT(name[m])) {
                while (m <= last && is_identchar(name[m])) { m++; }
              }
              if (name[m]) { id = ID_JUNK; }
            }
            id |= ++last_id << ID_SCOPE_SHIFT;
          }
          sym_tbl[name]   = id;
          sym_rev_tbl[id] = name;
          return id;
        }
      END
    end
    
    # verbatim
    def rb_is_const_id
      add_function :is_const_id
      <<-END
        function rb_is_const_id(id) {
          return is_const_id(id) ? Qtrue : Qfalse;
        }
      END
    end
    
    # verbatim
    def rb_is_local_id
      add_function :is_local_id
      <<-END
        function rb_is_local_id(id) {
          return is_local_id(id) ? Qtrue : Qfalse;
        }
      END
    end
    
    # changed st_lookup
    def rb_sym_interned_p
      <<-END
        function rb_sym_interned_p(str) {
          if (sym_tbl[str.ptr]) { return Qtrue; } // was st_lookup
          return Qfalse;
        }
      END
    end
    
    # verbatim
    def top_local_init
      add_function :local_push
      <<-END
        function top_local_init() {
          local_push(1);
          lvtbl.cnt = ruby_scope.local_tbl ? ruby_scope.local_tbl[0] : 0;
          if (lvtbl.cnt > 0) {
            lvtbl.tbl = []; // was "lvtbl->tbl = ALLOC_N(ID, lvtbl->cnt+3)"
            MEMCPY(lvtbl.tbl, ruby_scope.local_tbl, lvtbl.cnt + 1);
          } else {
            lvtbl.tbl = 0;
          }
          lvtbl.dlev = (ruby_dyna_vars) ? 1 : 0;
        }
      END
    end
  end
  
  module Proc
    # CHECK
    def proc_alloc
      add_function :rb_block_given_p, :rb_f_block_given_p, :rb_raise, :frame_dup,
                   :blk_copy_prev, :scope_dup, :proc_save_safe_level
      <<-END
        function proc_alloc(klass, proc) {
          var data;
          if (!rb_block_given_p() && !rb_f_block_given_p()) { rb_raise(rb_eArgError, "tried to create Proc object without a block"); }
          if (!proc && ruby_block.block_obj && (CLASS_OF(ruby_block.block_obj) == klass)) { return ruby_block.block_obj; }
        //var block = Data_Make_Struct(klass, BLOCK, blk_mark, blk_free, data);
          var data = ruby_block;
          var block = NEWOBJ();
          OBJSETUP(block, klass, T_DATA);
          block.data = data;
        //data.orig_thread = rb_thread_current();
        //data.wrapper = ruby_wrapper;
          data.iter = data.prev ? Qtrue : Qfalse;
          data.block_obj = block;
          frame_dup(data.frame);
          if (data.iter) {
            blk_copy_prev(data);
          } else {
            data.prev = 0;
          }
          for (var p = data; p; p = p.prev) {
            for (var vars = p.dyna_vars; vars; vars = vars.next) {
              if (FL_TEST(vars, DVAR_DONT_RECYCLE)) { break; }
              FL_SET(vars, DVAR_DONT_RECYCLE);
            }
          }
          scope_dup(data.scope);
          proc_save_safe_level(block);
          if (proc) {
            data.flags |= BLOCK_LAMBDA;
          } else {
            ruby_block.block_obj = block;
          }
          return block;
        }
      END
    end
    
    # EMPTY
    def proc_eq
      <<-END
        function proc_eq() {}
      END
    end
    
    # CHECK
    def proc_get_safe_level
      <<-END
        function proc_get_safe_level(data) {
          return (data.flags & PROC_TMASK) >> PROC_TSHIFT;
        }
      END
    end
    
    # CHECK
    def proc_invoke
      add_function :proc_set_safe_level
      <<-END
        function proc_invoke(proc, args, self, klass) {
          var result = Qundef;
          var safe = ruby_safe_level;
          var avalue = Qtrue;
          var tmp = args;
          var bvar = Qnil;
          var state = 0;
          if (rb_block_given_p() && ruby_frame.last_func) {
            if (klass != ruby_frame.last_class) { klass = rb_obj_class(proc); }
            bvar = rb_block_proc();
          }
          var data = proc.data;
          var pcall = (data.flags & BLOCK_LAMBDA) ? YIELD_LAMBDA_CALL : 0;
          if (!pcall && args.ptr.length == 1) {
            avalue = Qfalse;
            args = args.ptr;
          }
          var _old_vars = ruby_dyna_vars; // ff. was PUSH_VARS
          ruby_dyna_vars = 0; // ^^
          ruby_dyna_vars = data.dyna_vars;
          var old_block = ruby_block;
          var _block = data;
          _block.block_obj = bvar;
          if (self != Qundef) { _block.frame.self = self; }
          if (klass) { _block.frame.last_class = klass; }
          _block.frame.argc = tmp.ptr.length;
          _block.frame.flags = ruby_frame.flgas;
          if (_block.frame.argc && DMETHOD_P()) {
            var scope = { val: last_value += 4 };
            OBJSETUP(scope, tmp, T_SCOPE);
            scope.local_tbl = _block.scope.local_tbl;
            scope.local_vars = _block.scope.local_vars;
            scope.flags |= SCOPE_CLONE;
            _block.scope = scope;
          }
          ruby_block = _block;
          var _iter = {}; // ff. was PUSH_ITER(ITER_CUR)
          _iter.prev = ruby_iter;
          _iter.iter = ITER_CUR;
          ruby_iter = _iter; // ^^
          ruby_frame.iter = ITER_CUR;
          var _tag = {}; // ff. was PUSH_TAG(pcall ? PROT_LAMBDA : PROT_NONE)
          _tag.retval = Qnil;
          _tag.frame = ruby_frame;
          _tag.iter = ruby_iter;
          _tag.prev = prot_tag;
          _tag.scope = ruby_scope;
          _tag.tag = pcall ? PROT_LAMBDA : PROT_NONE;
          _tag.dst = 0;
          _tag.blkid = 0;
          prot_tag = _tag; // ^
          try {
            proc_set_safe_level(proc);
            result = rb_yield_0(args, self, (self != Qundef) ? CLASS_OF(self) : 0, pcall | YIELD_PROC_CALL, avalue);
          } catch (x) {
            if (typeof(state = x) != 'number') { throw(state); }
            if (TAG_DST()) { result = prot_tag.retval; }
          }
          prot_tag = _tag.prev; // was POP_TAG
          ruby_iter = _iter.prev; // was POP_ITER
          ruby_block = old_block;
          if (_old_vars && (ruby_scope.flags & SCOPE_DONT_RECYCLE)) { // ff. was POP_VARS
            if (RBASIC(_old_vars).flags) /* unless it's already recycled */ { FL_SET(_old_vars, DVAR_DONT_RECYCLE); }
          }
          ruby_dyna_vars = _old_vars; // ^^
          ruby_safe_level = safe;
          switch (state) {
            case 0:
              break;
            case TAG_RETRY:
              proc_jump_error(TAG_RETRY, Qnil);
              JUMP_TAG(state);
              break;
            case TAG_NEXT:
            case TAG_BREAK:
              if (!pcall && result != Qundef) { proc_jump_error(state, result); }
            case TAG_RETURN:
              if (result != Qundef) {
                if (pcall) { break; }
                return_jump(result);
              }
              break;
            default:
              JUMP_TAG(state);
          }
          return result;
        }
      END
    end
    
    # CHECK
    def proc_lambda
      add_function :proc_alloc
      <<-END
        function proc_lambda() {
          return proc_alloc(rb_cProc, Qtrue);
        }
      END
    end
    
    # verbatim
    def proc_s_new
      add_function :proc_alloc, :rb_obj_call_init
      <<-END
        function proc_s_new(argc, argv, klass) {
          var block = proc_alloc(klass, Qfalse);
          rb_obj_call_init(block, argc, argv);
          return block;
        }
      END
    end
    
    # CHECK
    def proc_save_safe_level
      <<-END
        function proc_save_safe_level(data) {
          var safe = ruby_safe_level;
          if (safe > PROC_TMAX) { safe = PROC_TMAX; }
          FL_SET(data, (safe << PROC_TSHIFT) & PROC_TMASK);
        }
      END
    end
    
    # CHECK
    def proc_set_safe_level
      add_function :proc_get_safe_level
      <<-END
        function proc_set_safe_level(data) {
          ruby_safe_level = proc_get_safe_level(data);
        }
      END
    end
    
    # verbatim
    def proc_to_self
      <<-END
        function proc_to_self(self) {
          return self;
        }
      END
    end
    
    # CHECK
    def rb_obj_is_proc
      <<-END
        function rb_obj_is_proc(proc) {
        //if (TYPE(proc) == T_DATA && RDATA(proc)->dfree == (RUBY_DATA_FUNC)blk_free) {
          return (TYPE(proc) == T_DATA) ? Qtrue : Qfalse;
        }
      END
    end
    
    # CHECK
    def rb_proc_call
      add_function :proc_invoke
      <<-END
        function rb_proc_call(proc, args) {
          return proc_invoke(proc, args, Qundef, 0);
        }
      END
    end
  end
  
  module Range
    # CHECK
    def range_check
      add_function :rb_funcall
      add_method :"<=>"
      <<-END
        function range_check(args) {
          return rb_funcall(args[0], id_cmp, 1, args[1]);
        }
      END
    end
    
    # verbatim
    def range_eq
      add_function :rb_obj_is_instance_of, :rb_obj_class, :rb_equal, :rb_ivar_get
      <<-END
        function range_eq(range, obj) {
          if (range == obj) { return Qtrue; }
          if (!rb_obj_is_instance_of(obj, rb_obj_class(range))) { return Qfalse; }
          if (!rb_equal(rb_ivar_get(range, id_beg), rb_ivar_get(obj, id_beg))) { return Qfalse; }
          if (!rb_equal(rb_ivar_get(range, id_end), rb_ivar_get(obj, id_end))) { return Qfalse; }
          if (EXCL(range) != EXCL(obj)) { return Qfalse; }
          return Qtrue;
        }
      END
    end
    
    # CHECK
    def range_failed
      add_function :rb_raise
      <<-END
        function range_failed() {
          rb_raise(rb_eArgError, "bad value for range");
        }
      END
    end
    
    # CHECK
    def range_init
      add_function :rb_rescue, :range_failed, :rb_ivar_set
      <<-END
        function range_init(range, beg, end, exclude_end) {
          var args = [beg, end];
          if (!FIXNUM_P(beg) || !FIXNUM_P(end)) {
            var v = rb_rescue(range_check, args, range_failed, 0);
            if (NIL_P(v)) { range_failed(); }
          }
          SET_EXCL(range, exclude_end);
          rb_ivar_set(range, id_beg, beg);
          rb_ivar_set(range, id_end, end);
        }
      END
    end
    
    # expanded rb_scan_args
    def range_initialize
      add_function :rb_ivar_defined, :rb_name_error, :range_init
      <<-END
        function range_initialize(argc, argv, range) {
          var tmp = rb_scan_args(argc, argv, "21");
          var beg = tmp[1];
          var end = tmp[2];
          var flags = tmp[3];
          /* Ranges are immutable, so that they should be initialized only once. */
          if (rb_ivar_defined(range, id_beg)) { rb_name_error(rb_intern("initialize"), "`initialize' called twice"); }
          range_init(range, beg, end, RTEST(flags));
          return Qnil;
        }
      END
    end
    
    # CHECK
    def range_inspect
      add_function :rb_inspect, :rb_ivar_get, :rb_str_dup, :rb_str_cat, :rb_str_append
      <<-END
        function range_inspect(range) {
          var str = rb_inspect(rb_ivar_get(range, id_beg));
          var str2 = rb_inspect(rb_ivar_get(range, id_end));
          str = rb_str_dup(str);
          rb_str_cat(str, EXCL(range) ? '...' : '..');
          rb_str_append(str, str2);
          OBJ_INFECT(str, str2);
          return str;
        }
      END
    end
    
    # EMPTY
    def range_to_s
      <<-END
        function range_to_s() {}
      END
    end
    
    # CHECK
    def rb_range_new
      add_function :rb_obj_alloc, :range_init
      <<-END
        function rb_range_new(beg, end, exclude_end) {
          var range = rb_obj_alloc(rb_cRange);
          range_init(range, beg, end, exclude_end);
          return range;
        }
      END
    end
  end
  
  module St
    # modified hash copying
    def st_copy
      <<-END
        function st_copy(src) {
          var tbl = {};
          for (var x in src) { tbl[x] = src[x]; }
          return tbl;
        }
      END
    end
  end
  
  module String
    # CHECK
    def rb_obj_as_string
      add_function :rb_funcall, :rb_any_to_s
      add_method :to_s
      <<-END
        function rb_obj_as_string(obj) {
          if (TYPE(obj) == T_STRING) { return obj; }
          var str = rb_funcall(obj, id_to_s, 0);
          if (TYPE(str) != T_STRING) { return rb_any_to_s(obj); }
          if (OBJ_TAINTED(obj)) OBJ_TAINT(str);
          return str;
        }
      END
    end
    
    # CHECK
    def rb_str_append
      add_function :rb_str_modify
      <<-END
        function rb_str_append(str, str2) {
        //rb_str_modify(str);
          str.ptr = str.ptr + str2.ptr;
          OBJ_INFECT(str, str2);
          return str;
        }
      END
    end
    
    # CHECK
    def rb_str_cat
      add_function :rb_str_modify
      <<-END
        function rb_str_cat(str, ptr) {
        //rb_str_modify(str);
          str.ptr = str.ptr + ptr;
          return str;
        }
      END
    end
    
    # CHECK
    def rb_str_dup
      add_function :str_alloc, :rb_obj_class, :rb_str_replace
      <<-END
        function rb_str_dup(str) {
          var dup = str_alloc(rb_obj_class(str));
          rb_str_replace(dup, str);
          return dup;
        }
      END
    end
    
    # verbatim
    def rb_str_equal
      add_function :rb_respond_to, :rb_intern, :rb_equal, :rb_str_cmp
      add_method :to_str
      <<-END
        function rb_str_equal(str1, str2) {
          if (str1 == str2) { return Qtrue; }
          if (TYPE(str2) != T_STRING) {
            if (!rb_respond_to(str2, rb_intern("to_str"))) { return Qfalse; }
            return rb_equal(str2, str1);
          }
          if ((str1.ptr.length == str2.ptr.length) && (rb_str_cmp(str1, str2) === 0)) { return Qtrue; }
          return Qfalse;
        }
      END
    end
    
    # expanded rb_scan_args
    def rb_str_init
      add_function :rb_scan_args, :rb_str_replace
      <<-END
        function rb_str_init(argc, argv, str) {
          var tmp = rb_scan_args(argc, argv, "01");
          var orig = tmp[1];
          if (tmp[0] == 1) { rb_str_replace(str, orig); }
          return str;
        }
      END
    end
    
    # EMPTY
    def rb_str_inspect
      <<-END
        function rb_str_inspect() {}
      END
    end
    
    # CHECK
    def rb_str_intern
      add_function :rb_raise, :rb_sym_interned_p, :rb_intern
      <<-END
        function rb_str_intern(s) {
          var str = s;
          if (!str.ptr || str.ptr.length === 0) { rb_raise(rb_eArgError, "interning empty string"); }
          if (OBJ_TAINTED(str) && rb_safe_level() >= 1 && !rb_sym_interned_p(str)) { rb_raise(rb_eSecurityError, "Insecure: can't intern tainted string"); }
          var id = rb_intern(str.ptr);
          return ID2SYM(id);
        }
      END
    end
    
    # CHECK
    def rb_str_new
      add_function :str_alloc
      <<-END
        function rb_str_new(ptr) {
          var str = str_alloc(rb_cString);
          str.ptr = ptr;
          return str;
        }
      END
    end
    
    # CHECK
    def rb_str_replace
      add_function :rb_str_modify
      <<-END
        function rb_str_replace(str, str2) {
          if (str === str2) { return str; }
        //StringValue(str2);
        //rb_str_modify(str);
          str.ptr = str2.ptr;
          return str;
        }
      END
    end
    
    # verbatim
    def rb_str_to_s
      add_function :str_alloc, :rb_str_replace, :rb_obj_class
      <<-END
        function rb_str_to_s(str) {
          if (rb_obj_class(str) != rb_cString) {
            var dup = str_alloc(rb_cString);
            rb_str_replace(dup, str);
            return dup;
          }
          return str;
        }
      END
    end
    
    # CHECK
    def str_alloc
      <<-END
        function str_alloc(klass) {
          var str = NEWOBJ();
          OBJSETUP(str, klass, T_STRING);
          str.ptr = 0;
          return str;
        }
      END
    end
    
    # verbatim
    def str_to_id
      add_function :rb_str_intern
      <<-END
        function str_to_id(str) {
          return SYM2ID(rb_str_intern(str));
        }
      END
    end
  end
  
  module Struct
    # removed bug warning
    def rb_struct_equal
      <<-END
        function rb_struct_equal(s, s2) {
          if (s == s2) { return Qtrue; }
          if (TYPE(s2) != T_STRUCT) { return Qfalse; }
          if (rb_obj_class(s) != rb_obj_class(s2)) { return Qfalse; }
          for (var i = 0, p = s.ptr, p2 = s2.ptr, l = s.ptr.length; i < l; ++i) {
            if (!rb_equal(p[i], p2[i])) return Qfalse;
          }
          return Qtrue;
        }
      END
    end
    
    # EMPTY
    def rb_struct_init_copy
      <<-END
        function rb_struct_init_copy() {}
      END
    end
    
    # EMPTY
    def rb_struct_initialize
      <<-END
        function rb_struct_initialize() {}
      END
    end
    
    # EMPTY
    def rb_struct_inspect
      <<-END
        function rb_struct_inspect() {}
      END
    end
    
    # EMPTY
    def rb_struct_s_def
      <<-END
        function rb_struct_s_def() {}
      END
    end
    
    # EMPTY
    def rb_struct_to_a
      <<-END
        function rb_struct_to_a() {}
      END
    end
  end
  
  module Symbol
    # completely changed; incomplete (needs to handle, e.g., :"one and two")
    def sym_inspect
      add_function :rb_str_new, :rb_id2name
      <<-END
        function sym_inspect(sym) {
          return rb_str_new(':' + rb_id2name(SYM2ID(sym)));
        }
      END
    end
    
    # verbatim
    def sym_to_i
      <<-END
        function sym_to_i(sym) {
          return LONG2FIX(SYM2ID(sym));
        }
      END
    end
    
    # removed warning
    def sym_to_int
      add_function :sym_to_i
      <<-END
        function sym_to_int(sym) {
          return sym_to_i(sym);
        }
      END
    end
    
    # verbatim
    def sym_to_proc
      add_function :rb_proc_new
      <<-END
        function sym_to_proc(sym) {
          return rb_proc_new(sym_call, SYM2ID(sym));
        }
      END
    end
    
    # changed rb_str_new2 to rb_str_new
    def sym_to_s
      add_function :rb_str_new, :rb_id2name
      <<-END
        function sym_to_s(sym) {
          return rb_str_new(rb_id2name(SYM2ID(sym)));
        }
      END
    end
    
    # verbatim
    def sym_to_sym
      <<-END
        function sym_to_sym(sym) {
          return sym;
        }
      END
    end
  end
  
  module True
    # changed rb_str_new2 to rb_str_new
    def true_to_s
      add_function :rb_str_new
      <<-END
        function true_to_s(obj) {
          return rb_str_new("true");
        }
      END
    end
    
    # verbatim
    def true_and
      <<-END
        function true_and(obj1, obj2) {
          return RTEST(obj2) ? Qtrue : Qfalse;
        }
      END
    end
    
    # verbatim
    def true_or
      <<-END
        function true_or(obj1, obj2) {
          return Qtrue;
        }
      END
    end
    
    # verbatim
    def true_xor
      <<-END
        function true_xor(obj1, obj2) {
          return RTEST(obj2) ? Qfalse : Qtrue;
        }
      END
    end
  end
  
  module Variable
    # slightly modified logic flow, replaced st calls
    def classname
      add_functions :find_class_path, :rb_str_new, :rb_id2name
      <<-END
        function classname(klass) {
          var path = Qnil;
          if (!klass) { klass = rb_cObject; }
          if (!klass.iv_tbl) { return find_class_path(klass); } // shifted from end of function
          
          if (!(path = klass.iv_tbl[classpath])) {
            var classid = rb_intern('__classid__');
            if (!(path = klass.iv_tbl[classid])) {
              return find_class_path(klass);
            }
            
            path = rb_str_new(rb_id2name(SYM2ID(path))); // changed rb_str_new2 to rb_str_new
            klass.iv_tbl[classpath] = path; // was st_insert
            delete klass.iv_tbl[classid]; // was st_delete
          }
          return path;
        }
      END
    end
    
    # verbatim
    def const_missing
      add_function :rb_funcall
      add_method :const_missing
      <<-END
       function const_missing(klass, id) {
          return rb_funcall(klass, rb_intern("const_missing"), 1, ID2SYM(id));
        }
      END
    end
    
    # verbatim
    def cvar_cbase
      add_functions :rb_raise
      <<-END
        function cvar_cbase() {
          var cref = ruby_cref;
          while (cref && cref.nd_next && (NIL_P(cref.nd_clss) || FL_TEST(cref.nd_clss, FL_SINGLETON))) { cref = cref.nd_next; } // removed bug warning
          if (NIL_P(cref.nd_clss)) { rb_raise(rb_eTypeError, "no class variables available"); }
          return cref.nd_clss;
        }
      END
    end
    
    # verbatim
    def generic_ivar_set
      add_functions :rb_special_const_p
      <<-END
        function generic_ivar_set(obj, id, val) {
          var data;
          var tbl;
          if (rb_special_const_p(obj)) { special_generic_ivar = 1; }
          // removed check for generic_iv_tbl
          if (!(data = generic_iv_tbl[obj.val])) { // was st_lookup
            FL_SET(obj, FL_EXIVAR);
            tbl = {}; // was st_init_numtable
            generic_iv_tbl[obj.val] = tbl; // was st_add_direct
            tbl[id] = val; // was st_add_direct
            return;
          }
          data[id] = val; // was st_insert
        }
      END
    end
    
    # verbatim
    def ivar_get
      add_functions :rb_special_const_p, :generic_ivar_get
      <<-END
        function ivar_get(obj, id, warn) {
          var val;
          switch (TYPE(obj)) {
            case T_OBJECT:
            case T_CLASS:
            case T_MODULE:
              if (obj.iv_tbl && (val = obj.iv_tbl[id])) { return val; }
              break;
            default:
              if (FL_TEST(obj, FL_EXIVAR) || rb_special_const_p(obj)) { return generic_ivar_get(obj, id, warn); }
          }
          // removed warning
          return Qnil;
        }
      END
    end
    
    # removed "autoload" call
    def mod_av_set
      add_functions :rb_raise, :rb_error_frozen
      <<-END
        function mod_av_set(klass, id, val, isconst) {
          if (!OBJ_TAINTED(klass) && rb_safe_level() >= 4) { rb_raise(rb_eSecurityError, "Insecure: can't set %s", isconst ? "constant" : "class variable"); }
          if (OBJ_FROZEN(klass)) { rb_error_frozen((BUILTIN_TYPE(klass) == T_MODULE) ? "module" : "class"); }
          if (!klass.iv_tbl) { klass.iv_tbl = {}; } // removed "autoload" call
          klass.iv_tbl[id] = val; // was st_insert
        }
      END
    end
    
    # unsupported
    def rb_alias_variable
      add_functions :rb_raise
      <<-END
        function rb_alias_variable() {
          rb_raise(rb_eRuntimeError, "Red doesn't support global variable aliasing");
        }
      END
    end
    
    # verbatim
    def rb_attr_get
      add_functions :ivar_get
      <<-END
        function rb_attr_get(obj, id) {
          return ivar_get(obj, id, Qfalse);
        }
      END
    end
    
    # verbatim
    def rb_class_name
      add_functions :rb_class_path, :rb_class_real
      <<-END
        function rb_class_name(klass) {
          return rb_class_path(rb_class_real(klass));
        }
      END
    end
    
    # changed string construction
    def rb_class_path
      add_functions :classname, :rb_obj_class, :rb_class2name, :rb_str_new, :rb_ivar_set
      <<-END
        function rb_class_path(klass) {
          var path = classname(klass);
          if (!NIL_P(path)) { return path; }
          if (klass.iv_tbl && (path = klass.iv_tbl[tmp_classpath])) { // was st_lookup
            return path;
          } else {
            var s = "Class";
            if (TYPE(klass) == T_MODULE) { s = (rb_obj_class(klass) == rb_cModule) ? "Module" : rb_class2name(klass.basic.klass); }
            path = rb_str_new(0); // got rid of "len"
            path.ptr = "#<" + s + ":0x" + klass.toString(16) + ">"; // changed from snprintf
            rb_ivar_set(klass, tmp_classpath, path);
            return path;
          }
        }
      END
    end
    
    # verbatim
    def rb_class2name
      add_functions :rb_class_name
      <<-END
        function rb_class2name(klass) {
          return rb_class_name(klass).ptr;
        }
      END
    end
    
    # verbatim
    def rb_const_defined
      add_functions :rb_const_defined_0
      <<-END
        function rb_const_defined(klass, id) {
          return rb_const_defined_0(klass, id, Qfalse, Qtrue);
        }
      END
    end
    
    # removed "autoload" call, unwound "goto" architecture
    def rb_const_defined_0
      <<-END
        function rb_const_defined_0(klass, id, exclude, recurse) {
          var value;
          var tmp = klass;
          var mod_retry = 0;
          do { // added to handle "goto"
            while (tmp) {
              if (tmp.iv_tbl && (value = tmp.iv_tbl[id])) { return Qtrue; } // removed "autoload" call
              if (!recurse && (klass != rb_cObject)) { break; }
              tmp = tmp.superclass;
            }
          } while (!exclude && !mod_retry && (BUILTIN_TYPE(klass) == T_MODULE) && (tmp = rb_cObject) && (mod_retry = 1)); // added to handle "goto"
          return Qfalse;
        }
      END
    end
    
    # verbatim
    def rb_const_defined_at
      add_functions :rb_const_defined_0
      <<-END
        function rb_const_defined_at(klass, id) {
          return rb_const_defined_0(klass, id, Qtrue, Qfalse);
        }
      END
    end
    
    # verbatim
    def rb_const_get
      add_functions :rb_const_get_0
      <<-END
        function rb_const_get(klass, id) {
          return rb_const_get_0(klass, id, Qfalse, Qtrue);
        }
      END
    end
    
    # removed "autoload" call, unwound "goto" architecture
    def rb_const_get_0
      add_functions :const_missing
      <<-END
        function rb_const_get_0(klass, id, exclude, recurse) {
          var value;
          var tmp = klass;
          var mod_retry = 0;
          do {
            while (tmp) {
              while (tmp.iv_tbl && (value = tmp.iv_tbl[id])) { return value; } // removed "autoload" call
              if (!recurse && (klass != rb_cObject)) { break; }
              tmp = tmp.superclass;
            }
          } while (!exclude && !mod_retry && (BUILTIN_TYPE(klass) == T_MODULE) && (tmp = rb_cObject) && (mod_retry = 1));
          return const_missing(klass, id);
        }
      END
    end
    
    # verbatim
    def rb_const_get_at
      add_functions :rb_const_get_0
      <<-END
        function rb_const_get_at(klass, id) {
          return rb_const_get_0(klass, id, Qtrue, Qfalse);
        }
      END
    end
    
    # verbatim
    def rb_const_get_from
      add_functions :rb_const_get_0
      <<-END
        function rb_const_get_from(klass, id) {
          return rb_const_get_0(klass, id, Qtrue, Qtrue);
        }
      END
    end
    
    # verbatim
    def rb_const_set
      add_functions :rb_raise, :rb_id2name, :mod_av_set
      <<-END
        function rb_const_set(klass, id, val) {
          if (NIL_P(klass)) { rb_raise(rb_eTypeError, "no class/module to define constant %s", rb_id2name(id)); }
          mod_av_set(klass, id, val, Qtrue);
        }
      END
    end
    
    # added undefined check
    def rb_cvar_get
      add_functions :rb_name_error, :rb_id2name, :rb_class2name
      <<-END
        function rb_cvar_get(klass, id) {
          var value;
          var tmp = klass;
          while (tmp) {
            if (tmp.iv_tbl && (value = tmp.iv_tbl[id]) && (value !== undefined)) { return value; } // was st_lookup, added undefined check
            tmp = tmp.superclass;
          }
          rb_name_error(id, "uninitialized class variable %s in %s", rb_id2name(id), rb_class2name(klass));
          return Qnil; /* not reached */
        }
      END
    end
    
    # verbatim
    def rb_cvar_set
      add_functions :rb_error_frozen, :rb_raise, :mod_av_set
      <<-END
        function rb_cvar_set(klass, id, val) {
          var tmp = klass;
          while (tmp) {
            if (tmp.iv_tbl && tmp.iv_tbl[id]) { // was st_lookup
              if (OBJ_FROZEN(tmp)) { rb_error_frozen("class/module"); }
              if (!OBJ_TAINTED(tmp) && rb_safe_level() >= 4) { rb_raise(rb_eSecurityError, "Insecure: can't modify class variable"); }
              // removed warnings
              tmp.iv_tbl[id] = val; // was st_insert
              return;
            }
            tmp = tmp.superclass;
          }
          mod_av_set(klass, id, val, Qfalse);
        }
      END
    end
    
    # verbatim
    def rb_define_const
      add_functions :rb_const_set, :rb_secure
      <<-END
        function rb_define_const(klass, name, val) {
          // removed warning
          if (klass == rb_cObject) { rb_secure(4); }
          rb_const_set(klass, rb_intern(name), val);
        }
      END
    end
    
    # verbatim
    def rb_define_global_const
      add_functions :rb_define_const
      <<-END
        function rb_define_global_const(name, val) {
          rb_define_const(rb_cObject, name, val);
        }
      END
    end
    
    # CHECK
    def rb_define_hooked_variable
      <<-END
        console.log('man, global variables are awful');
        function rb_define_hooked_variable() {}
      END
    end
    
    # verbatim
    def rb_define_variable
      add_function :rb_define_hooked_variable
      <<-END
        function rb_define_variable(name, vars) {
          rb_define_hooked_variable(name, vars, 0, 0);
        }
      END
    end
    
    # verbatim
    def rb_dvar_push
      add_function :new_dvar
      <<-END
        function rb_dvar_push(id, value) {
          ruby_dyna_vars = new_dvar(id, value, ruby_dyna_vars);
        }
      END
    end
    
    # simplified to hash lookup
    def rb_gvar_get
      <<-END
        function rb_gvar_get(id) {
          var result;
          return typeof(result = rb_global_tbl[id]) === 'undefined' ? Qnil : result;
        }
      END
    end
    
    # simplified to hash storage
    def rb_gvar_set
      <<-END
        function rb_gvar_set(id, val) {
          return rb_global_tbl[id] = val;
        }
      END
    end
    
    # verbatim
    def rb_iv_get
      add_functions :rb_ivar_get
      <<-END
        function rb_iv_get(obj, name) {
          return rb_ivar_get(obj, rb_intern(name));
        }
      END
    end
    
    # verbatim
    def rb_iv_set
      add_functions :rb_ivar_set
      <<-END
        function rb_iv_set(obj, name, val) {
          return rb_ivar_set(obj, rb_intern(name), val);
        }
      END
    end
    
    # verbatim
    def rb_ivar_get
      add_functions :ivar_get
      <<-END
        function rb_ivar_get(obj, id) {
          return ivar_get(obj, id, Qtrue);
        }
      END
    end
    
    # verbatim
    def rb_ivar_set
      add_functions :rb_raise, :rb_error_frozen, :generic_ivar_set
      <<-END
        function rb_ivar_set(obj, id, val) {
          if (!OBJ_TAINTED(obj) && rb_safe_level() >= 4) { rb_raise(rb_eSecurityError, "Insecure: can't modify instance variable"); }
          if (OBJ_FROZEN(obj)) { rb_error_frozen("object"); }
          switch (TYPE(obj)) {
            case T_OBJECT:
            case T_CLASS:
            case T_MODULE:
              if (!obj.iv_tbl) { obj.iv_tbl = {}; } // was st_init_numtable
              obj.iv_tbl[id] = val; // was st_insert
              break;
            default:
              generic_ivar_set(obj, id, val);
              break;
          }
          return val;
        }
      END
    end
    
    # verbatim
    def rb_mod_const_missing
      add_function :uninitialized, :rb_to_id
      <<-END
        function rb_mod_const_missing(klass, name) {
          ruby_frame = ruby_frame.prev; /* pop frame for "const_missing" */
          uninitialized_constant(klass, rb_to_id(name));
          return Qnil; /* not reached */
        }
      END
    end
    
    # verbatim
    def rb_name_class
      add_functions :rb_iv_set
      <<-END
        function rb_name_class(klass, id) {
          rb_iv_set(klass, '__classid__', ID2SYM(id));
        }
      END
    end
    
    # verbatim
    def rb_obj_classname
      add_functions :rb_class2name
      <<-END
        function rb_obj_classname(obj) {
          return rb_class2name(CLASS_OF(obj));
        }
      END
    end
    
    # changed string handling
    def rb_set_class_path
      add_functions :rb_str_new, :rb_class_path, :rb_ivar_set
      <<-END
        function rb_set_class_path(klass, under, name) {
          if (under == rb_cObject) {
            var str = rb_str_new(name);
          } else {
            var base_name = rb_class_path(under).ptr;
            var str = rb_str_new(base_name + "::" + name);
          }
          rb_ivar_set(klass, classpath, str);
        }
      END
    end
    
    # verbatim
    def uninitialized_constant
      add_function :rb_name_error, :rb_class2name, :rb_id2name
      <<-END
        function uninitialized_constant(klass, id) {
          if (klass && (klass != rb_cObject)) {
            rb_name_error(id, "uninitialized constant %s::%s", rb_class2name(klass), rb_id2name(id));
          } else {
            rb_name_error(id, "uninitialized constant %s", rb_id2name(id));
          }
        }
      END
    end
  end
  
  include Array
  include Boot
  include Browser
  include Class
  include Comparable
  include Data
  include Rb
  include Document
  include Element
  include Enumerable
  include Enumerator
  include Eval
  include Event
  include Exception
  include False
  include Fixnum
  include Float
  include Hash
  include Integer
  include IO
  include Method
  include Module
  include Nil
  include Node
  include Numeric
  include Object
  include Parse
  include Proc
  include Range
  include St
  include String
  include Struct
  include Symbol
  include True
  include UserEvent
  include Variable
  include Window
end
