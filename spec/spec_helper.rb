require 'rubygems'
require 'spec'
# http://github.com/defunkt/fakefs
require 'fakefs/safe'

$: << File.expand_path(File.dirname(__FILE__) + '/../lib')
module SpecHelpers
  def stub_environment_variables!(vars = {})
    vars.each do |name, value|
      ENV.should_receive(:[]).any_number_of_times.
        with(name.to_s).and_return value
    end
  end
end
