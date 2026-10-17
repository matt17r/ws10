class CloseOutEventsJob < ApplicationJob
  queue_as :default

  cattr_accessor :active_origin_check, default: -> {
    !Rails.env.production? || system(Rails.root.join("script/cf_active_check").to_s, out: File::NULL, err: File::NULL)
  }

  def perform
    unless active_origin_check.call
      Rails.logger.info "CloseOutEventsJob skipped: this host isn't the active origin"
      return
    end

    Event.ready_to_close_out.find_each(&:finalised!)
  end
end
