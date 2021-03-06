require 'rails_admin/config/actions'
require 'rails_admin/config/actions/base'

module RailsAdminPublishNews
end

module RailsAdmin
  module Config
    module Actions
      class PublishNews < RailsAdmin::Config::Actions::Base

        register_instance_option :member? do
          true
        end
        register_instance_option :link_icon do
          'icon-check'
        end
        register_instance_option :controller do
          Proc.new do
            @object.publish
            flash[:notice] = "You have published the news item titled: #{@object.title}."
            redirect_to back_or_index
          end
        end

      end
    end
  end
end