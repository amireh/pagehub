namespace :routes do
  desc "Lists all defined routes"
  task :list => :environment do
    Sinatra::Application.routes.each do |method_routes|
      verb = method_routes[0]
      method_routes[1].each do |route|
        # puts "#{r_entry[0]}\t#{route.first.source}"
        route_regex = route.first.source
        captures = route[1]
        captures.each { |c|
          fst_pattern = route_regex.index('([^\.%2E/?#]+)')
          snd_pattern = route_regex.index('([^/?#]+)')
          if fst_pattern && snd_pattern
            if fst_pattern < snd_pattern
              route_regex.gsub!('([^\.%2E/?#]+)', ":#{c}")
            else
              route_regex.gsub!('([^/?#]+)', ":#{c}")
            end
          elsif fst_pattern
            route_regex.gsub!('([^\.%2E/?#]+)', ":#{c}")
          elsif snd_pattern
            route_regex.gsub!('([^/?#]+)', ":#{c}")
          end
        }

        # puts "#{verb}\t#{route_regex.gsub(/\\A|\\z/, '')} [#{captures.join(', ')}]"
      end
    end
  end
end