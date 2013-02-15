describe Folder do
  before do
    fixture(:user)
  end

  it "should be created" do
    f = valid! fixture(:folder)
    f.folder.should == f.space.root_folder
  end
  
  it "should nest folders" do
    f = valid! fixture(:folder)
    f = valid! fixture(:folder, { folder: f })
  end
    
  it "should nest folders with the same title in different levels" do
    f = valid! fixture(:folder, { title: "Mock" })
    f = valid! fixture(:folder, { title: "Mock", folder: f })
  end
  
  it "should not allow for duplicate-titled folders" do
    f = valid! fixture(:folder, { title: "Test" })
    f = invalid! fixture(:folder, { title: "Test" })

    f.report_errors.should match(/already have a folder with that title/)
  end
   
  it "should not allow for duplicate-titled pages" do
    p = fixture(:page, { title: "README" })
    p.saved?.should be_false
    
    p.report_errors.should match(/already have such a page/)
  end
    
  context "Placement" do
    it "should reject self-parenting" do
      f = valid! fixture(:folder)
      f.update({ folder: f }).should be_false
      f.report_errors.should match(/cannot add a folder to itself/)
    end
    
    it "should reject child becoming a parent" do
      f = valid! fixture(:folder)
      c = valid! fixture(:folder, { folder: f })
      f.update({ folder: c })
      f.report_errors.should match(/cannot become its child/)
    end
    
    it "should not allow nesting of cross-space folders" do
      new_space = valid! @u.owned_spaces.create({ title: "Moo" })
      
      f = invalid! @u.folders.create({ title: "Test", folder: @u.spaces.first.root_folder, space: new_space })
      f.report_errors.should match(/is not in the same space!/)
    end
    
    it "should reject parent-less placement" do
      f = invalid! fixture(:folder, { folder: nil })
      f.report_errors.should match(/must be set inside another/)
    end
  end    
  
  describe "Instance methods" do
    before do
      @root        = @space.root_folder
      @parent      = valid! fixture(:folder, { title: "Parent" })
      @child       = valid! fixture(:folder, { title: "Child",     folder: @parent })
      @grandchild  = valid! fixture(:folder, { title: "Granchild", folder: @child  })
      @uncle       = valid! fixture(:folder, { title: "Uncle" })
    end
    
    it "siblings()" do
      @root.siblings.count.should == 0
      @parent.siblings.count.should == 1
      f3 = valid! fixture(:folder)
      @parent.refresh.siblings.count.should == 2
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
      f = fixture(:folder)
      rc = f.destroy
      rc.should be_true
    end
    
    # it "should not be destroyed if it's the root folder" do
    #   f = @s.root_folder
    #   f.destroy.should be_false
    #   f.report_errors.should match(/can not remove the root/)
    # end
    
    # it "should not be destroyed if no editor is assigned" do
    #   f = @s.folders.create({ title: "Test" })
    #   f.destroy.should be_false
    #   f.report_errors.should match(/editor must be assigned/)
    # end
        
    it "should not be destroyed if it contains folders created by others" do
      fixture(:another_user)
      
      @u1 = @u
      
      parent = @u2.folders.create({ title: "Test", space: @s2 })
      parent.saved?.should be_true
      parent.creator.should == @u2
      
      child = @u1.folders.create({ title: "Test", folder: parent, space: @s2 })
      child.saved?.should be_true
      child.creator.should == @u1      
      
      # parent.editor = @u2 # creator
      # parent.destroy.should be_false
      s, msg = *parent.deletable_by?(@u2)
      s.should be_false 
      msg.should match(/folder contains others created by someone else/)
    end
    
    it "should be destroyed only by the creator" do
      fixture(:another_user)
      
      f = fixture(:folder)
      # f.space.editor = f.space.creator
      
      [ :member, :editor, :admin ].each do |role|
        f.errors.clear
        
        f.space.send(:"add_#{role}", @u2)
        # f.editor = @u2
        # f.destroy.should be_false
        # f.report_errors.should match(/not authorized to delete/)
        s, msg = *f.deletable_by?(@u2)
        s.should be_false 
        msg.should match(/not authorized to delete/)
      end
    end  
    
    it "should attach its descendants to its parent folder" do
      f = fixture(:folder)
      p = fixture(:page, { folder: f })
      p.folder.should == f
      f.nullify_references.destroy.should be_true
      p.refresh.folder.should == @space.root_folder
      
      f   = fixture(:folder)
      cf  = fixture(:folder,  { folder: f })
      p   = fixture(:page,    { folder: f })
      cp  = fixture(:page,    { folder: cf })
      
      f.nullify_references.destroy.should be_true
      p.refresh.folder.should == @space.root_folder
      cf.refresh.folder.should == @space.root_folder
      cp.refresh.folder.should == cf
      
      f   = fixture(:folder)
      cf  = fixture(:folder,  { folder: f })
      p   = fixture(:page,    { folder: f })
      cp  = fixture(:page,    { folder: cf })
      
      cf.nullify_references.destroy.should be_true
      p.refresh.folder.should ==  f
      cp.refresh.folder.should == f      
    end
    
    it "should prefix its homepage title when migrating to parent folder" do
      f = valid! fixture(:folder)
      f.create_homepage
      
      folder_title = f.title
      
      f.nullify_references.destroy.should be_true
      
      @s.pages.all({ title: "#{folder_title} - README" }).count.should == 1
    end
    
  end # Destruction context

end