require 'fastimage'
require 'timeout'
require 'mini_magick'

module Badge
  class Runner

    def run(path, dark_badge, custom_badge, no_badge, shield_string)
      app_icons = Dir.glob("#{path}/**/*.appiconset/*.{png,PNG}")

      Helper.log.info "Verbose active...".blue unless not $verbose

      if app_icons.count > 0
        Helper.log.info "Start adding badges...".green

        shield = nil
        begin
          Timeout.timeout(Badge.shield_io_timeout) do
            shield = load_shield(shield_string) unless not shield_string
          end
        rescue Timeout::Error
          Helper.log.error "Error loading image from shield.io timeout reached. Skipping Shield. Use --verbose for more info".red
        end

        app_icons.each do |full_path|
          Helper.log.info "'#{full_path}'"
          icon_path = Pathname.new(full_path)
          icon = MiniMagick::Image.new(full_path)

          result = MiniMagick::Image.new(full_path)
          result = add_beta_badge(custom_badge, dark_badge, icon) unless no_badge

          result = add_shield(icon, result, shield) unless not shield

          result.format "png"
          result.write full_path
        end

        Helper.log.info "Badged \\o/!".green
      else
        Helper.log.error "Could not find any app icons...".red
      end
    end

    def add_shield(icon, result, shield)
      Helper.log.info "Adding shield.io image ontop of icon".blue unless not $verbose

      current_shield = MiniMagick::Image.open(shield.path)
      current_shield.resize "#{icon.width}x#{icon.height}>"
      result = result.composite(current_shield) do |c|
        c.compose "Over"
        c.gravity "north"
      end
    end

    def load_shield(shield_string)
      url = Badge.shield_base_url + Badge.shield_path + shield_string + ".png"
      file_name = shield_string + ".png"

      Helper.log.info "Trying to load image from shield.io. Timeout: ".blue unless not $verbose
      Helper.log.info "URL: #{url}".blue unless not $verbose

      shield = Tempfile.new(file_name).tap do |file|
        file.binmode
        file.write(open(url).read)
        file.close
      end
    end

    def add_beta_badge(custom_badge, dark_badge, icon)
      Helper.log.info "Adding beta badge image ontop of icon".blue unless not $verbose
      if custom_badge && File.exist?(custom_badge) # check if custom image is provided
        badge = MiniMagick::Image.open(custom_badge)
      else
        badge = MiniMagick::Image.open(dark_badge ? Badge.dark_badge : Badge.light_badge)
      end

      badge.resize "#{icon.width}x#{icon.height}"
      result = icon.composite(badge) do |c|
        c.compose "Over"
      end
    end
  end
end
