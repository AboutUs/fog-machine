class Recipe
  RECIPE_DIR = File.dirname(__FILE__) + "/../recipes"
  class << self
    def define_command(cmd_str = nil, &cmd_block)
      if cmd_str and block_given?
        raise ArgumentError, "pass commands as a string or a block, but not both"
      end
      @commands ||= []
      @commands << (block_given? ? cmd_block : cmd_str)
    end
    alias_method :commands, :define_command

    def profile(profile_str)
      @profile = profile_str
    end

    def get_profile
      @profile.to_s if @profile
    end

    def get_command
      return unless @commands and !@commands.empty?
      ((@before_commands || []) + (@commands || [])).map do |c|
        c = c.call if c.respond_to? :call
        c.split("\n")
      end.join(" && ")
    end

    def get(name)
      name.camelize.constantize
    end

    def load!
      with_recipe_files{|file| require file[0..file.length-4]}
    end

    def reload!
      with_recipe_files{|file| load file}
    end

    def with_recipe_files
      Dir[File.join(RECIPE_DIR, "**", "*.rb")].each{|file| yield file }
    end
  end
end
