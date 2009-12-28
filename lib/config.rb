class FogMachine
  module Config
    extend self
    def config_file_path
      File.expand_path(ENV['FOG_MACHINE_CONFIG_FILE'] ||
          File.join(ENV['HOME'], ".fmrc"))
    end

    # Default configuration.  Can be overriden in config file.
    def defaults
      {
        'recipe_directory' => File.expand_path(File.join(File.dirname(__FILE__), %w[ .. recipes ]))
      }
    end

    def [] key
      raise "Use string keys" unless key.is_a? String
      raise "No config file. Run script/configure" unless File.exist? config_file_path
      defaults.merge(YAML.load_file(config_file_path))[key] ||
          raise("Couldn't find #{key.inspect} in #{config_file_path.inspect}.  Run script/configure")
    end
  end
end
