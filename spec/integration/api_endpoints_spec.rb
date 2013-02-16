describe "API Endpoints" do
  before(:all) do
    fixture(:user, { nickname: "adooken" })
    @space  = valid! fixture(:space, { title: "The Zoo" })
    
    @folder = valid! fixture(:folder, { title: "Mammals", space: @space, folder: @space.root_folder })
    @subfolder = valid! fixture(:folder, { title: "Whales", space: @space, folder: @folder })
    
    @page   = valid! fixture(:page, { folder: @space.root_folder, title: "What a zoo is" })
    @folder_page = valid! fixture(:page, { title: "What mammals are", folder: @folder })
    @subfolder_page = valid! fixture(:page, { title: "What whales are", folder: @subfolder })
    
    @page.generate_revision('foobar', @page.creator).should be_true
    @page.generate_revision('the foobar', @page.creator).should be_true
    
    @page_rv1 = @page.revisions.first
    @page_rv2 = @page.revisions.last
  end
  
  describe "Hyperlinks" do
    it "for a user" do
      @u.href.should == '/adooken'
    end
    
    it "for a space" do
      @space.href.should == "/adooken/the-zoo"
    end
    
    it "for a folder" do
      @space.root_folder.href.should == "/adooken/the-zoo"
      @folder.href.should == '/adooken/the-zoo/mammals'
      @subfolder.href.should == '/adooken/the-zoo/mammals/whales'
    end
    
    it "for a page" do
      @page.href.should == '/adooken/the-zoo/what-a-zoo-is'
      @folder_page.href.should == '/adooken/the-zoo/mammals/what-mammals-are'
      @subfolder_page.href.should == '/adooken/the-zoo/mammals/whales/what-whales-are'
    end
    
    it "for page revisions" do
      @page_rv1.href.should == "/adooken/the-zoo/what-a-zoo-is/revisions/#{@page_rv1.id}"
      @page_rv2.href.should == "/adooken/the-zoo/what-a-zoo-is/revisions/#{@page_rv2.id}"
    end
  end
  
  describe "Endpoints" do
    it "for a user" do
      @u.url.should == "/users/#{@u.id}"
    end
    
    it "for a space" do
      @space.url.should == "/users/#{@u.id}/spaces/#{@space.id}"
    end
    
    it "for a folder" do
      @space.root_folder.url.should == "/spaces/#{@space.id}/folders/#{@space.root_folder.id}"
      @folder.url.should == "/spaces/#{@space.id}/folders/#{@folder.id}"
      @subfolder.url.should == "/spaces/#{@space.id}/folders/#{@subfolder.id}"
    end
    
    it "for a page" do
      @page.url.should ==           "/spaces/#{@space.id}/pages/#{@page.id}"
      @folder_page.url.should ==    "/spaces/#{@space.id}/pages/#{@folder_page.id}"
      @subfolder_page.url.should == "/spaces/#{@space.id}/pages/#{@subfolder_page.id}"
    end
    
    it "for page revisions" do
      @page_rv1.url.should == "/pages/#{@page.id}/revisions/#{@page_rv1.id}"
      @page_rv2.url.should == "/pages/#{@page.id}/revisions/#{@page_rv2.id}"
    end
  end
end