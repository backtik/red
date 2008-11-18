# require File.dirname(__FILE__) + '/../../spec_helper'
# require File.dirname(__FILE__) + '/fixtures/classes'

describe "Array#first" do |it| 
  it.returns "the first element" do
    %w{a b c}.first.should_equal('a')
    [nil].first.should_equal(nil)
  end
  
  it.returns "nil if self is empty" do
    [].first.should_equal(nil)
  end
  
  it.returns "the first count elements if given a count" do
    [true, false, true, nil, false].first(2).should_equal([true, false])
  end

  it.returns "an empty array when passed count on an empty array" do
    [].first(0).should_equal([])
    [].first(1).should_equal([])
    [].first(2).should_equal([])
  end
  
  it.returns "an empty array when passed count == 0" do
    [1, 2, 3, 4, 5].first(0).should_equal([])
  end
  
  it.returns "an array containing the first element when passed count == 1" do
    [1, 2, 3, 4, 5].first(1).should_equal([1])
  end
  
  it.raises " an ArgumentError when count is negative" do
    lambda { [1, 2].first(-1) }.should_raise(ArgumentError)
  end
  
  it.returns "the entire array when count > length" do
    [1, 2, 3, 4, 5, 9].first(10).should_equal([1, 2, 3, 4, 5, 9])
  end

  it.returns "an array which is independent to the original when passed count" do
    ary = [1, 2, 3, 4, 5]
    ary.first(0).replace([1,2])
    ary.should_equal([1, 2, 3, 4, 5])
    ary.first(1).replace([1,2])
    ary.should_equal([1, 2, 3, 4, 5])
    ary.first(6).replace([1,2])
    ary.should_equal([1, 2, 3, 4, 5])
  end

  it.can "properly handles recursive arrays" do
    empty = ArraySpecs.empty_recursive_array
    empty.first.should_equal(empty)

    ary = ArraySpecs.head_recursive_array
    ary.first.should_equal(ary)
  end

  it.tries "to convert the passed argument to an Integer using #to_int" do
    obj = mock('to_int')
    obj.should_receive(:to_int).and_return(2)
    [1, 2, 3, 4, 5].first(obj).should_equal([1, 2])
  end
  
  it.checks "whether the passed argument responds to #to_int" do
    obj = mock('method_missing to_int')
    obj.should_receive(:respond_to?).with(:to_int).any_number_of_times.and_return(true)
    obj.should_receive(:method_missing).with(:to_int).and_return(2)
    [1, 2, 3, 4, 5].first(obj).should_equal([1, 2])
  end

  it.raises " a TypeError if the passed argument is not numeric" do
    lambda { [1,2].first(nil) }.should_raise(TypeError)
    lambda { [1,2].first("a") }.should_raise(TypeError)

    obj = mock("nonnumeric")
    obj.should_receive(:respond_to?).with(:to_int).and_return(false)
    lambda { [1,2].first(obj) }.should_raise(TypeError)
  end

  it.does_not "return subclass instance when passed count on Array subclasses" do
    ArraySpecs::MyArray[].first(0).class.should_equal(Array)
    ArraySpecs::MyArray[].first(2).class.should_equal(Array)
    ArraySpecs::MyArray[1, 2, 3].first(0).class.should_equal(Array)
    ArraySpecs::MyArray[1, 2, 3].first(1).class.should_equal(Array)
    ArraySpecs::MyArray[1, 2, 3].first(2).class.should_equal(Array)
  end

  it.is_not " destructive" do
    a = [1, 2, 3]
    a.first
    a.should_equal([1, 2, 3])
    a.first(2)
    a.should_equal([1, 2, 3])
    a.first(3)
    a.should_equal([1, 2, 3])
  end
end
