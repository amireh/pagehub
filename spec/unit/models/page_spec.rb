describe Page do
  before(:all) do
    valid! fixture(:user)
  end
  
  after do
    @user.pages.destroy.should be_true
  end

  it "should be creatable" do
    f = valid! fixture(:folder)
    p = valid! f.pages.create({ title: "Test", creator: @u })
    p.folder.should == f
    f.pages.count.should == 1
    f.destroy
  end
  
  it "should be destroyed" do
    p = valid! fixture(:page)
    p.destroy.should be_true
  end
  
  it "should generate a carbon copy on creation" do
    p = valid! fixture(:page)
    p.cc.should be_true
    p.cc.content.should == ''
  end  
  
  context "versioning" do
    before do
      @u = valid! fixture(:user)
      @p = valid! fixture(:page, { title: "Versionable page" })
      
      @updates    = [ "foobar", "adooken", "got\n\nya" ]
      @revisions  = []
      @updates.each do |new_content|
        @p.generate_revision(new_content, @p.creator).should be_true
        @p.update!({ content: new_content })
        @revisions << @p.revisions.last
      end
      
      @p.revisions.count.should == @updates.length
      @p.content.should == @updates.last
    end
    
    it 'snapshotting' do
      @p.snapshot(@revisions[0]).should == 'foobar'
      @p.snapshot(@revisions[1]).should == 'adooken'
      @p.snapshot(@revisions[2]).should == "got\n\nya"
    end
    
    it 'rolling back' do
      @p.content.should == @updates.last
      @p.rollback(@revisions[0]).should be_true
      @p.refresh.content.should == 'foobar'
      @p.refresh.revisions.count.should == 1
    end
    
    it 'rolling back to the latest HEAD' do
      @p.rollback(@revisions.last).should be_true
      @p.refresh.content.should == "got\n\nya"
    end
    
    it 'rolling back sequentially' do
      @revisions.reverse.each_with_index do |rv, i|
        @p.rollback(rv).should be_true
        @p.content.should == @updates.reverse[i]
      end
    end

  end

end