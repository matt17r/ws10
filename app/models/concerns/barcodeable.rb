module Barcodeable
  extend ActiveSupport::Concern

  included do
    has_one_attached :barcode
    after_create :generate_code
  end

  private

  require "barby"
  require "barby/barcode/code_128"
  require "barby/outputter/png_outputter"
  require "stringio"

  def generate_code
    barcode_object = Barby::Code128B.new(barcode_string)
    png_data = Barby::PngOutputter.new(barcode_object).to_png
    io = StringIO.new(png_data)

    self.barcode.attach(
      io:           io,
      filename:     "#{barcode_string.downcase}.png",
      content_type: "image/png"
    )
  end
end
