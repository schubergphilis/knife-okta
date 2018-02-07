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

class Chef
  class Knife
    class DataBagFromOktaGroup < Chef::Knife
      deps do
        require "chef/data_bag"
        require "chef/knife/data_bag_from_file"
        require "oktakit"
        require "tempfile"
        Chef::Knife::DataBagFromFile.load_deps
      end

      banner "knife data bag from okta group BAG ITEM GROUP [GROUP..] (options)"
      category "data bag"

      option :max_change,
             long: "--max-change MAX_CHANGE",
             description: "Set the maximum amount of allowed changes",
             default: 0,
             proc: proc { |key| key.to_i }

      option :okta_attribute,
             short: "-a OKTA_ATTRIBUTE",
             long: "--okta-attribute OKTA_ATTRIBUTE",
             description: "Specify the user profile attribute to return",
             proc: proc { |key| Chef::Config[:knife][:okta_attribute] = key }

      option :okta_endpoint,
             short: "-o OKTA_ENDPOINT",
             long: "--okta-endpoint OKTA_ENDPOINT",
             description: "Set the Okta API endpoint (e.g. https://yourorg.okta.com/api/v1)",
             proc: proc { |key| Chef::Config[:knife][:okta_endpoint] = key }

      option :okta_token,
             short: "-t OKTA_TOKEN",
             long: "--okta-token OKTA_TOKEN",
             description: "Set the Okta API token",
             proc: proc { |key| Chef::Config[:knife][:okta_token] = key }

      option :show_changes,
             long: "--show-changes",
             description: "Show any changes when uploading a data bag item",
             boolean: true,
             default: false

      option :show_members,
             long: "--show-members",
             description: "Show data bag item members when uploading a data bag item",
             boolean: true,
             default: false

      def run
        validate_arguments
        validate_okta_config
        setup

        begin
          Chef::DataBag.validate_name!(@data_bag_name)
        rescue Chef::Exceptions::InvalidDataBagName => e
          ui.fatal(e.message)
          exit(1)
        end

        if same_as_existing_data_bag_item?
          ui.info("Data bag item #{@data_bag_item_name} already exists and contains no changes, skipping upload")
          exit(0)
        end

        create_data_bag_if_missing
        create_data_bag_item_file
        display_data_bag_item_changes
        display_data_bag_item_members
        check_changes_within_range
        upload_data_bag_item
      ensure
        FileUtils.remove_entry tmpdir if tmpdir
      end

      private

      def validate_arguments
        return unless @name_args.size < 3
        ui.msg(opt_parser)
        exit(1)
      end

      def validate_okta_config
        config[:okta_attribute] ||= ENV["OKTA_ATTRIBUTE"] if ENV["OKTA_ATTRIBUTE"]
        config[:okta_endpoint] ||= ENV["OKTA_ENDPOINT"] if ENV["OKTA_ENDPOINT"]
        config[:okta_token] ||= ENV["OKTA_TOKEN"] if ENV["OKTA_TOKEN"]

        unless config[:okta_attribute]
          ui.fatal("You must use specify an Okta identity profile attribute, either using --okta-endpoint or knife[:okta_endpoint] in your config.")
          exit(1)
        end

        # This should probably be more dynamic, e.g. later on once we have a user hash to look if
        # the provided attribute matches a profile key and if not, fail, but for now we're OK with this.
        unless %w{displayName email login}.include?(config[:okta_attribute])
          ui.fatal('Unsupported value for --okta-attribute, please specify either "displayName", "email" or "login".')
          exit(1)
        end

        unless config[:okta_endpoint]
          ui.fatal("You must use specify an Okta API endpoint, either using --okta-endpoint or knife[:okta_endpoint] in your config.")
          exit(1)
        end

        unless config[:okta_token]
          ui.fatal("You must use specify an Okta API token, either using --okta-token or knife[:okta_token] in your config.")
          exit(1)
        end
      end

      def setup
        @data_bag_name = @name_args.shift
        @data_bag_item_name = @name_args.shift
        @okta_groups = @name_args.shift.split(',')
      end

      def tmpdir
        @tmpdir ||= Dir.mktmpdir
      end

      def attribute_key_values
        @attribute_key_values ||= values_for_key(config[:okta_attribute]).sort
      end

      def check_changes_within_range
        return if config[:max_change] == 0

        changes = data_bag_item_additions.size + data_bag_item_removals.size
        return if config[:max_change] > changes

        ui.fatal("Data bag item #{@data_bag_item_name} has more changes than --max-change allows (#{config[:max_change]}).")
        exit(1)
      end

      def values_for_key(key)
        values = []

        @okta_groups.each do |okta_group|
          group_members = active_group_members(group_id(okta_group))
          group_members.each do |group_member|
            values << group_member[:profile][key.to_sym]
          end
        end

        values.compact.sort.uniq
      end

      def same_as_existing_data_bag_item?
        return false if data_bag_item_data.nil?
        data_bag_item_data[config[:okta_attribute]] == attribute_key_values
      end

      def data_bag_item_data
        rest.get("data/#{@data_bag_name}/#{@data_bag_item_name}")
      rescue Net::HTTPServerException
        nil
      end

      def data_bag_item_exist?
        @data_bag_item_exists ||= data_bag_item_data
        @data_bag_item_exists.nil? ? false : true
      rescue Net::HTTPServerException
        false
      end

      def data_bag_item_file
        @data_bag_item_file ||= "#{tmpdir}/#{@data_bag_item_name}.json"
      end

      def create_data_bag_if_missing
      # Verify if the data bag exists
        rest.get("data/#{@data_bag_name}")
        ui.info("Data bag #{@data_bag_name} already exists")
      rescue Net::HTTPServerException => e
        raise unless e.to_s =~ /^404/
        # if it doesn't exists, try to create it
        rest.post("data", { "name" => @data_bag_name })
        ui.info("Created data_bag[#{@data_bag_name}]")
      end

      def create_data_bag_item_file
        hash = { "id" => @data_bag_item_name, config[:okta_attribute] => attribute_key_values }
        File.open(data_bag_item_file, "w") { |f| f.write(JSON.pretty_generate(hash)) }
      end

      def data_bag_item_additions
        return attribute_key_values if data_bag_item_data.nil?
        attribute_key_values - data_bag_item_data[config[:okta_attribute]]
      end

      def data_bag_item_removals
        return [] if data_bag_item_data.nil?
        data_bag_item_data[config[:okta_attribute]] - attribute_key_values
      end

      def display_data_bag_item_additions
        return if data_bag_item_additions.empty?
        ui.info("The following will be added to the data bag item #{@data_bag_item_name}:")
        data_bag_item_additions.each { |v| ui.info("  * #{v}") }
      end

      def display_data_bag_item_removals
        return if data_bag_item_removals.empty?
        ui.info("The following will be removed from the data bag item #{@data_bag_item_name}:")
        data_bag_item_removals.each { |v| ui.info("  * #{v}") }
      end

      def display_data_bag_item_changes
        return unless config[:show_changes]

        if data_bag_item_data.nil?
          display_data_bag_item_additions
        elsif data_bag_item_data.keys.reject { |e| e == "id" }.shift.to_s == config[:okta_attribute]
          display_data_bag_item_removals
          display_data_bag_item_additions
        else
          ui.info("A new Okta profile attribute has been specified, replacing existing data bag item with the following:")
          attribute_key_values.each { |v| ui.info("  * #{v}") }
        end
      end

      def display_data_bag_item_members
        return unless config[:show_members]

        ui.info("The data bag item will be uploaded with the following contents:")
        attribute_key_values.each { |v| ui.info("  * #{v}") }
      end

      def upload_data_bag_item
        ui.confirm("Data bag item #{@data_bag_item_name} exists, overwrite it") if data_bag_item_exist?

        knife_data_bag_from_file = Chef::Knife::DataBagFromFile.new
        knife_data_bag_from_file.ui = ui
        knife_data_bag_from_file.name_args = [@data_bag_name, data_bag_item_file]
        knife_data_bag_from_file.run
      end

      # Okta

      def okta_client
        @okta_client ||= Oktakit.new(token: config[:okta_token], api_endpoint: config[:okta_endpoint])
      end

      def groups
        @groups ||= okta_client.list_groups.shift
      end

      def group_hash(group_name)
        group_hash = groups.select { |group| group[:type] == "OKTA_GROUP" && group[:profile][:name] =~ /^#{group_name}$/i }.shift
        if group_hash.nil?
          ui.fatal("Cannot find a group with the name \"#{group_name}\" in the specified Okta tenant")
          exit(1)
        end
        group_hash
      end

      def group_id(group_name)
        group_hash(group_name)[:id]
      end

      def active_group_members(group_id)
        okta_client.list_group_members(group_id).shift.select { |user| user[:status] == "ACTIVE" }
      end

      def users
        @users ||= okta_client.list_users.shift
      end

      def user_hash(user_name)
        user_hash = users.select { |user| user.profile.displayName =~ /^#{user_name}$/i }.shift
        if user_hash.nil?
          ui.info("Cannot find a user with the name \"#{user_name}\" in the specified Okta tenant")
        end
        user_hash
      end

      def okta_user_active?(user_name)
        user_hash(user_name).status == "ACTIVE"
      rescue NoMethodError
        false
      end
    end
  end
end
