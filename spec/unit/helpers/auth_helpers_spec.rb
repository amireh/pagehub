describe Sinatra::Authenticator do
  after do
    cleanup_routes 
  end
  
  
  # it "should use a folder as a page's scope" do
  #   app.get('/spec/:folder_id/pages/:page_id', :provides => [ :json ], :auth => [ :member ], :requires => [ :folder, :page ]) {
  #     true
  #   }
  #   rc = api_call get "/spec/#{@f.id}/pages/123"
  #   rc.should fail(404, 'No such page')
  # end
  
  
end