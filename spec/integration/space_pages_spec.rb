feature "Space pages" do
  before do
    fixture(:user)
    sign_in
  end
  
  context "as a creator" do
    before do
    end

    context "in my own space" do
      
      it "i get a page" do
        p = valid! fixture(:page)
        expect { api_call get "/spaces/#{p.space.id}/pages/#{p.id}" }.to succeed
      end
      
      it "i create a page" do
        expect {
          api_call post "/spaces/#{@s.id}/pages", {
            title:      "Some Page",
            folder_id:  @s.root_folder.id
          }
        }.to succeed
      end

      it "i update a page" do
        p = valid! fixture(:page)
        
        rc = api_call put "/spaces/#{@u.default_space.id}/pages/#{p.id}", {
            content: "i ate all your monkeys"
          }
        
        rc.should succeed(200)
        rc.body["page"]["content"].should == 'i ate all your monkeys'
      end
    end
  end
  
  context "as an editor" do
    before do
      fixture(:another_user)
      @s.add_editor(@u2)
      
      @p = valid! fixture(:page)
      
      sign_out
      sign_in(@u2)      
    end    
    
    it "i create my own page" do
      expect {
        api_call post "/spaces/#{@s.id}/pages", {
          title:      "Some Page",
          folder_id:  @s.root_folder.id
        }
      }.to succeed
    end
      
    scenario "i edit a page authored by someone else" do
      api {
        put "/spaces/#{@s.id}/pages/#{@p.id}", {
          title: "The Foofighters"
        }
      }.should succeed
      
      @p.refresh.title.should == "The Foofighters"
    end
    
    scenario "i'm prohibited from deleting a page authored by someone else" do
      rc = api_call delete "/spaces/#{@s.id}/pages/#{@p.id}"
      rc.should fail(403, 'can not remove pages authored by someone else')
      
      @p.refresh.should be_true
    end
    
    scenario "i delete my own page" do
      p = valid! fixture(:page, { creator: @u2 })
      
      p.creator.id.should == @u2.id
      
      rc = api_call delete "/spaces/#{@s.id}/pages/#{p.id}"
      rc.should succeed
    end
    
  end
  
  context "as an admin" do
    before do
      fixture(:another_user)
      @s.add_admin(@u2)
      
      @p = valid! fixture(:page)
      
      sign_out
      sign_in(@u2)
    end
    
    scenario "i delete a page authored by someone else" do
      api { delete "/spaces/#{@s.id}/pages/#{@p.id}" }.should succeed
      
      @p.refresh.should be_false
    end
  end
  
  context "as a member" do
    before do
      fixture(:another_user)
      @p = valid! fixture(:page)
      @s.add_member(@u2)
      sign_in(@u2)
    end
    
    scenario "i read a page" do
      rc = api {
        get "/spaces/#{@s.id}/pages/#{@p.id}"
      }
      
      rc.should succeed      
      rc.body["page"]["id"].should == @p.id
    end
    
    scenario "i'm prohibited from editing any page" do
      rc = api {
        put "/spaces/#{@s.id}/pages/#{@p.id}", {}
      }
      
      rc.should fail(403, 'need to be an editor')
    end

    scenario "i'm prohibited from creating any page" do
      rc = api {
        post "/spaces/#{@s.id}/pages", {}
      }
      
      rc.should fail(403, 'need to be an editor')
    end

    scenario "i'm prohibited from deleting any page" do
      rc = api {
        delete "/spaces/#{@s.id}/pages/#{@p.id}"
      }
      
      rc.should fail(403, 'can not remove')
    end
  end
end