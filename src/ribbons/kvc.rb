class Red::MethodCompiler
  def rb_kvc_reader
    <<-END
      function rb_kvc_reader(klass, id, dependencies) {
        
      }
    END
  end
  
  def rb_kvc_attr
    add_function :rb_is_local_id, :rb_is_const_id, :rb_name_error, :rb_id2name, :rb_id_attrset,
                 :rb_add_method,:rb_raise, :rb_intern, :rb_ivar_set, :define_method, :rb_iv_attr_set
    <<-END
      function rb_kvc_attr(klass, id, ex) {
        var noex;
        if (!ex) {
          noex = NOEX_PUBLIC;
        } else if (SCOPE_TEST(SCOPE_PRIVATE)) {
          noex = NOEX_PRIVATE;
        } else if (SCOPE_TEST(SCOPE_PROTECTED)) {
          noex = NOEX_PROTECTED;
        } else {
          noex = NOEX_PUBLIC;
        }
        if (!rb_is_local_id(id) && !rb_is_const_id(id)) { rb_name_error(id, "invalid attribute name '%s'", rb_id2name(id)); }
        var name = rb_id2name(id);
        if (!name) { rb_raise(rb_eArgError, "argument needs to be symbol or string"); }
        var attriv = rb_intern('@' + name);
        rb_add_method(klass, id, NEW_IVAR(attriv), noex);
        var fn = function(obj, value) {
          rb_ivar_set(obj, attriv, value);
          for (var i = 0, p = obj.callbacks[attriv] || [], l = p.length; i < l; ++i) {
            p[i]();
          }
          return value;
        };
        rb_define_method(klass, rb_id2name(rb_id_attrset(id)), fn, 1);
      }
    END
  end
end