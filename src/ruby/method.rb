class Red::MethodCompiler
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
