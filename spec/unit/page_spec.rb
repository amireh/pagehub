describe Page do
  before do
    mockup_user
  end

  it "should be creatable" do
    f = valid! rmock(:folder)
    p = valid! f.pages.create({ title: "Test", creator: @u })
    p.folder.should == f
    f.pages.count.should == 1
  end
  
  context "Destruction" do
    it "should be destroyed" do
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
  end
  
  it "should generate a carbon copy on creation" do
    @root.homepage.cc.should be_true
    @root.homepage.cc.content.should == ''
  end
  
  it "should generate revisions on content update" do
  end
end