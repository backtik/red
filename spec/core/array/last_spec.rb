# require File.dirname(__FILE__) + '/../../spec_helper'
# require File.dirname(__FILE__) + '/fixtures/classes'

describe "Array#last" do |it| 
  it.returns "the last element" do
    [1, 1, 1, 1, 2].last.should_equal(2)
  end
  
  it.returns "nil if self is empty" do
    [].last.should_equal(nil)
  end
  
  it.returns "the last count elements if given a count" do
    [1, 2, 3, 4, 5, 9].last(3).should_equal([4, 5, 9])
  end

  it.returns "an empty array when passed a count on an empty array" do
    [].last(0).should_equal([])
    [].last(1).should_equal([])
  end
  
  it.returns "an empty array when count == 0" do
    [1, 2, 3, 4, 5].last(0).should_equal([])
  end

  it.returns "an array containing the last element when passed count == 1" do
    [1, 2, 3, 4, 5].last(1).should_equal([5])
  end

  it.raises " an ArgumentError when count is negative" do
    lambda { [1, 2].last(-1) }.should_raise(ArgumentError)
  end
  
  it.returns "the entire array when count > length" do
    [1, 2, 3, 4, 5, 9].last(10).should_equal([1, 2, 3, 4, 5, 9])
  end

  it.returns "an array which is independent to the original when passed count" do
    ary = [1, 2, 3, 4, 5]
    ary.last(0).replace([1,2])
    ary.should_equal([1, 2, 3, 4, 5])
    ary.last(1).replace([1,2])
    ary.should_equal([1, 2, 3, 4, 5])
    ary.last(6).replace([1,2])
    ary.should_equal([1, 2, 3, 4, 5])
  end

  it.can "properly handles recursive arrays" do
    empty = ArraySpecs.empty_recursive_array
    empty.last.should_equal(empty)

    array = ArraySpecs.recursive_array
    array.last.should_equal(array)
  end

  it.tries "to convert the passed argument to an Integer usinig #to_int" do
    obj = mock('to_int')
    obj.should_receive(:to_int).and_return(2)
    [1, 2, 3, 4, 5].last(obj).should_equal([4, 5])
  end

  it.can "check whether the passed argument responds to #to_int" do
    obj = mock('method_missing to_int')
    obj.should_receive(:respond_to?).with(:to_int).any_number_of_times.and_return(true)
    obj.should_receive(:method_missing).with(:to_int).and_return(2)
    [1, 2, 3, 4, 5].last(obj).should_equal([4, 5])
  end

  it.raises " a TypeError if the passed argument is not numeric" do
    lambda { [1,2].last(nil) }.should_raise(TypeError)
    lambda { [1,2].last("a") }.should_raise(TypeError)

    obj = mock("nonnumeric")
    obj.should_receive(:respond_to?).with(:to_int).and_return(false)
    lambda { [1,2].last(obj) }.should_raise(TypeError)
  end

  it.does_not "return subclass instance on Array subclasses" do
    ArraySpecs::MyArray[].last(0).class.should_equal(Array)
    ArraySpecs::MyArray[].last(2).class.should_equal(Array)
    ArraySpecs::MyArray[1, 2, 3].last(0).class.should_equal(Array)
    ArraySpecs::MyArray[1, 2, 3].last(1).class.should_equal(Array)
    ArraySpecs::MyArray[1, 2, 3].last(2).class.should_equal(Array)
  end

  it.is_not " destructive" do
    a = [1, 2, 3]
    a.last
    a.should_equal([1, 2, 3])
    a.last(2)
    a.should_equal([1, 2, 3])
    a.last(3)
    a.should_equal([1, 2, 3])
  end
end
