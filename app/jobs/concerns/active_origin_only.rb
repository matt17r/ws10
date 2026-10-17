module ActiveOriginOnly
  extend ActiveSupport::Concern

  mattr_accessor :active_origin_check, instance_accessor: false, default: -> {
    !Rails.env.production? || system(Rails.root.join("script/cf_active_check").to_s, out: File::NULL, err: File::NULL)
  }

  included do
    around_perform do |job, block|
      if ActiveOriginOnly.active_origin_check.call
        block.call
      else
        Rails.logger.info "#{job.class.name} skipped: this host isn't the active origin"
      end
    end
  end
end
