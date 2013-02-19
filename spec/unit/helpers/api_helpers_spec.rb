describe Sinatra::API do
  after do
    cleanup_routes.should >= 1
  end
  
  it "should reject a request missing a required parameter" do
    app.post('/spec', :provides => [ :json ]) {
      api_required!({ something: nil })
    }
    rc = post "/spec", {}
    rc.status.should == 400
    rc.body.should match(/Missing.*:something/)
  end
  
  it "should ignore a missing optional parameter" do
    app.post('/spec', :provides => [ :json ]) {
      api_required!({ something: nil })
      api_optional!({ something_else: nil })
    }
    
    rc = post "/spec", { something: 'yeah' }
    rc.status.should == 200
  end
  
  it "should reject a required parameter with a custom msg" do
    app.post('/spec', :provides => [ :json ]) {
      api_required!({ something: lambda { |s| "On fire" if s == 'ignite' } })
    }
    
    rc = post "/spec", { something: 'ignite' }
    rc.status.should == 400
    rc.body.should match(/On fire/)
  end
  
  describe "locating resources" do
    
    before(:all) do
      fixture(:user)
    end
    
    after(:all) do
      Fixtures.teardown
    end
    
    before do
      sign_in
    end
    
    it "should locate a space" do
      app_instance.stub(:whine)
      app_instance.should_receive(:whine).with(@s.id)
      
      app.get('/spec/:space_id', :auth => [ :user ], :requires => [ :space ]) {
        whine @space.id
      }
      
      rc = api_call get "/spec/#{@s.id}"
      rc.should succeed
    end
    
    it "should locate a page in a space" do
      app_instance.stub(:whine)
      app_instance.should_receive(:whine).with(@s.pages.first.id)

      app.get('/spec/:space_id/:page_id', :auth => [ :user ], :requires => [ :space, :page ]) {
        whine @page.id
      }
      
      rc = api_call get "/spec/#{@s.id}/#{@s.pages.first.id}"
      rc.should succeed
    end
    
    it "should locate a folder in a space" do
      salt = some_salt
      app.get("/spec/#{salt}/:space_id/:folder_id", :auth => [ :user ], :requires => [ :space, :folder ]) { 200 }
      rc = api_call get "/spec/#{salt}/#{@s.id}/#{@f.id}"
      rc.should succeed
    end
    
    
    it "should reject a request missing a space" do
      app.get('/spec', :provides => [ :json ], :auth => [ :user ], :requires => [ :space ]) {
        true
      }
      
      rc = api_call get '/spec'
      rc.should fail(404, 'No such resource: Space#')
      
      app.get('/spec/:space_id', :auth => [ :user ], :requires => [ :space ]) {
        true
      }
      
      rc = api_call get '/spec/1234'
      rc.should fail(404, 'No such resource: Space#1234')
    end
    
    it "should reject a page request with an invalid id" do
      app.get('/spec/:space_id/pages/:page_id', :auth => [ :user ], :requires => [ :space, :page ]) {
        true
      }
      rc = api_call get "/spec/#{@s.id}/pages/123"
      rc.should fail(404, 'No such resource: Page#123')
    end
    
    it "should reject a page request with an invalid space" do
      app.get('/spec/:space_id/pages/:page_id', :auth => [ :member ], :requires => [ :space, :page ]) {
        true
      }
      rc = api_call get "/spec/123/pages/456"
      rc.should fail(404, 'No such resource: Space#123')
    end
  end
end