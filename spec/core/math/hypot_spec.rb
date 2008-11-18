# require File.dirname(__FILE__) + '/../../spec_helper'
# require File.dirname(__FILE__) + '/fixtures/classes'

describe "Math.hypot" do |it| 
  it.returns "a float" do
    Math.hypot(3, 4).class.should_equal(Float)
  end
  
  it.returns "the length of the hypotenuse of a right triangle with legs given by the arguments" do 
    Math.hypot(0, 0).should_be_close(0.0, TOLERANCE)
    Math.hypot(2, 10).should_be_close( 10.1980390271856, TOLERANCE)
    Math.hypot(5000, 5000).should_be_close(7071.06781186548, TOLERANCE)
    Math.hypot(0.0001, 0.0002).should_be_close(0.000223606797749979, TOLERANCE)
    Math.hypot(-2, -10).should_be_close(10.1980390271856, TOLERANCE)
    Math.hypot(2, 10).should_be_close(10.1980390271856, TOLERANCE)
  end
    
  it.raises " an ArgumentError if the argument cannot be coerced with Float()" do    
    lambda { Math.hypot("test", "this") }.should_raise(ArgumentError)
  end
  
  it.raises " a ArgumentError if the argument is nil" do
    lambda { Math.hypot(nil) }.should_raise(ArgumentError)
  end 
  
  it.will "accept any argument that can be coerced with Float()" do
    Math.hypot(MathSpecs::Float.new, MathSpecs::Float.new).should_be_close(1.4142135623731, TOLERANCE)
  end
end 

describe "Math#hypot" do |it| 
  it.is "accessible as a private instance method" do
    IncludesMath.new.send(:hypot, 2, 3.1415).should_be_close(3.72411361937307, TOLERANCE)
  end
end
