namespace :pagehub do
  desc "sets an updated_at timestamp for pages that don't have it"
  task :update_page_timestamps => :environment do
    Page.all({updated_at: nil}).update({ updated_at: DateTime.now })
  end
end