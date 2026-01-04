namespace :db do
  desc "Associate existing events with locations based on location_name"
  task associate_events_with_locations: :environment do
    location_mapping = {
      "Bungarribee Park" => Location.find_by(slug: "bungarribee"),
      "Nepean River" => Location.find_by(slug: "nepean"),
      "Parramatta Park" => Location.find_by(slug: "parramatta")
    }

    updated_count = 0
    skipped_count = 0

    Event.where(location_id: nil).find_each do |event|
      location_name_value = event.read_attribute(:location_name)
      location = location_mapping[location_name_value]
      if location
        event.update!(location: location)
        puts "✓ Associated Event ##{event.number} (#{event.date}) with #{location.name}"
        updated_count += 1
      else
        puts "⚠ Warning: No location found for '#{location_name_value}' (Event ##{event.number})"
        skipped_count += 1
      end
    end

    puts "\n#{updated_count} events associated with locations"
    puts "#{skipped_count} events skipped (no matching location)" if skipped_count > 0
  end
end
