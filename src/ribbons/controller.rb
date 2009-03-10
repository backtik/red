class Red::MethodCompiler
  def controller_initialize
    <<-END
      function controller_initialize(controller) {
        controller.callbacks = {};
      }
    END
  end
end