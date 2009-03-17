class Red::MethodCompiler
  # complete
  def resp_text
    add_function :rb_str_new
    <<-END
      function resp_text(resp) {
        return rb_str_new(resp.text);
      }
    END
  end
  
  # complete
  def resp_xml
    add_function :rb_str_new
    <<-END
      function resp_xml(resp) {
        return rb_str_new(resp.xml);
      }
    END
  end
end
