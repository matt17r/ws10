namespace :og_image do
  desc "Generate a preview SVG for an event OG image. Usage: bin/rails og_image:preview[42] or bin/rails og_image:preview (uses latest finalised event)"
  task :preview, [ :number ] => :environment do |_, args|
    event = if args[:number]
      Event.find_by!(number: args[:number])
    else
      Event.finalised.order(number: :desc).first || raise("No finalised events found")
    end

    path = Rails.root.join("tmp/og_preview.svg")
    FileUtils.mkdir_p(path.dirname)
    File.write(path, OgImageGeneratorService.new(event).build_svg)

    puts "Preview saved: #{path}"
    puts "Open with:    open #{path}"
  end
end
