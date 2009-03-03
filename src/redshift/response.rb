class Red::MethodCompiler
  # 
  module Response
    # 
    def resp_alloc
      <<-END
        function resp_alloc(klass) {
          var resp = NEWOBJ();
          OBJSETUP(resp, klass, T_DATA);
          resp.ptr = 0;
          return resp;
        }
      END
    end
    
    # 
    def resp_text
      add_function :rb_str_new
      <<-END
        function resp_text(resp) {
          return rb_str_new(resp.text);
        }
      END
    end
    
    # 
    def resp_xml
      add_function :rb_str_new
      <<-END
        function resp_xml(resp) {
          return rb_str_new(resp.xml);
        }
      END
    end
  end
end
