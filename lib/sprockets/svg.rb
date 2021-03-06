require 'sprockets/svg/version'
require 'chunky_png'
require 'mini_magick'

module Sprockets
  module Svg
    extend self

    USELESS_PNG_METADATA = %w(svg:base-uri date:create date:modify).freeze

    # TODO: integrate svgo instead: https://github.com/svg/svgo
    # See https://github.com/lautis/uglifier on how to integrate a npm package as a gem.
    def self.convert(svg_blob)
      stream = StringIO.new(svg_blob)
      image = MiniMagick::Image.create('.svg', false) { |file| IO.copy_stream(stream, file) }
      image.format('png')
      strip_png_metadata(image.to_blob)
    end

    def strip_png_metadata(png_blob)
      image = ChunkyPNG::Datastream.from_blob(png_blob)

      image.other_chunks.reject! do |chunk|
        chunk.type == "tIME" ||
          (chunk.respond_to?(:keyword) && USELESS_PNG_METADATA.include?(chunk.keyword))
      end

      str = StringIO.new
      image.write(str)
      str.string
    end

    def install(assets)
      assets.register_preprocessor 'image/svg+xml', Sprockets::Svg::Cleaner
      assets.register_transformer 'image/svg+xml', 'image/png', -> (input) {
        Sprockets::Svg.convert(input[:data])
      }
    end

  end
end

require_relative 'svg/cleaner'

require_relative 'svg/railtie' if defined?(Rails)
