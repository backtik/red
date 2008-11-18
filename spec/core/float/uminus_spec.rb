# require File.dirname(__FILE__) + '/../../spec_helper'

describe "Float#-@" do |it| 
  it.will "negate self" do
    (2.221.send(:-@)).should_be_close(-2.221, TOLERANCE)
    -2.01.should_be_close(-2.01,TOLERANCE)
    -2_455_999_221.5512.should_be_close(-2455999221.5512, TOLERANCE)
    (--5.5).should_be_close(5.5, TOLERANCE)
    -8.551.send(:-@).should_be_close(8.551, TOLERANCE)
  end
end
