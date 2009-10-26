require 'rubygems'
require 'right_aws'
require 'aws/s3'
require 'net/ssh'
require 'yaml'

CONFIG_FILE = File.expand_path(ENV['FOG_MACHINE_CONFIG_FILE'] ||
                               File.join(ENV['HOME'], ".fmrc"))
raise "No config file. Run script/configure" unless File.exist? CONFIG_FILE
CONFIG = YAML.load_file CONFIG_FILE

AWS::S3::Base.establish_connection!(
  :access_key_id => CONFIG["access_key_id"],
  :secret_access_key => CONFIG["secret_access_key"]
)

$: << File.dirname(__FILE__) + "/../lib"
require "recipe"
require "util"

Recipe.load!
