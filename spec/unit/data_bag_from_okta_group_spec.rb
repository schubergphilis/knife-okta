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

require "spec_helper"

describe Chef::Knife::DataBagFromOktaGroup do
  before(:each) do
    allow(subject).to receive(:config).and_return(config)
    allow(subject).to receive(:rest).and_return(rest)
    allow(subject.ui).to receive(:stdout).and_return(stdout)
    allow(subject).to receive(:okta_client).and_return(okta_client)
    allow(subject).to receive(:groups).and_return(okta_groups)

    allow(okta_client).to receive(:list_group_members).with("00gdqt4doz0QC1eF40h7").and_return([okta_group_membership_everyone])
    allow(okta_client).to receive(:list_group_members).with("00gdrphd5bUykSq4u0h7").and_return([okta_group_membership_family_guy])
    allow(okta_client).to receive(:list_group_members).with("00gdrpbvraOhKH6PF0h7").and_return([okta_group_membership_simpsons])

    subject.instance_variable_set(:@data_bag_name, data_bag_name)
    subject.instance_variable_set(:@data_bag_item_name, data_bag_item_name)
    subject.instance_variable_set(:@okta_groups, ["everyone"])
  end

  let(:okta_client) { double("Oktakit") }
  let(:okta_groups) do
    [
      { :id => "00gdqt4doz0QC1eF40h7", :type => "OKTA_GROUP", :profile => { :name => "Everyone" } },
      { :id => "00gdrphd5bUykSq4u0h7", :type => "OKTA_GROUP", :profile => { :name => "Family Guy" } },
      { :id => "00gdrpbvraOhKH6PF0h7", :type => "OKTA_GROUP", :profile => { :name => "Simpsons" } },
    ]
  end
  let(:okta_group_membership_everyone) do
    [
      {
        :id => "00udqt4drmCVwjVXj0h7",
        :status => "ACTIVE",
        :profile => { :displayName => "Stan Smith", :login => "StanSmith@example.com", :email => "StanSmith@example.com" },
      },
      {
        :id => "00udrpjj9fsbpxCoN0h7",
        :status => "ACTIVE",
        :profile => { :displayName => "Peter Griffin", :login => "PeterGriffin@example.com", :email => "PeterGriffin@example.com" },
      },
      {
        :id => "00udrpn3yw4Whp8mR0h7",
        :status => "ACTIVE",
        :profile => { :displayName => "Chris Griffin", :login => "ChrisGriffin@example.com", :email => "ChrisGriffin@example.com" },
      },
      {
        :id => "00udrpobkm2wS27sw0h7",
        :status => "ACTIVE",
        :profile => { :displayName => "Bart Simpson", :login => "BartSimpson@example.com", :email => "BartSimpson@example.com" },
      },
      {
        :id => "00udrpp8j7S5Q63KN0h7",
        :status => "ACTIVE",
        :profile => { :displayName => "Homer Simpson", :login => "HomerSimpson@example.com", :email => "HomerSimpson@example.com" },
      },
    ]
  end
  let(:okta_group_membership_family_guy) do
    [
      {
        :id => "00udrpjj9fsbpxCoN0h7",
        :status => "ACTIVE",
        :profile => { :displayName => "Peter Griffin", :login => "PeterGriffin@example.com", :email => "PeterGriffin@example.com" },
      },
      {
        :id => "00udrpn3yw4Whp8mR0h7",
        :status => "ACTIVE",
        :profile => { :displayName => "Chris Griffin", :login => "ChrisGriffin@example.com", :email => "ChrisGriffin@example.com" },
      },
    ]
  end
  let(:okta_group_membership_simpsons) do
    [
      {
        :id => "00udrpobkm2wS27sw0h7",
        :status => "ACTIVE",
        :profile => { :displayName => "Bart Simpson", :login => "BartSimpson@example.com", :email => "BartSimpson@example.com" },
      },
      {
        :id => "00udrpp8j7S5Q63KN0h7",
        :status => "ACTIVE",
        :profile => { :displayName => "Homer Simpson", :login => "HomerSimpson@example.com", :email => "HomerSimpson@example.com" },
      },
    ]
  end

  let(:config) { {} }
  let(:data_bag_name) { "users" }
  let(:data_bag_item_name) { "allowed_users" }
  let(:rest) { double("Chef::ServerAPI") }
  let(:stdout) { StringIO.new }

  let(:usage) do
    <<-EOF.gsub(/^ {6}/, "")
      knife data bag from okta group BAG ITEM GROUP [GROUP..] (options)
              --max-change MAX_CHANGE      Set the maximum amount of allowed changes
          -a OKTA_ATTRIBUTE,               Specify the user profile attribute to return
              --okta-attribute
          -o OKTA_ENDPOINT,                Set the Okta API endpoint (e.g. https://yourorg.okta.com/api/v1)
              --okta-endpoint
          -t, --okta-token OKTA_TOKEN      Set the Okta API token
              --show-changes               Show any changes when uploading a data bag item
              --show-members               Show data bag item members when uploading a data bag item
    EOF
  end

  subject { described_class.new }

  describe "#validate_arguments" do
    it "prints usage and exits 1 when cli has no arguments" do
      subject.name_args = []

      expect { subject.send :validate_arguments }.to exit_with_code(1)
      expect(stdout.string).to eq usage
    end

    it "prints usage and exits 1 when cli has one argument" do
      subject.name_args = [data_bag_name]

      expect { subject.send :validate_arguments }.to exit_with_code(1)
      expect(stdout.string).to eq usage
    end

    it "prints usage and exits 1 when cli has two arguments" do
      subject.name_args = [data_bag_name, data_bag_item_name]

      expect { subject.send :validate_arguments }.to exit_with_code(1)
      expect(stdout.string).to eq usage
    end

    it "returns nil when cli has three arguments" do
      subject.name_args = [data_bag_name, data_bag_item_name, "everyone"]

      expect(subject.send :validate_arguments).to eq(nil)
      expect(stdout.string).to eq ""
    end
  end

  describe "#validate_okta_config" do
    describe "using cli parameters" do
      it "prints fatal error and exits 1 when no --okta-attribute value specified" do
        subject.name_args = [data_bag_name, data_bag_item_name, "everyone"]

        expect(subject.ui).to receive(:fatal)
          .with("You must use specify an Okta identity profile attribute, either using --okta-endpoint or knife[:okta_endpoint] in your config.")
        expect { subject.send :validate_okta_config }.to exit_with_code(1)
      end

      it "prints fatal error and exits 1 when specifying an unsupported --okta-attribute value" do
        subject.name_args = [data_bag_name, data_bag_item_name, "everyone"]
        config[:okta_attribute] = "username"

        expect(subject.ui).to receive(:fatal)
          .with("Unsupported value for --okta-attribute, please specify either \"displayName\", \"email\" or \"login\".")
        expect { subject.send :validate_okta_config }.to exit_with_code(1)
      end

      it "prints fatal error and exits 1 when specifying a supported --okta-attribute value with incorrect case" do
        subject.name_args = [data_bag_name, data_bag_item_name, "everyone"]
        config[:okta_attribute] = "DisplayName"

        expect(subject.ui).to receive(:fatal)
          .with("Unsupported value for --okta-attribute, please specify either \"displayName\", \"email\" or \"login\".")
        expect { subject.send :validate_okta_config }.to exit_with_code(1)
      end

      it "prints fatal error and exits 1 when no --okta-endpoint value specified" do
        subject.name_args = [data_bag_name, data_bag_item_name, "everyone"]
        config[:okta_attribute] = "displayName"

        expect(subject.ui).to receive(:fatal)
          .with("You must use specify an Okta API endpoint, either using --okta-endpoint or knife[:okta_endpoint] in your config.")
        expect { subject.send :validate_okta_config }.to exit_with_code(1)
      end

      it "prints fatal error and exits 1 when no --okta-token value specified" do
        subject.name_args = [data_bag_name, data_bag_item_name, "everyone"]
        config[:okta_attribute] = "displayName"
        config[:okta_endpoint] = "https://example.okta.com/api/1"

        expect(subject.ui).to receive(:fatal)
          .with("You must use specify an Okta API token, either using --okta-token or knife[:okta_token] in your config.")
        expect { subject.send :validate_okta_config }.to exit_with_code(1)
      end

      it "returns nil when valid --okta-attribute, --okta-endpoint and --okta-token values specified" do
        subject.name_args = [data_bag_name, data_bag_item_name, "everyone"]
        config[:okta_attribute] = "displayName"
        config[:okta_endpoint] = "https://example.okta.com/api/1"
        config[:okta_token] = "123456"

        expect(subject.send :validate_okta_config).to eq(nil)
        expect(stdout.string).to eq ""
      end
    end

    describe "using environment variables" do
      before(:each) do
        allow(ENV).to receive(:[]).with("OKTA_ATTRIBUTE").and_return("displayName")
        allow(ENV).to receive(:[]).with("OKTA_ENDPOINT").and_return("https://example.okta.com/api/1")
        allow(ENV).to receive(:[]).with("OKTA_TOKEN").and_return("123456")
      end

      it "loads $OKTA_ATTRIBUTE value correctly" do
        subject.send :validate_okta_config

        expect(subject.config[:okta_attribute]).to eq("displayName")
      end

      it "loads $OKTA_ENDPOINT value correctly" do
        subject.send :validate_okta_config

        expect(subject.config[:okta_endpoint]).to eq("https://example.okta.com/api/1")
      end

      it "loads $OKTA_TOKEN value correctly" do
        subject.send :validate_okta_config

        expect(subject.config[:okta_token]).to eq("123456")
      end
    end
  end

  describe "#setup" do
    context "with a single okta group" do
      before(:each) do
        subject.name_args = [data_bag_name, data_bag_item_name, "everyone"]
        subject.send :setup
      end

      it "@data_bag_name has expected value" do
        expect(subject.instance_variable_get(:@data_bag_name)).to eq(data_bag_name)
      end

      it "@data_bag_item_name has expected value" do
        expect(subject.instance_variable_get(:@data_bag_item_name)).to eq(data_bag_item_name)
      end

      it "@okta_groups has expected value" do
        expect(subject.instance_variable_get(:@okta_groups)).to eq(["everyone"])
      end
    end

    context "with multiple okta groups" do
      before(:each) do
        subject.name_args = [data_bag_name, data_bag_item_name, "family guy,simpsons"]
        subject.send :setup
      end

      it "@data_bag_name has expected value" do
        expect(subject.instance_variable_get(:@data_bag_name)).to eq(data_bag_name)
      end

      it "@data_bag_item_name has expected value" do
        expect(subject.instance_variable_get(:@data_bag_item_name)).to eq(data_bag_item_name)
      end

      it "@okta_groups has expected value" do
        expect(subject.instance_variable_get(:@okta_groups)).to eq(["family guy", "simpsons"])
      end
    end
  end

  describe "#create_data_bag_if_missing" do
    context "when data bag does not exist" do
      # Lifted from https://github.com/chef/chef/blob/master/spec/unit/knife/data_bag_create_spec.rb#L61-L67
      before(:each) do
        exception = double("404 error", :code => "404")
        allow(rest).to receive(:get)
          .with("data/users")
          .and_raise(Net::HTTPServerException.new("404", exception))

        config[:okta_attribute] = "displayName"
      end

      it "creates data bag and prints info" do
        expect(rest).to receive(:post).with("data", { "name" => data_bag_name })
        expect(subject.ui).to receive(:info)
          .with("Created data_bag[users]")
        subject.send :create_data_bag_if_missing
      end
    end

    context "when data bag already exists" do
      before(:each) do
        allow(rest).to receive(:get).and_return(data_bag_name => "http://127.0.0.1:8889/data/#{data_bag_name}")
        config[:okta_attribute] = "displayName"
      end

      it "does not create data bag and prints info" do
        expect(rest).not_to receive(:post).with("data", { "name" => "users" })
        expect(subject.ui).to receive(:info)
          .with("Data bag users already exists")
        subject.send :create_data_bag_if_missing
      end
    end
  end

  describe "#create_data_bag_item_file" do
    context "when given a single okta group" do
      it "creates data bag json in a temp dir with expected content" do
        subject.instance_variable_set(:@okta_groups, ["simpsons"])
        config[:okta_attribute] = "displayName"

        file = double("file")
        hash = {
          "id" => "allowed_users",
          "displayName" => [
            "Bart Simpson",
            "Homer Simpson",
          ],
        }

        allow(subject).to receive(:data_bag_item_file).and_return("/tmp/#{data_bag_item_name}.json")
        expect(File).to receive(:open).with("/tmp/#{data_bag_item_name}.json", "w").and_yield(file)
        expect(file).to receive(:write).with(JSON.pretty_generate(hash))

        subject.send :create_data_bag_item_file
      end
    end

    context "when given multiple okta groups" do
      it "creates data bag json in a temp dir with expected content" do
        subject.instance_variable_set(:@okta_groups, ["family guy", "simpsons"])
        config[:okta_attribute] = "displayName"

        file = double("file")
        hash = {
          "id" => "allowed_users",
          "displayName" => [
            "Bart Simpson",
            "Chris Griffin",
            "Homer Simpson",
            "Peter Griffin",
          ],
        }

        allow(subject).to receive(:data_bag_item_file).and_return("/tmp/#{data_bag_item_name}.json")
        expect(File).to receive(:open).with("/tmp/#{data_bag_item_name}.json", "w").and_yield(file)
        expect(file).to receive(:write).with(JSON.pretty_generate(hash))

        subject.send :create_data_bag_item_file
      end
    end

    context "when given multiple okta groups with common users" do
      it "creates data bag json in a temp dir with expected content" do
        subject.instance_variable_set(:@okta_groups, ["everyone", "simpsons"])
        config[:okta_attribute] = "displayName"

        file = double("file")
        hash = {
          "id" => "allowed_users",
          "displayName" => [
            "Bart Simpson",
            "Chris Griffin",
            "Homer Simpson",
            "Peter Griffin",
            "Stan Smith",
          ],
        }

        allow(subject).to receive(:data_bag_item_file).and_return("/tmp/#{data_bag_item_name}.json")
        expect(File).to receive(:open).with("/tmp/#{data_bag_item_name}.json", "w").and_yield(file)
        expect(file).to receive(:write).with(JSON.pretty_generate(hash))

        subject.send :create_data_bag_item_file
      end
    end
  end

  describe "#display_data_bag_item_changes" do
    before(:each) do
      config[:show_changes] = true
    end

    describe "when a data bag doesn't exist" do
      before(:each) do
        exception = double("404 error", :code => "404")
        allow(rest).to receive(:get).and_raise(Net::HTTPServerException.new("404", exception))
        config[:okta_attribute] = "displayName"
      end

      it "prints info with data bag additions" do
        expect(subject.ui).to receive(:info)
          .with("The following will be added to the data bag item #{data_bag_item_name}:").once
        expect(subject.ui).to receive(:info)
          .with("  * Bart Simpson").once
        expect(subject.ui).to receive(:info)
          .with("  * Homer Simpson").once

        subject.instance_variable_set(:@okta_groups, ["simpsons"])
        subject.send :display_data_bag_item_changes
      end
    end

    describe "when adding data bag item values" do
      before(:each) do
        allow(rest).to receive(:get).and_return(data_bag_item)

        config[:okta_attribute] = "displayName"
      end

      let(:data_bag_item) do
        {
          "id": "allowed_users",
          "displayName": [],
        }
      end

      it "prints info with data bag additions" do
        expect(subject.ui).to receive(:info)
          .with("The following will be added to the data bag item #{data_bag_item_name}:").once
        expect(subject.ui).to receive(:info)
          .with("  * Bart Simpson").once
        expect(subject.ui).to receive(:info)
          .with("  * Homer Simpson").once

        subject.instance_variable_set(:@okta_groups, ["simpsons"])
        subject.send :display_data_bag_item_changes
      end
    end

    describe "when removing data bag item values" do
      before(:each) do
        allow(rest).to receive(:get).and_return(data_bag_item)

        config[:okta_attribute] = "displayName"
      end

      let(:data_bag_item) do
        {
          "id": "allowed_users",
          "displayName": [ "Bart Simpson", "Homer Simpson", "Stan Smith" ],
        }
      end

      it "prints info with data bag removals" do
        expect(subject.ui).to receive(:info)
          .with("The following will be removed from the data bag item #{data_bag_item_name}:").once
        expect(subject.ui).to receive(:info)
          .with("  * Stan Smith").once

        subject.instance_variable_set(:@okta_groups, ["simpsons"])
        subject.send :display_data_bag_item_changes
      end
    end

    describe "when adding and removing data bag item values" do
      before(:each) do
        allow(rest).to receive(:get).and_return(data_bag_item)

        config[:okta_attribute] = "displayName"
      end

      let(:data_bag_item) do
        {
          "id": "allowed_users",
          "displayName": [ "Homer Simpson", "Stan Smith" ],
        }
      end

      it "prints info with data bag removals and additions" do
        expect(subject.ui).to receive(:info)
          .with("The following will be removed from the data bag item #{data_bag_item_name}:").once
        expect(subject.ui).to receive(:info)
          .with("  * Stan Smith").once
        expect(subject.ui).to receive(:info)
          .with("The following will be added to the data bag item #{data_bag_item_name}:").once
        expect(subject.ui).to receive(:info)
          .with("  * Bart Simpson").once

        subject.instance_variable_set(:@okta_groups, ["simpsons"])
        subject.send :display_data_bag_item_changes
      end
    end
  end

  describe "#display_data_bag_item_members" do
    describe "when using --show-members option" do
      it "prints info with data bag contents" do
        subject.instance_variable_set(:@okta_groups, ["simpsons"])
        config[:okta_attribute] = "displayName"
        config[:show_members] = true

        expect(subject.ui).to receive(:info)
          .with("The data bag item will be uploaded with the following contents:").once
        expect(subject.ui).to receive(:info)
          .with("  * Bart Simpson").once
        expect(subject.ui).to receive(:info)
          .with("  * Homer Simpson").once

        subject.send :display_data_bag_item_members
      end
    end

    describe "when not using --show-members option" do
      it "does not print info with data bag contents" do
        expect(subject.ui).not_to receive(:info)

        subject.send :display_data_bag_item_members
      end
    end
  end

  describe "#group_hash" do
    context "when no group is found" do
      let(:okta_groups) do
        [
          { :id => "00gdrpbvraOhKH6PF0h6", :type => "APP_GROUP", :profile => { :name => "Simpsons" } },
        ]
      end

      it "prints fatal and exits 1" do
        expect(subject.ui).to receive(:fatal)
          .with("Cannot find a group with the name \"simpsons\" in the specified Okta tenant")
        expect { subject.send :group_hash, "simpsons" }.to exit_with_code(1)
      end
    end

    context "when there is one group type with matching name" do
      let(:okta_groups) do
        [
          { :id => "00gdrpbvraOhKH6PF0h7", :type => "OKTA_GROUP", :profile => { :name => "Simpsons" } },
        ]
      end

      it "returns group with type okta_group" do
        expect(subject.send(:group_hash, "simpsons")).to eq(
          { :id => "00gdrpbvraOhKH6PF0h7", :type => "OKTA_GROUP", :profile => { :name => "Simpsons" } }
        )
      end
    end

    context "when there is two group types with matching name" do
      let(:okta_groups) do
        [
          { :id => "00gdrpbvraOhKH6PF0h6", :type => "APP_GROUP", :profile => { :name => "Simpsons" } },
          { :id => "00gdrpbvraOhKH6PF0h7", :type => "OKTA_GROUP", :profile => { :name => "Simpsons" } },
        ]
      end

      it "returns group with type okta_group" do
        expect(subject.send(:group_hash, "simpsons")).to eq(
          { :id => "00gdrpbvraOhKH6PF0h7", :type => "OKTA_GROUP", :profile => { :name => "Simpsons" } }
        )
      end
    end
  end

  describe "#check_changes_within_range" do
    before(:each) do
      allow(rest).to receive(:get).and_return(data_bag_item)

      config[:okta_attribute] = "displayName"
    end

    let(:data_bag_item) do
      {
        "id": "allowed_users",
        "displayName": [
          "Stan Smith",
        ],
      }
    end

    it "returns nil when --max-change not specified" do
      config[:max_change] = 0

      expect(subject.send :check_changes_within_range).to eq(nil)
      expect(stdout.string).to eq ""
    end

    it "returns nil when --max-change=5 and there are 4 changes" do
      config[:max_change] = 5

      expect(subject.send :check_changes_within_range).to eq(nil)
      expect(stdout.string).to eq ""
    end

    it "prints fatal error and exits 1 when --max-change=3 and there are 4 changes" do
      config[:max_change] = 3

      expect(subject.ui).to receive(:fatal)
        .with("Data bag item allowed_users has more changes than --max-change allows (#{config[:max_change]}).")
      expect { subject.send :check_changes_within_range }.to exit_with_code(1)
    end
  end

  describe "#upload_data_bag_item" do
    let(:knife_data_bag_from_file) { double("Chef::Knife::DataBagFromFile") }

    context "when data bag item does not exist" do
      before do
        allow(Chef::Knife::DataBagFromFile).to receive(:new).and_return(knife_data_bag_from_file)
        allow(subject).to receive(:data_bag_item_file).and_return("/tmp/#{data_bag_item_name}.json")
      end

      it "does not prompt to overwrite and uploads data bag item" do
        allow(subject).to receive(:data_bag_item_exist?).and_return(false)

        expect(subject.ui).not_to receive(:confirm)
          .with("Data bag item #{data_bag_item_name} exists, overwrite it")
        expect(knife_data_bag_from_file).to receive(:ui=).with(subject.ui)
        expect(knife_data_bag_from_file).to receive(:name_args=).with([data_bag_name, "/tmp/#{data_bag_item_name}.json"])
        expect(knife_data_bag_from_file).to receive(:run)

        subject.send :upload_data_bag_item
      end
    end

    context "when data bag already exists" do
      before do
        allow(Chef::Knife::DataBagFromFile).to receive(:new).and_return(knife_data_bag_from_file)
        allow(subject).to receive(:data_bag_item_file).and_return("/tmp/#{data_bag_item_name}.json")
      end

      it "does prompt to overwrite and uploads data bag item" do
        allow(subject).to receive(:data_bag_item_exist?).and_return(true)

        expect(subject.ui).to receive(:confirm)
          .with("Data bag item #{data_bag_item_name} exists, overwrite it")
        expect(knife_data_bag_from_file).to receive(:ui=).with(subject.ui)
        expect(knife_data_bag_from_file).to receive(:name_args=).with([data_bag_name, "/tmp/#{data_bag_item_name}.json"])
        expect(knife_data_bag_from_file).to receive(:run)

        subject.send :upload_data_bag_item
      end
    end
  end
end
