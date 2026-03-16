class GenerateOgImageJob < ApplicationJob
  queue_as :default

  def perform(event_id)
    event = Event.find(event_id)
    OgImageGeneratorService.new(event).generate_and_attach
  rescue => e
    Rails.logger.error("OG image generation failed for event #{event_id}: #{e.message}")
    raise
  end
end
