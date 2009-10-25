require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe 'script/configure' do
  before { FakeFS.activate! }
  after { FakeFS.deactivate! }

  it "should create a config file" do
    stub_environment_variables! :FOG_MACHINE_CONFIG_FILE => nil,
      :HOME => '/home'
    default_path = File.join(ENV['HOME'], '.fmrc')

    File.exist?(default_path).should be_false
    run_config_script
    File.exist?(default_path).should be_true
    YAML.load(File.read(default_path)).should == {
        "access_key_id"=>"key",
        "secret_access_key"=>"secret",
        "worker_domain"=>"foo",
        "profile_domain"=>"bar"
      }
  end

  it "should create a config file to an environment specified location" do
    my_path = "/my/custom/config_file"
    stub_environment_variables! :FOG_MACHINE_CONFIG_FILE => my_path,
      :HOME => '/home'

    File.exist?(my_path).should be_false
    run_config_script
    File.exist?(my_path).should be_true
  end

  def run_config_script
    $stdin, $stdout = StringIO.new("key\nsecret\nfoo\nbar\n"), StringIO.new("")
    load File.expand_path(File.dirname(__FILE__) + '/../../script/configure')
    $stdin, $stdout = STDIN, STDOUT
  end

  def stub_environment_variables!(vars = {})
    vars.each do |name, value|
      ENV.should_receive(:[]).any_number_of_times.
        with(name.to_s).and_return value
    end
  end
end
