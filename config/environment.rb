require 'rubygems'
require 'right_aws'
require 'aws/s3'
require 'net/ssh'
require 'yaml'

CONFIG_FILE = File.expand_path File.join(ENV['HOME'], ".fmrc")
CONFIG = YAML.load_file CONFIG_FILE

AWS::S3::Base.establish_connection!(
  :access_key_id => CONFIG["access_key_id"],
  :secret_access_key => CONFIG["secret_access_key"]
)

$: << File.dirname(__FILE__) + "/../lib"
require "recipe"
require "util"
RECIPE_DIR = File.dirname(__FILE__) + "/../recipes"

Recipe.load!
