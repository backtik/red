class Red::MethodCompiler
  # verbatim
  def big2dbl
    <<-END
      function big2dbl(x) {
        var d = 0.0;
        var i = x.len;
        var ds = BDIGITS(x);
        while (i--) {
          d = ds[i] + BIGRAD * d;
        }
        if (!x.sign) { d = -d; }
        return d;
      }
    END
  end
  
  # removed warning
  def rb_big2dbl
    <<-END
      function rb_big2dbl(x) {
        return big2dbl(x);
      }
    END
  end
end
