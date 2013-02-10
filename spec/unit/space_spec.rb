describe Space do
  before do
    mockup_user
  end

  context "Creation" do

    it "should create a default space for a new user" do
      @user.owned_spaces.count.should == 1
      @user.spaces.count.should == 1
    end

    it "should implicitly define a :creator membership for the creator" do
      @s.space_users.count.should == 1
      @s.space_users.all({ role: :creator, user: @u }).count.should == 1
    end
    
    it "should create a homepage for the space by default" do
      @s.root_folder.pages.count.should == 1
    end
  end
  
  
  it "update its pretty title whenever the title is updated" do
    @s.pretty_title.should == @s.title.sanitize
    @s.update({ title: "New Title" })
    @s.pretty_title.should == "New Title".sanitize
  end
  
  context "Total annihilation" do
    it "should delete itself cleanly" do
      s = @u.owned_spaces.create({ title: "The Zoo" })
      s.saved?.should be_true
      
      @u = @u.refresh
      
      nr_memberships = @u.space_users.count
      nr_spaces      = @u.spaces.count
      nr_ospaces     = @u.owned_spaces.count
      
      nr_spaces.should == nr_ospaces
      
      s.destroy
      
      @u = @u.refresh
      @u.should be_true
      
      @u.space_users.count.should   == nr_memberships - 1
      @u.spaces.count.should        == nr_spaces - 1
      @u.owned_spaces.count.should  == nr_ospaces - 1
    end
    
    it "should orphanize its folders into a new user space" do
      mockup_another_user()
      
      u1, u2 = @u, @u2

      # create a space owned by u2      
      s = u2.owned_spaces.create({ title: "The Zoo 123" })
      s.saved?.should be_true
      
      # add u1 to the space
      s.space_users.create({ user: u1, role: :admin })
      
      u1.spaces.count.should == 2
      s.users.count.should == 2
      
      # create some page in the space as u1
      s.root_folder.pages.create({ title: "Test", creator: u1 }).should be_true
      
      s = s.refresh
      s.pages.last.creator.id.should == u1.id
      nr_pages = s.pages.count
      
      s.destroy.should be_true
      
      u1, u2 = u1.refresh, u2.refresh

      u1.spaces.count.should == 2
      u2.spaces.count.should == 1
      
      orphan = u1.spaces.first({ title: "Orphaned: The Zoo 123" })
      orphan.should be_true
      orphan.pages.count.should == 2
      orphan.pages.first.title.should == "README"
      orphan.pages.last.title.should  == "Test"
    end
  end
  
end