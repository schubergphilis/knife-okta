#
# Copyright 2018 Stephen Hoekstra <shoekstra@schubergphilis.com>
# Copyright 2018 Schuberg Philis
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require "bundler/setup"
require "chef/knife"
require "chef/knife/data_bag_from_okta_group"
require "oktakit"

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before(:each) do
    Chef::Config.reset
    Chef::Config[:knife] = {}

    Chef::Knife::DataBagFromOktaGroup.load_deps
  end
end

# Lifted from http://stackoverflow.com/questions/1480537/how-can-i-validate-exits-and-aborts-in-rspec
RSpec::Matchers.define :exit_with_code do |exp_code|
  actual = nil
  match do |block|
    begin
      block.call
    rescue SystemExit => e
      actual = e.status
    end
    actual && actual == exp_code
  end

  failure_message do |_block|
    "expected block to call exit(#{exp_code}) but exit" +
      (actual.nil? ? " not called" : "(#{actual}) was called")
  end

  failure_message_when_negated do |_block|
    "expected block not to call exit(#{exp_code})"
  end

  description do
    "expect block to call exit(#{exp_code})"
  end

  def supports_block_expectations?
    true
  end
end
