# frozen_string_literal: true
require "bundler"

module Licensed
  module Source
    class Bundler
      def initialize(config)
        @config = config
      end

      def enabled?
        @config.enabled?(type) && File.exist?(lockfile_path)
      end

      def type
        "rubygem"
      end

      def dependencies
        @dependencies ||= with_local_configuration do
          definition.specs_for(groups).map do |spec|
            Dependency.new(spec.gem_dir, {
              "type"     => type,
              "name"     => spec.name,
              "version"  => spec.version.to_s,
              "summary"  => spec.summary,
              "homepage" => spec.homepage
            })
          end
        end
      end

      # Build the bundler definition
      def definition
        @definition ||= ::Bundler::Definition.build(gemfile_path, lockfile_path, nil)
      end

      # Returns the bundle definition groups, excluding test and development
      def groups
        definition.groups - [:test, :development]
      end

      # Returns the expected path to the Bundler Gemfile
      def gemfile_path
        @config.pwd.join ::Bundler.default_gemfile.basename.to_s
      end

      # Returns the expected path to the Bundler Gemfile.lock
      def lockfile_path
        @config.pwd.join ::Bundler.default_lockfile.basename.to_s
      end

      private

      # helper to clear all bundler environment around a yielded block
      def with_local_configuration
        # with a clean, original environment
        ::Bundler.with_original_env do
          # reset all bundler configuration
          ::Bundler.reset!
          # and re-configure with settings for current directory
          ::Bundler.configure

          yield
        end
      ensure
        # restore bundler configuration
        ::Bundler.reset!
        ::Bundler.configure
      end
    end
  end
end
