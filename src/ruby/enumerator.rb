class Red::MethodCompiler
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

