class CloseOutEventsJob < ApplicationJob
  include ActiveOriginOnly

  queue_as :default

  def perform
    Event.ready_to_close_out.find_each(&:finalised!)
  end
end
