# require File.dirname(__FILE__) + '/../../spec_helper'
# require File.dirname(__FILE__) + '/fixtures/classes'

describe "Math.atan2" do |it| 
  it.returns "a float" do
    Math.atan2(1.2, 0.5).class.should_equal(Float)
  end
  
  it.returns "the arc tangent of y, x" do
    Math.atan2(4.2, 0.3).should_be_close(1.49948886200961, TOLERANCE)
    Math.atan2(0.0, 1.0).should_be_close(0.0, TOLERANCE)
    Math.atan2(-9.1, 3.2).should_be_close(-1.23265379809025, TOLERANCE)
    Math.atan2(7.22, -3.3).should_be_close(1.99950888779256, TOLERANCE)
  end
  
  it.raises " an ArgumentError if the argument cannot be coerced with Float()" do    
    lambda { Math.atan2(1.0, "test")    }.should_raise(ArgumentError)
    lambda { Math.atan2("test", 0.0)    }.should_raise(ArgumentError)
    lambda { Math.atan2("test", "this") }.should_raise(ArgumentError)
  end
  
  it.raises " a TypeError if the argument is nil" do
    lambda { Math.atan2(nil, 1.0)  }.should_raise(TypeError)
    lambda { Math.atan2(-1.0, nil) }.should_raise(TypeError)
    lambda { Math.atan2(nil, nil)  }.should_raise(TypeError)
  end

  it.will "accept any argument that can be coerced with Float()" do
    Math.atan2(MathSpecs::Float.new, MathSpecs::Float.new).should_be_close(0.785398163397448, TOLERANCE)
  end
end

describe "Math#atan2" do |it| 
  it.is "accessible as a private instance method" do
    IncludesMath.new.send(:atan2, 1.1, 2.2).should_be_close(0.463647609000806, TOLERANCE)
  end
end
