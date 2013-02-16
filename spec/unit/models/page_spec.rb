describe Page do
  before do
    fixture(:user)
  end

  it "should be creatable" do
    f = valid! fixture(:folder)
    p = valid! f.pages.create({ title: "Test", creator: @u })
    p.folder.should == f
    f.pages.count.should == 1
  end
  
  context "Destruction" do
    it "should be destroyed" do
      p = @f.pages.first
      p.destroy.should be_true
    end
    
    # it "should be deletable only by its creator" do
    #   fixture(:another_user)
    #   u1, u2 = @u, @u2
      
    #   p = @s.pages.create({ creator: u2 })
    #   p.saved?.should be_true
      
    #   p.destroy.should be_false
    #   p.report_errors.should match(/can be deleted only by their author/)
      
    #   p.errors.clear
      
    #   p.editor = u2
    #   p.destroy.should be_true
    # end    
    
  end
  
  it "should generate a carbon copy on creation" do
    @root.homepage.cc.should be_true
    @root.homepage.cc.content.should == ''
  end
  
  it "should generate revisions on content update" do
  end

end