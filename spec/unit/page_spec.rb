describe Page do
  before do
    mockup_user
  end

  it "should create a page in the root folder by default" do
    @s.pages.count.should == 1
    p = @s.pages.create({ title: "Test", creator: @u })
    p.saved?.should be_true
    p.folder.should == @s.root_folder
    @s.pages.count.should == 2
  end
  
  it "should create a page inside any folder" do
    f = @s.folders.create({ title: "Test Container", creator: @u })
    f.saved?.should be_true
    f.folder.should == @s.root_folder
    @s.folders.count.should == 2
    
    p = f.pages.create({ title: "Test", creator: @u })
    p.saved?.should be_true
    p.folder.should == f
    f.pages.count.should == 2
  end
  
  it "should delete a page" do
    p = @f.pages.first
    p.editor = @u
    p.destroy.should be_true
    @f.refresh.pages.empty?.should be_true
  end
  
  it "should be deletable only by its creator" do
    mockup_another_user
    u1, u2 = @u, @u2
    
    p = @s.pages.create({ creator: u2 })
    p.saved?.should be_true
    
    p.editor = u1
    p.destroy.should be_false
    p.report_errors.should match(/can be deleted only by their author/)
    
    p.errors.clear
    
    p.editor = u2
    p.destroy.should be_true
  end
  
  it "should generate a carbon copy on creation" do
    @f.homepage.cc.should be_true
    @f.homepage.cc.content.should == ''
  end
  
  it "should generate revisions on content update" do
  end
end