require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'fakefs/safe'

describe 'script/configure' do
  before { FakeFS.activate! }
  after { FakeFS.deactivate! }

  def run_config_script
    $stdin, $stdout = StringIO.new("key\nsecret\nfoo\nbar\n"), StringIO.new("")
    load File.expand_path(File.dirname(__FILE__) + '/../../script/configure')
    $stdin, $stdout = STDIN, STDOUT
  end

  it "should create a config file" do
    File.exist?(File.join(ENV['HOME'], '.fmrc')).should be_false
    run_config_script
    File.exist?(File.join(ENV['HOME'], '.fmrc')).should be_true
    YAML.load(File.read(File.join(ENV['HOME'], '.fmrc'))).
      should == {
        "access_key_id"=>"key",
        "secret_access_key"=>"secret",
        "worker_domain"=>"foo",
        "profile_domain"=>"bar"
      }
  end
end
