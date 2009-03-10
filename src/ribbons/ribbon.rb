class Red::MethodCompiler
  module Ribbon
    def ribbon_initialize
      add_function :rb_new_class_instance
      <<-END
        function ribbon_initialize(ribbon, object, attribute, key_path_string) {
          ribbon.object = object;
          ribbon.reader_id = rb_to_id(attribute);
          ribbon.writer_id = rb_to_id(rb_id2name(ribbon.reader_id) + '=');
          ribbon.key_path = rb_new_class_instance(1, [key_path_string], rb_cKeyPath);
        }
      END
    end
  end
end