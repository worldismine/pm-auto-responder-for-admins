# name: discourse-pm-auto-responder-for-admins
# version: 0.6.1
# authors: Muhlis Budi Cahyono (muhlisbc@gmail.com)
# url: https://github.com/muhlisbc

enabled_site_setting :enable_pm_auto_responder_for_admins

DiscoursePluginRegistry.serialized_current_user_fields << "mmn_auto_respond_pm"
DiscoursePluginRegistry.serialized_current_user_fields << "mmn_auto_respond_message"

after_initialize {

  register_editable_user_custom_field("mmn_auto_respond_pm")
  register_editable_user_custom_field("mmn_auto_respond_message")

  module ::Jobs
    class SendAutoResponderMsg < ::Jobs::Base

      def execute(args)
        post = Post.find_by(id: args[:post_id])

        return unless post

        topic = post.topic

        admins    = User.where("id > ?", 0).where(admin: true) # select admins
        user_ids  = topic.topic_allowed_users.pluck(:user_id)

        counter = 0

        admins.each do |admin|
          next unless user_ids.include?(admin.id)
          next unless admin.custom_fields["mmn_auto_respond_pm"]

          auto_respond_msg = admin.custom_fields["mmn_auto_respond_message"].to_s.strip
          next unless auto_respond_msg.length > 0

          diff_time   = Time.now.to_i - topic.custom_fields["last_auto_respond_by_admin_#{admin.id}"].to_i
          delay_secs  = SiteSetting.delay_between_auto_responder_message_in_hour.to_i.hour.to_i

          next unless diff_time >= delay_secs

          opts = {
            topic_id: topic.id,
            raw: auto_respond_msg,
            skip_validation: true
          }

          PostCreator.create!(admin, opts)
          topic.custom_fields["last_auto_respond_by_admin_#{admin.id}"] = Time.now.to_i

          counter += 1
        end

        topic.save! if counter > 0
      end
    end
  end

  require_dependency "post"
  Post.class_eval {
    after_commit :send_auto_responder, on: :create

    def send_auto_responder
      return if !SiteSetting.enable_pm_auto_responder_for_admins

      return if !topic.private_message? # return if regular topic

      return if user.admin # return if message is sent by admin

      Jobs.enqueue(:send_auto_responder_msg, post_id: self.id)
    end
  }

  User.register_custom_field_type("mmn_auto_respond_pm", :boolean)
  User.register_custom_field_type("mmn_auto_respond_message", :text)

  module ::MmnAutoRespondPm
    class Engine < ::Rails::Engine
      engine_name "mmn_auto_respond_pm"
      isolate_namespace MmnAutoRespondPm
    end
  end

  #require_dependency "application_controller"
  class MmnAutoRespondPm::MmnController < ::ApplicationController

    def enable
      set_auto_responder(true)
    end

    def disable
      set_auto_responder(false)
    end

    def is_enabled
      render json: {is_enabled: current_user.custom_fields["mmn_auto_respond_pm"]}
    end

    private

    def set_auto_responder(bool)
      status = if SiteSetting.enable_pm_auto_responder_for_admins && current_user && current_user.admin
          current_user.custom_fields["mmn_auto_respond_pm"] = bool
          current_user.save!
          "ok"
        else
          "error"
        end

      render json: {status: status}
    end

  end

  MmnAutoRespondPm::Engine.routes.draw do
    get "/enable"        => "mmn#enable"
    get "/disable"       => "mmn#disable"
    get "/is_enabled"    => "mmn#is_enabled"
  end

  Discourse::Application.routes.append do
    mount ::MmnAutoRespondPm::Engine, at: "mmn_auto_respond_pm"
  end

}

register_asset "stylesheets/pm-auto-responder.scss"
