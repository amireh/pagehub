describe "Access control" do
  describe "Pages" do
    before(:all) do      
      fixture(:user)
      fixture(:another_user)
      @page = valid! fixture(:page, { creator: @u, folder: @f })
    end

    after(:all) do
      Fixtures.teardown
    end

    before do
      sign_in(@u2)
      cleanup_routes
    end
    
    it "as a member" do
      @s.add_member(@u2)
      app.get('/spec/:space_id/:page_id', :requires => [ :space, :page ]) {
        [
          (can? :read,    @page),
          (can? :create,  @page),
          (can? :update,  @page),
          (can? :delete,  @page)
        ].to_json
      }
      api { get "/spec/#{@s.id}/#{@page.id}" }.body.should == [ true, false, false, false ]
    end
    
    it "as an editor" do
      @s.add_editor(@u2)
      app.get('/spec/:space_id/:page_id', :requires => [ :space, :page ]) {
        [
          (can? :read,    @page),
          (can? :create,  @page),
          (can? :update,  @page),
          (can? :delete,  @page)
        ].to_json
      }
      api { get "/spec/#{@s.id}/#{@page.id}" }.body.should == [ true, true, true, false ]
    end

    it "as an admin" do
      @s.add_admin(@u2)
      app.get('/spec/:space_id/:page_id', :requires => [ :space, :page ]) {
        [
          (can? :read,    @page),
          (can? :create,  @page),
          (can? :update,  @page),
          (can? :delete,  @page)
        ].to_json
      }
      api { get "/spec/#{@s.id}/#{@page.id}" }.body.should == [ true, true, true, true ]
    end
    it "as a creator" do
      sign_in(@u)
      app.get('/spec/:space_id/:page_id', :requires => [ :space, :page ]) {
        [
          (can? :read,    @page),
          (can? :create,  @page),
          (can? :update,  @page),
          (can? :delete,  @page)
        ].to_json
      }
      api { get "/spec/#{@s.id}/#{@page.id}" }.body.should == [ true, true, true, true ]
    end
    
  end
  
  describe "Folders" do
    before(:all) do      
      fixture(:user)
      fixture(:another_user)
      @f = valid! fixture(:folder, { creator: @u, space: @s })
    end

    after(:all) do
      Fixtures.teardown
    end

    before do
      sign_in(@u2)
      cleanup_routes
    end
    
    it "as a member" do
      @s.add_member(@u2)
      app.get('/spec/:space_id/:folder_id', :requires => [ :space, :folder ]) {
        [
          (can? :read,    @folder),
          (can? :create,  @folder),
          (can? :update,  @folder),
          (can? :delete,  @folder)
        ].to_json
      }
      api { get "/spec/#{@s.id}/#{@f.id}" }.body.should == [ true, false, false, false ]
    end
    
    it "as an editor" do
      @s.add_editor(@u2)
      app.get('/spec/:space_id/:folder_id', :requires => [ :space, :folder ]) {
        [
          (can? :read,    @folder),
          (can? :create,  @folder),
          (can? :update,  @folder),
          (can? :delete,  @folder)
        ].to_json
      }
      api { get "/spec/#{@s.id}/#{@f.id}" }.body.should == [ true, true, true, false ]
    end

    it "as an admin" do
      @s.add_admin(@u2)
      app.get('/spec/:space_id/:folder_id', :requires => [ :space, :folder ]) {
        [
          (can? :read,    @folder),
          (can? :create,  @folder),
          (can? :update,  @folder),
          (can? :delete,  @folder)
        ].to_json
      }
      api { get "/spec/#{@s.id}/#{@f.id}" }.body.should == [ true, true, true, true ]
    end
    
    it "as a creator" do
      sign_in(@u)
      app.get('/spec/:space_id/:folder_id', :requires => [ :space, :folder ]) {
        [
          (can? :read,    @folder),
          (can? :create,  @folder),
          (can? :update,  @folder),
          (can? :delete,  @folder)
        ].to_json
      }
      api { get "/spec/#{@s.id}/#{@f.id}" }.body.should == [ true, true, true, true ]      
    end
  end
  
  describe "Spaces" do
    before(:all) do      
      fixture(:user)
      fixture(:another_user)
      @space = valid! fixture(:space, { creator: @u })
    end

    after(:all) do
      Fixtures.teardown
    end

    before do
      sign_in(@u2)
      cleanup_routes
    end
    
    it "as a member" do
      @space.add_member(@u2)
      app.get('/spec/:space_id', :requires => [ :space ]) {
        [
          (can? :read,    @space),
          (can? :create,  @space),
          (can? :update,  @space),
          (can? :delete,  @space)
        ].to_json
      }
      api { get "/spec/#{@space.id}" }.body.should == [ true, true, false, false ]
    end
    
    it "as an editor" do
      @space.add_editor(@u2)
      app.get('/spec/:space_id', :requires => [ :space ]) {
        [
          (can? :read,    @space),
          (can? :create,  @space),
          (can? :update,  @space),
          (can? :delete,  @space)
        ].to_json
      }
      api { get "/spec/#{@space.id}" }.body.should == [ true, true, false, false ]
    end

    it "as an admin" do
      @space.add_admin(@u2)
      app.get('/spec/:space_id', :requires => [ :space ]) {
        [
          (can? :read,    @space),
          (can? :create,  @space),
          (can? :update,  @space),
          (can? :delete,  @space)
        ].to_json
      }
      api { get "/spec/#{@space.id}" }.body.should == [ true, true, true, false ]
    end
    
    it "as a creator" do
      sign_in(@u)
      app.get('/spec/:space_id', :requires => [ :space ]) {
        [
          (can? :read,    @space),
          (can? :create,  @space),
          (can? :update,  @space),
          (can? :delete,  @space)
        ].to_json
      }
      api { get "/spec/#{@space.id}" }.body.should == [ true, true, true, true ]      
    end
  end
end