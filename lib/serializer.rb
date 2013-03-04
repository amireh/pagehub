require 'zipruby'

module PageHub
  class Vocal
    unless $VERBOSE || ENV['VERBOSE']; def puts(*args) end; end
  end

  class Archiver < Vocal
    def deflate(options)
      options = {
        algorithm: :zip,
        soft: false
      }.merge(options)

      title, repository, dest = options[:prefix], options[:root], options[:out]

      if !repository || repository.empty? || !File.exists?(repository)
        raise ArgumentError, "Invalid repository root: #{repository}"
      end

      if !title || title.to_s.empty?
        raise ArgumentError, "Archive must have a prefix assigned."
      end

      case options[:algorithm]
      when :zip
        ZIPArchiver.new.deflate(title, repository, dest, options[:soft])
      else
        raise ArgumentError, "unsupported archiving format #{options[:algorithm]}, supported formats: [ :zip ]"
      end
    end

    class ZIPArchiver < Vocal

      def deflate(title, repository, destination, soft = false)
        destination = destination + '.zip'

        puts "creating archive at: #{destination}"
        puts "archive root: #{repository}"

        stats = { folders: 0, pages: 0 }

        begin; FileUtils.rm(destination) rescue nil; end

        Zip::Archive.open(destination, Zip::CREATE) do |a|
          a.add_dir(title)

          fix = lambda { |p| p.gsub(repository, '') }

          Dir.glob("#{repository}/**/*").each do |path|
            if File.directory?(path)
              if soft
                puts "dir:  #{title + fix.call(path)}"
              else
                a.add_dir(title + fix.call(path))
              end

              stats[:folders] += 1
            else
              if soft
                puts "\tfile: #{title + fix.call(path)}"
              else
                a.add_file(title + fix.call(path), path)
              end

              stats[:pages] += 1
            end
          end
        end

        puts "archive contents: #{stats[:folders]} folders, #{stats[:pages]} pages"
        destination
      end # deflate
    end # ZIPArchiver
  end

  class SpaceSerializer < Vocal
    def initialize(options = {})
      @options = {
        extension: '.md',
        processor: lambda { |p| p.content }
      }.merge(options)

      unless @options[:processor] && @options[:processor].respond_to?(:call)
        raise ArgumentError, ':processor must be a callable object that returns page content to be serialized'
      end

      super()
    end

    def serialize(space, path, compress = :zip, cleanup = true)
      bundle = space.creator.nickname.sanitize + '-' + space.pretty_title
      bundle_path = File.join(path, bundle)

      root_folder_path = serialize_folder(space.root_folder, bundle_path)

      if compress
        archive = PageHub::Archiver.new.deflate({
          prefix:     bundle,
          root:       root_folder_path,
          algorithm:  compress,
          out:        bundle_path
        })

        if cleanup
          FileUtils.rm_rf(bundle_path)
        end

        return archive
      end

      root_folder_path
    end # serialize

    private

    def serialize_folder(f, path)
      path = File.join(path, f.pretty_title)
      begin; FileUtils.rm_rf(path); rescue nil; end
      FileUtils.mkdir_p(path)

      f.folders.each  { |cf|  serialize_folder(cf, path)  }
      f.pages.each    { |p|   serialize_page(p, path)     }

      path
    end

    def serialize_page(p, path)
      path = File.join(path, "#{p.pretty_title}#{@options[:extension]}")

      File.open(path, 'w') { |f|
        f.write(@options[:processor].call(p))
      }
    end

  end
end