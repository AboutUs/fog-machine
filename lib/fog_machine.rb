$: << File.dirname(__FILE__) + '/../config'
require 'environment'

class FogMachine
  class << self
    def sdb_servers
      Util.sdb_items(CONFIG["worker_domain"]).inject({}) do |_, item|
        _[item.keys.first] = item.values.first

        _
      end
    end

    def clean_sdb
      usable_instance_ids = usable_servers.collect { |i| i[:aws_instance_id] }
      sdb_servers.keys.reject do |id|
        usable_instance_ids.include? id
      end.each do |inactive_id|
        sdb.delete_attributes CONFIG["worker_domain"], inactive_id
      end
    end

    def servers
      server_metadata = sdb_servers

      servers = active_servers.collect do |data|
        Instance.new data, server_metadata[data[:aws_instance_id]]
      end

      InstanceArray.new(servers)
    end

    def active_servers
      ec2.describe_instances
    end

    def usable_servers
      active_servers.select { |i| i[:aws_state] == "running" || i[:aws_state] == "pending" }
    end

    def running_servers
      active_servers.select { |i| i[:aws_state] == "running" }
    end

    def recipe(name)
      rcp = Recipe.get(name)
      servers.active.with_profile(rcp.get_profile).run_command rcp.get_command
    end

    def recipes(*names)
      names.each { |name| recipe name }
    end

    def ec2
      RightAws::Ec2.new CONFIG["access_key_id"],
        CONFIG["secret_access_key"],
        :logger => logger
    end

    def sdb
      RightAws::SdbInterface.new CONFIG["access_key_id"],
        CONFIG["secret_access_key"],
        :multi_thread => true,
        :logger => logger
    end

    def logger
      Logger.new("/dev/null")
    end

    def launch(options = {})
      print "Cleaning out inactive instances... "
      clean_sdb
      puts "Done"

      options = {:count => 1}.merge options

      tag = options.delete :profile

      profile = Profile.get(tag).inject({}) do |_, (key, value)|
        _[key.to_sym] = value.first

        _
      end

      count = options.delete :count

      ami = profile.delete :ami

      user_data_filename = profile.delete(:user_data_filename)
      user_data = File.read(user_data_filename) if user_data_filename && !user_data_filename.empty?

      launch_options = profile.merge({:min_count => count, :max_count => count, :user_data => user_data})

      launch_options = launch_options.merge options

      response = ec2.launch_instances ami, launch_options

      response.each do |server|
        sdb.put_attributes CONFIG["worker_domain"], server[:aws_instance_id], {'profile' => tag, 'started_at' => Time.now.to_i}
      end
    end
  end

  class InstanceArray < Array
    def active
      select &:active?
    end

    def with_profile(profile)
      select { |i| i.from_profile == profile }
    end

    def select
      self.class.new(super)
    end

    def run(command, concurrent = true)
      concurrent ? run_concurrently(command) : run_serially(command)
    end
    alias_method :run_command, :run

    def run_serially(command)
      map { |i| send_to_instance(i, command)}
    end

    def run_concurrently(command)
      map do |i|
        Thread.new do
          Thread.current[:result] = send_to_instance(i, command)
        end
      end.map{|t| t.join; t[:result] }
    end

    def silence_output
      @silence_output = true
    end

    def unsilence_output
      @silence_output = false
    end

    def silence_output?
      !!@silence_output
    end

    private
    def send_to_instance instance, command
      r = instance.run_command(command)
      puts r unless silence_output?
      r
    end
  end

  class Instance
    def initialize(data, metadata)
      @data, @metadata = data, metadata
    end

    def active?
      state == "running"
    end

    def metadata
      @metadata || {}
    end

    def method_missing(method, *args)
      @data[method] or @data[:"aws_#{method}"] or super
    end

    def id
      @data[:aws_instance_id]
    end

    def from_profile
      self['profile']
    end

    def run_command(command)
      puts "#{id} >> Running: #{command}"
      result = nil
      Net::SSH.start(dns_name, "root",
                     :keys => [keyfile],
                     :auth_methods => ['publickey']) do |ssh|
        result = ssh.exec!(command)
      end

      result = result.strip if result.respond_to?(:strip)
    end

    def keyfile
      file = "/www/aboutus/secrets/aws/#{ssh_key_name}-key"
      raise "no keyfile exists" unless File.exists? file

      file
    end

    def inspect
      "<FogMachine::Instance #{id}>"
    end

    def []=(key, val)
      FogMachine.sdb.put_attributes CONFIG["worker_domain"], id, {key => val}
    end

    def [](key)
      (metadata[key] || []).first
    end

    def ssh_command
      "ssh -i #{keyfile} root@#{dns_name}"
    end

    def ssh!
      %x{osascript -e 'tell app "System Events" to set termOn to (exists process "Terminal")' -e 'set cmd to "#{ssh_command}"' -e 'if (termOn) then' -e 'tell app "Terminal" to do script cmd' -e 'else' -e 'tell app "Terminal" to do script cmd in front window' -e 'end if' -e 'tell app "Terminal" to activate'}
    end
  end

  class Profile < Hash
    attr_accessor :name

    def initialize(name, attrs = {})
      @name = name
      merge! attrs
    end

    def save
      self.class.save name, self
    end

    class << self
      def get(name)
        attrs = sdb.get_attributes(CONFIG["profile_domain"], name)[:attributes]
        new name, attrs
      end

      def all
        Util.sdb_items(CONFIG["profile_domain"]).map do |data|
          new data.keys.first, data.values.first
        end
      end

      def save(name, attrs)
        sdb.put_attributes CONFIG["profile_domain"], name, attrs, true
      end

      def sdb
        FogMachine.sdb
      end
    end
  end
end

FM = FogMachine unless defined? FM
