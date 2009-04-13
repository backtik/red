class Red::MethodCompiler
  # removed "mark" and "free" GC handling
  def rb_data_object_alloc
    add_function :rb_check_type
    <<-END
      function rb_data_object_alloc(klass, datap, dmark) {
        NEWOBJ(data);
        if (klass) { Check_Type(klass, T_CLASS); }
        OBJSETUP(data, klass, T_DATA);
        data.data = datap;
        data.dmark = dmark;
        return data;
      }
    END
  end
end
