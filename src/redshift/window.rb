class Red::MethodCompiler
  # complete
  module Window
    # complete
    def win_document
      <<-END
        function win_document() {
          return rb_mDocument;
        }
      END
    end
    
    # complete
    def win_window
      <<-END
        function win_window() {
          return rb_mWindow;
        }
      END
    end
  end
end
