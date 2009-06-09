module ExpireOnRestart
  LIST_FILE = File.join(Rails.root, 'tmp', '.expire_on_restart')

  class RestartExpirator
    include Singleton

    def add(*files)
      File.open(LIST_FILE, 'a+') { |f| f.write("\n" + Array(files).flatten.join("\n")) }
    end

    def expire_marked_files
      return unless File.exist?(LIST_FILE) && File.readable?(LIST_FILE)

      files_to_expire.each do |file|
        path = File.join(Rails.root, file)
        next unless File.exist?(path) && File.writable?(path)

        File.delete(path)
      end

      File.delete(LIST_FILE)
    end

    def files_to_expire
      File.new(LIST_FILE).readlines.collect { |f| f.gsub("\n", '') }.reject(&:blank?)
    end
  end

  module ExpirationHelper
    def expire_on_restart(*files)
      RestartExpirator.instance.add(*files)
    end
  end

  module AssetCacheExpirationHelper
    include ExpirationHelper

    def self.included(base)
      base.alias_method_chain(:javascript_include_tag, :expiration_on_restart)
      base.alias_method_chain(:stylesheet_link_tag, :expiration_on_restart)
    end

    def javascript_include_tag_with_expiration_on_restart(*sources)
      options = sources.extract_options!.symbolize_keys
      if options[:cache]
        cache_file = File.join('public', 'javascripts', (options[:cache] == true ? 'all' : options[:cache].gsub('.js', '')) + '.js')
        expire_on_restart(cache_file)
      end

      javascript_include_tag_without_expiration_on_restart(*(sources << options))
    end

    def stylesheet_link_tag_with_expiration_on_restart(*sources)
      options = sources.extract_options!.symbolize_keys
      if options[:cache]
        cache_file = File.join('public', 'stylesheets', (options[:cache] == true ? 'all' : options[:cache].gsub('.css', '')) + '.css')
        expire_on_restart(cache_file)
      end

      stylesheet_link_tag_without_expiration_on_restart(*(sources << options))
    end
  end
end