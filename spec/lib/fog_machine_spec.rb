require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'fog_machine'

describe FogMachine do

  describe FogMachine::InstanceArray do
    def mock_instance mocks = {}
      mock("Instance", :run_command => "running ssh command")
    end

    before do
      @array = FogMachine::InstanceArray.new 5 do
        mock_instance
      end
      @array.silence_output
    end

    it "should run_command on all instances" do
      @array.each{|m| m.should_receive(:run_command).and_return{@i||=0; @i+=1}}
      @array.run_serially("hello").should == (1..5).map
    end

    it "should run commands concurrently" do
      @array.each{|m| m.should_receive(:run_command).and_return{@i||=0; @i+=1}}
      @array.run_concurrently("hello").should == (1..5).map.sort
    end

    it "should run concurrently by default" do
      @array.should_receive(:run_concurrently)
      @array.run("hello")
    end

    it "should run serially if passed a second false argument" do
      @array.should_receive(:run_serially)
      @array.run("hello", false)
    end
  end
end
