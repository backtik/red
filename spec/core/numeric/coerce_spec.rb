# require File.dirname(__FILE__) + '/../../spec_helper'
# require File.dirname(__FILE__) + '/fixtures/classes'

describe "Numeric#coerce" do |it| 
  before(:each) do
    @obj = NumericSub.new
  end
  
  it.returns "[other, self] if self and other are instances of the same class" do
    other = NumericSub.new
    @obj.coerce(other).should_equal([other, @obj])
  end
  
  it.returns "an Array containing other and self converted to Fixnums using #to_f if they are not instances of the same class" do
    @obj.should_receive(:to_f).at_most(4).times.and_return(10.5)

    result = @obj.coerce(2.5)
    result.should_equal([2.5, 10.5])
    result.first.should_be_kind_of(Float)
    result.last.should_be_kind_of(Float)
    
    result = @obj.coerce(3)
    result.should_equal([3.0, 10.5])
    result.first.should_be_kind_of(Float)
    result.last.should_be_kind_of(Float)

    result = @obj.coerce("4.4")
    result.should_equal([4.4, 10.5])
    result.first.should_be_kind_of(Float)
    result.last.should_be_kind_of(Float)

    not_compliant_on :rubinius do
      result = @obj.coerce(bignum_value)
      result.should_equal([bignum_value.to_f, 10.5])
      result.first.should_be_kind_of(Float)
      result.last.should_be_kind_of(Float)
    end
  end

  it.raises " a TypeError when other can't be coerced" do
    not_compliant_on :ironruby do
      # This really is implementation specific - it relies on to_f being called on both parameters
      # IronRuby bails out if other.to_f fails
      @obj.should_receive(:to_f).exactly(2).times.and_return(10.5)
    end
    lambda { @obj.coerce(nil)   }.should_raise(TypeError)
    lambda { @obj.coerce(false) }.should_raise(TypeError)    
  end
  
  it.raises " an ArgumentError when other can't be converted to Float" do
    not_compliant_on :ironruby do
      # This really is implementation specific - it relies on to_f being called on both parameters
      # IronRuby bails out if other.to_f fails
      @obj.should_receive(:to_f).and_return(10.5)
    end
    lambda { @obj.coerce("test") }.should_raise(ArgumentError)
  end
end