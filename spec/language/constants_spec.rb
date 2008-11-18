# require File.dirname(__FILE__) + '/../spec_helper'
# require File.dirname(__FILE__) + '/fixtures/constants'

class StaticScope
  def chain
    ary = []
    ss = self
    while ss
      ary << ss.module
      ss = ss.parent
    end
    
    return ary
  end
end

describe "Constant lookup rule" do |it| 
  it.can "finds a toplevel constant" do
    Exception.should_equal(::Exception)
  end
  
  it.can "looks up the static, lexical scope in a class method" do
    ConstantSpecs::A::B::C.number.should_equal(47)
    ConstantSpecs::A::B::C.name.should_equal("specs")
    ConstantSpecs::A::B::C.place.should_equal("boston")
  end
  
  it.can "looks up the static, lexical scope in an instance method" do
    ConstantSpecs::A::B::C.new.number.should_equal(47)
    ConstantSpecs::A::B::C.new.name.should_equal("specs")
    ConstantSpecs::A::B::C.new.place.should_equal("boston")
  end
  
  it.can "looks up the superclass chain" do
    ConstantSpecs::D.new.number.should_equal(47)
    ConstantSpecs::D.number.should_equal(47)
  end
  
  it.can "isn't influenced by the calling scope" do
    ConstantSpecs::E.new.go.should_equal(8)
  end
  
  it.can "isn't influenced by the calling scope, in modules" do
    ConstantSpecs::I.new.go.should_equal(::Exception)
  end
  
  it.calls " const_missing on the original scope" do
    ConstantSpecs::A::B::C.new.fire_missing.should_equal(:missing!)
  end
  
  it.is "bound in blocks properly" do
    ConstantSpecs::Foo.foo.should_equal(47)
  end
  
  it.is "bound in blocks, then singletons properly" do
    ConstantSpecs::Foo.foo2.should_equal(47)
  end
  
  # This expectation leaves the 'LeftoverConstant' laying around in
  # the Object class.  Unfortunately, due to the nature of includes,
  # you can't remove constants from included modules.
  it.can "looks up in modules included in Object" do
    begin
      module M; LeftoverConstant = 42; end
      Object.send(:include, M)
      lambda { Object::LeftoverConstant }.should_not raise_error()
    ensure
      Object.send :remove_const, :M
    end
  end
  
  it.can "only searches a Module or Class" do
    lambda { :File::TEST }.should_raise(TypeError)
  end
end

describe "Constant declaration" do |it| 
  it.can "can be done under modules" do
    begin
      module M; end
      proc{ M::Z = 3 }.should_not raise_error()
    ensure
      Object.send :remove_const, :M
    end
  end

  it.can "can be done under classes" do
    begin
      class C; end
      proc{ C::Z = 3 }.should_not raise_error()
    ensure
      Object.send :remove_const, :C
    end
  end

  it.can "cannot be done under other types of constants" do
    begin
      V = 3
      proc{ V::Z = 3 }.should_raise(TypeError)
    ensure
      Object.send :remove_const, :V
    end
  end

  it.returns "the assigned variable" do
    begin
      module M; end
      (Y = 3).should_equal(3)
      (M::Z = 3).should_equal(3)
    ensure
      Object.send :remove_const, :Y
      Object.send :remove_const, :M rescue nil
    end
  end
end

