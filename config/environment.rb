require 'rubygems'
require 'right_aws'
require 'aws/s3'
require 'net/ssh'
require 'yaml'
require 'config'

AWS::S3::Base.establish_connection!(
  :access_key_id => FogMachine::Config["access_key_id"],
  :secret_access_key => FogMachine::Config["secret_access_key"]
)

$: << File.dirname(__FILE__) + "/../lib"
require "recipe"
require "util"

Recipe.load!
