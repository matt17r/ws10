class GenerateOgImageJob < ApplicationJob
  queue_as :default

  def perform(event_id)
    event = Event.find(event_id)
    OgImageGeneratorService.new(event).generate_and_attach
  end
end
