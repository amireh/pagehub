# encoding: utf-8

namespace :pagehub do
  desc "dumps the entire data to stdout as JSON"
  task :dump => :environment do
    def pluck(resource, attrs)
      attrs.each_with_object({}) { |a,h| h[a.to_sym] = resource.send(a) }
    end

    class Writer
      attr_accessor :index, :path, :fragment_size, :padding

      def initialize(path, fragment_size=1024, padding=5)
        self.path = path
        self.index = 0
        self.fragment_size = fragment_size
        self.padding = padding

        FileUtils.mkdir_p(path)
      end

      def save(data, filename)
        data.each_slice(self.fragment_size).to_a.each_with_index do |entries, fragment|
          index = "%0#{self.padding}i" % self.index
          filepath = "#{path}/#{index}-#{filename}-#{fragment}.json"
          puts "Writing #{entries.length} #{filename.singularize} entries to #{filepath}"

          File.open(filepath, "w:UTF-8") do |file|
            file.write({ "#{filename}" => entries }.to_json)
          end

          self.index += 1
        end
      end
    end

    user_ids = ENV['USER_IDS'].to_s.split(',').map(&:strip).reject(&:empty?)
    path = ENV['OUT'] || "#{$ROOT}/dumps/#{Time.now.strftime("%Y.%m.%d")}"
    writer = Writer.new(path)


    users = if user_ids.any?
      User.all(id: Array(user_ids))
    else
      User.all
    end

    puts "Exporting data for #{users.count} users."

    user_attrs = users.map do |user|
      attrs = pluck user, %w[
        id
        email
        name
        nickname
        password
        created_at
        provider
        uid
        oauth_token
        oauth_secret
        extra
        auto_nickname
        gravatar_email
      ]

      preferences = user.preferences.dup
      preferences['runtime'] ||= {}
      preferences['runtime']['cf'] ||= []
      preferences['runtime']['cf'] = preferences['runtime']['cf'].uniq

      attrs['preferences'] = preferences
      attrs
    end

    writer.save(user_attrs, 'users')

    spaces = users.map(&:owned_spaces).flatten.map do |resource|
      pluck resource, %w[ id brief is_public created_at preferences title pretty_title creator_id ]
    end

    writer.save(spaces, 'spaces')

    space_ids = spaces.map { |space| space[:id] }

    space_users = SpaceUser.all(space_id: space_ids).map do |resource|
      pluck resource, %w[ role space_id user_id ]
    end

    writer.save(space_users, 'space_users')

    folders = Folder.all(space_id: space_ids).map do |resource|
      pluck resource, %w[ id title pretty_title created_at folder_id browsable space_id creator_id ]
    end

    writer.save(folders, 'folders')

    folder_ids = folders.map { |folder| folder[:id] }

    pages = Page.all(creator_id: user_ids).map do |resource|
      pluck resource, %w[
        id
        title
        pretty_title
        content
        created_at
        folder_id
        browsable
        updated_at
        creator_id
      ]
    end

    writer.save(pages, 'pages')

    page_ids = pages.map { |page| page[:id] }

    public_pages = PublicPage.all(page_id: page_ids).map do |resource|
      pluck resource, %w[
        id
        created_at
        user_id
        page_id
        space_id
      ]
    end

    writer.save(public_pages, 'public_pages')

    page_carbon_copies = Page::CarbonCopy.all(page_id: page_ids).map do |resource|
      pluck resource, %w[ content page_id ]
    end

    writer.save(page_carbon_copies, 'page_carbon_copies')

    page_revisions = Page::Revision.all(page_id: page_ids).map do |resource|
      attrs = pluck resource, %w[
        id
        version
        created_at
        additions
        deletions
        patchsz
        page_id
        editor_id
      ]

      attrs['blob'] = Base64.encode64(resource.blob)
      attrs
    end

    writer.save(page_revisions, 'page_revisions')
  end
end
