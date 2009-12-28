require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'fog_machine'
require 'config'
describe FogMachine::Config do
  include SpecHelpers
  describe "config file" do
    it "should look to ~/.fmrc by default" do
      stub_environment_variables!(:HOME => '/home/foo', :FOG_MACHINE_CONFIG_FILE => nil)
      FogMachine::Config.config_file_path.should == '/home/foo/.fmrc'
    end

    it "should be overrideable" do
      stub_environment_variables!(:HOME => '/home/foo', :FOG_MACHINE_CONFIG_FILE => '/foo/bar/baz.yml')
      FogMachine::Config.config_file_path.should == '/foo/bar/baz.yml'
    end
  end

  describe "defaults" do
    it "should have a default recipes path" do
      FakeFS do
        File.open(FogMachine::Config.config_file_path, 'w') do |f|
          config = FogMachine::Config.defaults
          config.delete('recipe_directory')
          f.puts YAML.dump(config)
        end
        FogMachine::Config['recipe_directory'].should == File.expand_path(File.join(File.dirname(__FILE__), %w[ .. .. recipes ]))
      end
    end

    it "should allow the recipes path to be overriden" do
      FakeFS do
        File.open(FogMachine::Config.config_file_path, 'w') do |f|
          f.puts YAML.dump(FogMachine::Config.defaults.merge('recipe_directory' => '/foo/bar/baz'))
        end
        FogMachine::Config['recipe_directory'].should == '/foo/bar/baz'
      end
    end
  end

  it "should get pissy if symbols are passed as keys" do
    lambda do
      FogMachine::Config[:foobar]
    end.should raise_error
  end

  it "should raise an error if a config variable is accessed that doesn't exist" do
    lambda do
      FogMachine::Config["a-config-var"]
    end.should raise_error(%r|Run script/configure|i)
  end

end
