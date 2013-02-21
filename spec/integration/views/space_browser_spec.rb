feature "Space browser" do
  
  def space_with_creator_logged_in
    @user = fixture(:user)
    @space = fixture(:space)
    
    visit "/sessions/new"
    
    within('form') do
      fill_in 'email', with: @user.email
      fill_in 'password', with: @user.password
      
      click_button('Login')
    end
  end

  before(:each) do
    space_with_creator_logged_in
  end
  
  # append_after(:each) do |scenario|
  #   if Capybara.page && example.failed?
  #     save_and_open_page
  #   end
  # end
  
  context "Injection" do
    before do
      @space.folders.destroy
      @space = @space.refresh

      visit @space.url
      current_path.should == @space.url
    end
    
    def space_browser
      page.find_by_id('browser')
    end
    
    def inject_space
      page.driver.execute_script <<-'JS'
        $.ajaxSetup({
          accepts:      { json: "application/json" },
          dataType:     "json"
        });
              
        $.ajax({
          type:     "GET",
          url:      space.url,
          async:    false,
          success:  function(data) {
            dynamism.inject(data.space, $("#browser"));
          }
        });
      JS
    end
    
    scenario "With nothing" do
      space_browser.all('li', :visible => true).should be_empty
    end
    
    scenario "With a page", :js => true do
      @space.create_root_folder
      
      inject_space
      
      space_browser.all('li', :visible => true).count.should == 2
      space_browser.find('li.folder > span.folder_title').should have_content(@space.root_folder.title)
      space_browser.find('li.folder > ol.pages', visible: true).should have_content(@space.pages.first.title)
    end
    
    scenario "With an empty folder", :js => true do
      @space.create_root_folder
      @space.root_folder.pages.destroy
      @space = @space.refresh
      
      inject_space
      
      space_browser.all('li', :visible => true).count.should == 1
      space_browser.should have_content(@space.root_folder.title)
    end
    
    
  end
end