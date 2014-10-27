require 'rspec'
require 'chefspec'


RSpec.configure do |config|
  config.fail_fast = true
  config.version = '14.04'
  config.platform = 'ubuntu'
  config.cookbook_path = Array(File.expand_path("../cookbooks" ,  __FILE__))
  config.role_path = Array(File.expand_path("../roles",  __FILE__))
  config.run_all_when_everything_filtered = true
  config.filter_run :focus
  config.backtrace_exclusion_patterns = []
end
