# frozen_string_literal: true

# This contains two patches to make sprockets more tolerable in dev
#
# 1. Stop computing asset paths which triggers sprockets to do mountains of work
#     All our assets in dev are in the /assets folder anyway
#
# 2. Stop using a concatenator that does tons of work checking for semicolons when
#     when rebuilding an asset

if Rails.env.development? || Rails.env.test?
  SanePatch.patch("sprockets", "~> 3.7.2") do
    module FreedomPatches
      module SprocketsPatches
        def self.concat_javascript_sources(buf, source)
          if buf.bytesize > 0
            # CODE REMOVED HERE
            buf << ";" # unless string_end_with_semicolon?(buf)
            buf << "\n" # unless buf.end_with?("\n")
          end
          buf << source
        end

        Sprockets.register_bundle_metadata_reducer 'application/javascript', :data, proc { +"" }, method(:concat_javascript_sources)
      end
    end
  end

  SanePatch.patch("actionview", "~> 7.0.2") do
    ActiveSupport.on_load(:action_view) do
      def compute_asset_path(source, _options = {})
        "/assets/#{source}"
      end
      alias_method :public_compute_asset_path, :compute_asset_path
    end
  end
end
