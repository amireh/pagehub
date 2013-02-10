describe Folder do
  before do
    mockup_user
  end

  it "should be created" do
    f = valid! rmock(:folder)
    f.folder.should == f.space.root_folder
  end
  
  it "should nest folders" do
    f = valid! rmock(:folder)
    f = valid! rmock(:folder, { q: { folder: f } })
  end
    
  it "should nest folders with the same title in different levels" do
    f = valid! rmock(:folder, { q: { title: "Mock" } })
    f = valid! rmock(:folder, { q: { title: "Mock", folder: f } })
  end
  
  it "should not allow for duplicate-titled folders" do
    f = valid! rmock(:folder, { q: { title: "Test" } })
    f = invalid! rmock(:folder, { q: { title: "Test" } })

    f.report_errors.should match(/already have a folder with that title/)
  end
   
  it "should not allow for duplicate-titled pages" do
    p = rmock(:page, { q: { title: "README" } })
    p.saved?.should be_false
    
    p.report_errors.should match(/already have such a page/)
  end
    
  context "Placement" do
    it "should reject self-parenting" do
      f = valid! rmock(:folder)
      f.update({ folder: f }).should be_false
      f.report_errors.should match(/cannot add a folder to itself/)
    end
    
    it "should reject child becoming a parent" do
      f = valid! rmock(:folder)
      c = valid! rmock(:folder, { q: { folder: f }})
      f.update({ folder: c })
      f.report_errors.should match(/cannot become its child/)
    end
    
    it "should not allow nesting of cross-space folders" do
      new_space = valid! @u.owned_spaces.create({ title: "Moo" })
      
      f = invalid! @u.folders.create({ title: "Test", folder: @u.spaces.first.root_folder, space: new_space })
      f.report_errors.should match(/is not in the same space!/)
    end
    
    it "should reject parent-less placement" do
      f = invalid! rmock(:folder, { q: { folder: nil }})
      f.report_errors.should match(/must be set inside another/)
    end
  end    
  
  describe "Instance methods" do
    before do
      @root        = @space.root_folder
      @parent      = rmock(:folder, { q: { title: "Parent" }})
      @child       = rmock(:folder, { q: { title: "Child", folder: @parent } })
      @grandchild  = rmock(:folder, { q: { title: "Granchild", folder: @child  } })
      @uncle       = rmock(:folder, { q: { title: "Uncle" }})
    end
    
    it "siblings()" do
      @root.siblings.count.should == 0
      @parent.siblings.count.should == 1
      f3 = rmock(:folder)
      @parent.siblings.count.should == 2
    end
    
    it "is_child_of?" do
      @grandchild.is_child_of?(@child).should   be_true
      @grandchild.is_child_of?(@parent).should  be_true
      @grandchild.is_child_of?(@root).should    be_true
      @grandchild.is_child_of?(@uncle).should   be_false
    end
    
    it "ancestors" do
      @root.ancestors.should         == [ ]
      @parent.ancestors.should       == [ @root ]
      @child.ancestors.should        == [ @parent, @root ]
      @grandchild.ancestors.should   == [ @child, @parent, @root ]
    end
    
    it "descendants" do
      @root.descendants.should  == [ @grandchild, @child, @parent, @uncle ]
      @uncle.descendants.should == [ ]
      @child.descendants.should == [ @grandchild ]
    end
  end
    
  context "Destruction" do
    it "should be destroyed" do
      f = rmock(:folder)
      f.editor = @u
      rc = f.destroy
      rc.should be_true
    end
    
    it "should not be destroyed if it's the root folder" do
      f = @s.root_folder
      f.editor = @u
      f.destroy.should be_false
      f.report_errors.should match(/can not remove the root/)
    end
    
    it "should not be destroyed if no editor is assigned" do
      f = @s.folders.create({ title: "Test" })
      f.destroy.should be_false
      f.report_errors.should match(/editor must be assigned/)
    end
        
    it "should not be destroyed if it contains folders created by others" do
      mockup_another_user()
      
      @u1 = @u
      
      parent = @u2.folders.create({ title: "Test", space: @s2 })
      parent.saved?.should be_true
      parent.creator.should == @u2
      
      child = @u1.folders.create({ title: "Test", folder: parent, space: @s2 })
      child.saved?.should be_true
      child.creator.should == @u1      
      
      parent.editor = @u2 # creator
      parent.destroy.should be_false
      parent.report_errors.should match(/folder contains others created by someone else/)
    end
    
    it "should be destroyed only by the creator" do
      mockup_another_user()
      
      f = rmock(:folder)
      
      [ :member, :editor, :admin ].each do |role|
        f.errors.clear
        
        f.space.send(:"add_#{role}", @u2)
        f.editor = @u2
        f.destroy.should be_false
        f.report_errors.should match(/not authorized to delete/)
      end
    end  
    
    it "should attach its descendants to its parent folder" do
      f = rmock(:folder)
      p = rmock(:page, { q: { folder: f } })
      p.folder.should == f
      f.editor = @u
      f.destroy.should be_true
      p.refresh.folder.should == @space.root_folder
      
      f   = rmock(:folder)
      cf  = rmock(:folder,  { q: { folder: f } })
      p   = rmock(:page,    { q: { folder: f } })
      cp  = rmock(:page,    { q: { folder: cf }})
      
      f.editor = @u
      f.destroy.should be_true
      p.refresh.folder.should == @space.root_folder
      cf.refresh.folder.should == @space.root_folder
      cp.refresh.folder.should == cf
      
      f   = rmock(:folder)
      cf  = rmock(:folder,  { q: { folder: f } })
      p   = rmock(:page,    { q: { folder: f } })
      cp  = rmock(:page,    { q: { folder: cf }})
      
      cf.editor = @u
      cf.destroy.should be_true
      p.refresh.folder.should ==  f
      cp.refresh.folder.should == f      
    end
    
    it "should prefix its homepage title when migrating to parent folder" do
      f = valid! rmock(:folder)
      f.create_homepage
      
      folder_title = f.title
      
      f.editor = @u
      f.destroy.should be_true
      
      @s.pages.all({ title: "#{folder_title} - README" }).count.should == 1
    end
    
  end # Destruction context

end