# require File.dirname(__FILE__) + '/../spec_helper'
# require File.dirname(__FILE__) + '/fixtures/array'

describe "Array literals" do |it|
  it.can "[] should return a new array populated with the given elements" do
    array = [1, 'a', nil]
    array.class.should_equal(Array)
    array[0].should_equal(1)
    array[1].should_equal('a')
    array[2].should_equal(nil)
  end

  it.can "[] treats empty expressions as nil elements" do
    array = [0, (), 2, (), 4]
    array.should_be_kind_of(Array)
    array[0].should_equal(0)
    array[1].should_equal(nil)
    array[2].should_equal(2)
    array[3].should_equal(nil)
    array[4].should_equal(4)
  end
end

describe "Bareword array literal" do |it| 
  it.can "%w() transforms unquoted barewords into an array" do
    a = 3
    %w(a #{3+a} 3).should_equal(["a", '#{3+a}', "3"])
  end

  it.can "%W() transforms unquoted barewords into an array, supporting interpolation" do
    a = 3
    %W(a #{3+a} 3).should_equal(["a", '6', "3"])
  end

  it.can "%W() always treats interpolated expressions as a single word" do
    a = "hello world"
    %W(a b c #{a} d e).should_equal(["a", "b", "c", "hello world", "d", "e"])
  end

  it.can "treats consecutive whitespace characters the same as one" do
    %w(a  b c  d).should_equal(["a", "b", "c", "d"])
    %W(hello
       world).should_equal(["hello", "world"])
  end

  it.can "treats whitespace as literals characters when escaped by a backslash" do
    %w(a b\ c d e).should_equal(["a", "b c", "d", "e"])
    %w(a b\
c d).should_equal(["a", "b\nc", "d"])
    %W(a\  b\tc).should_equal(["a ", "b\tc"])
    %W(white\  \  \ \  \ space).should_equal(["white ", " ", "  ", " space"])
  end
end

describe "The unpacking splat operator (*)" do |it| 
  it.can "when applied to a literal nested array, unpacks its elements into the containing array" do
    [1, 2, *[3, 4, 5]].should_equal([1, 2, 3, 4, 5])
  end

  it.can "when applied to a nested referenced array, unpacks its elements into the containing array" do
    splatted_array = [3, 4, 5]
    [1, 2, *splatted_array].should_equal([1, 2, 3, 4, 5])
  end

  it.can "unpacks the start and count arguments in an array slice assignment" do
    alphabet_1 = ['a'..'z'].to_a
    alphabet_2 = alphabet_1.dup
    start_and_count_args = [1, 10]

    alphabet_1[1, 10] = 'a'
    alphabet_2[*start_and_count_args] = 'a'

    alphabet_1.should_equal(alphabet_2)
  end

  it.can "unpacks arguments as if they were listed statically" do
    static = [1,2,3,4]
    receiver = static.dup
    args = [0,1]
    static[0,1] = []
    static.should_equal([2,3,4])
    receiver[*args] = []
    receiver.should_equal(static)
  end

  it.can "unpacks a literal array into arguments in a method call" do
    tester = ArraySpec::Splat.new
    tester.unpack_3args(*[1, 2, 3]).should_equal([1, 2, 3])
    tester.unpack_4args(1, 2, *[3, 4]).should_equal([1, 2, 3, 4])
    tester.unpack_4args("a", %w(b c), *%w(d e)).should_equal(["a", ["b", "c"], "d", "e"])
  end

  it.can "unpacks a referenced array into arguments in a method call" do
    args = [1, 2, 3]
    tester = ArraySpec::Splat.new
    tester.unpack_3args(*args).should_equal([1, 2, 3])
    tester.unpack_4args(0, *args).should_equal([0, 1, 2, 3])
  end
end

describe "The packing splat operator (*)" do |it| 
  
end
