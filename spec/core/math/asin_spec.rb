# require File.dirname(__FILE__) + '/../../spec_helper'
# require File.dirname(__FILE__) + '/fixtures/classes'

# arcsine : (-1.0, 1.0) --> (-PI/2, PI/2)
describe "Math.asin" do |it| 
  it.returns " a float" do 
    Math.asin(1).class.should_equal(Float)
  end 
  
  it.returns "the arcsine of the argument" do   
    Math.asin(1).should_be_close(Math::PI/2, TOLERANCE)
    Math.asin(0).should_be_close(0.0, TOLERANCE)
    Math.asin(-1).should_be_close(-Math::PI/2, TOLERANCE)
    Math.asin(0.25).should_be_close(0.252680255142079, TOLERANCE)
    Math.asin(0.50).should_be_close(0.523598775598299, TOLERANCE)
    Math.asin(0.75).should_be_close(0.8480620789814816,TOLERANCE) 
  end
  
  it.raises " an ArgumentError if the argument cannot be coerced with Float()" do    
    lambda { Math.asin("test") }.should_raise(ArgumentError)
  end
  
  it.raises " a TypeError if the argument is nil" do
    lambda { Math.asin(nil) }.should_raise(TypeError)
  end

  it.will "accept any argument that can be coerced with Float()" do
    Math.asin(MathSpecs::Float.new).should_be_close(1.5707963267949, TOLERANCE)
  end
end

describe "Math#asin" do |it| 
  it.is "accessible as a private instance method" do
    IncludesMath.new.send(:asin, 0.5).should_be_close(0.523598775598299, TOLERANCE)
  end
end
