describe Page::Revision do
  
  before(:all) do
    fixture(:user)
  end
  
  context "generation" do
      
    before do
      @user.pages.destroy
      @page = fixture(:page)
    end
    
    it "should reject generating without a valid context" do
      expect {
        rv = Page::Revision.new
        rv.page = @page
        rv.editor = @page.creator
        rv.save
      }.to raise_error(Page::Revision::InvalidContextError, /context must be populated/)
    end
    
    it "should reject generating without a carbon copy" do
      expect {
        @page.cc.destroy.should be_true
        @page = @page.refresh
        rv = Page::Revision.new
        rv.page = @page
        rv.editor = @page.creator
        rv.context = { content: 'foobar' }
        rv.save
      }.to raise_error(Page::Revision::InvalidContextError, /must have a CC/)
      
      @page.init_cc
    end
    
    it "should generate" do
      rv_count = @page.revisions.count
      @page.generate_revision('foobar', @page.creator).should be_true
      @page.refresh.revisions.count.should == rv_count + 1
    end
    
    it "should not generate if content hasn't changed" do
      expect {
        @page.generate_revision(@page.content, @page.creator)
        @page.generate_revision(@page.content, @page.creator)
      }.to raise_error(Page::Revision::NothingChangedError)
    end

    it "should reject patching content too big" do
      really_large_string = ''
      Page::Revision::MaxPatchSize.times do really_large_string << 'a' end
      
      @page.generate_revision(@page.content, @page.creator)
      
      expect {
        @page.generate_revision(really_large_string, @page.creator)
      }.to raise_error(Page::Revision::PatchTooBigError)
    end
  end
  
  describe "instance methods" do
    before(:all) do
      @page = fixture(:page)
      @page.generate_revision('foobar', @page.creator).should be_true
      @page.generate_revision('barfoo', @page.creator).should be_true

      @page.revisions.count.should == 2
            
      @rv1 = @page.revisions.first
      @rv2 = @page.revisions.last
    end
    
    after(:all) do
      @user.pages.destroy
    end
    
    it "#info" do
      @rv1.info.should == "1 addition and 0 deletions."
      @rv2.info.should == "1 addition and 1 deletion."
    end
    
    it "#next" do
      @rv1.next.should == @rv2
      @rv2.next.should == nil
    end
    
    it "#prev" do
      @rv2.prev.should == @rv1
      @rv1.prev.should == nil
    end
    
    it '#roll' do
      @rv1.send(:roll, :backward, 'foobar').should == ''
      @rv2.send(:roll, :backward, 'barfoo').should == 'foobar'
      
      @rv1.send(:roll, :forward, '').should == 'foobar'
      @rv2.send(:roll, :forward, 'foobar').should == 'barfoo'
    end
    
    it '#roll with a bad patch' do
      old_blob = @rv1.blob
      
      @rv1.update!({ blob: "#{Marshal.dump(['foo'])}#{@rv1.blob}" })
      
      expect {
        @rv1.send(:roll, :backward, 'foobar')
      }.to raise_error(Exception, /Patch might be corrupt/)

      @rv1.update!({ blob: old_blob })
    end
    
    it '#roll with a bad serialized patch' do
      old_blob = @rv1.blob
      
      @rv1.update!({ blob: "teehee#{@rv1.blob}" })
      
      expect {
        @rv1.send(:roll, :backward, 'foobar')
      }.to raise_error(Exception, /Unable to load/)

      @rv1.update!({ blob: old_blob })
    end
    
  end
end