require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'recipe'

describe Recipe do
  # create an anonymous recipe class so we don't run into naming conflicts as
  # the test suite grows
  def define_recipe(parent_recipe = Recipe, &class_body)
    Class.new(parent_recipe, &class_body)
  end

  describe "an empty recipe" do
    before { @empty_recipe = define_recipe }

    it "get command should return nil" do
      @empty_recipe.get_command.should be_nil
    end

    it "get profile should return nil" do
      @empty_recipe.get_profile.should be_nil
    end
  end


  describe "a simple recipe" do
    before do
      @simple_recipe = define_recipe do
        profile :foobaz
        commands "foo\nbar"
      end
    end

    it "get command should return lines joined with &&" do
      @simple_recipe.get_command.should == "foo && bar"
    end

    it "get profile should return string of profile" do
      @simple_recipe.get_profile.should == "foobaz"
    end
  end

  describe "with hooks" do
    before do
      @hooked_recipe = define_recipe do
        define_command "git checkout foo"
        define_command "foo\nbar"
      end
    end

    it "should && commands together" do
      @hooked_recipe.get_command.should == "git checkout foo && foo && bar"
    end
  end

  describe "lazy loading commands" do
    describe "with one command" do
      before do
        @recipe = define_recipe do
          commands do
            raise "this shouldn't be evalutated until the command is called"
          end
        end
      end

      it "should evaluate the commands lazily" do
        lambda do
          @recipe.get_command
        end.should raise_error("this shouldn't be evalutated until the command is called")
      end
    end
  end

  describe "defining commands" do
    it "should allow a string or a block but not both" do
      lambda do
        define_recipe do
          commands("ls"){ "ls" }
        end
      end.should raise_error(ArgumentError)
    end
  end
end
