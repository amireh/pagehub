describe "Access control" do
  describe "Pages" do
    before(:all) do
      fixture(:user)
      fixture(:another_user)
      @page = valid! fixture(:page, { creator: @u, folder: @f })
    end

    after(:all) do
      Fixtures.teardown
    end

    before do
      sign_in(@u2)
      cleanup_routes
    end

    it "as a member" do
      @s.add_member(@u2)
      app.get('/spec/:space_id/:page_id', auth: :user, :requires => [ :space, :page ]) {
        [
          (can? :read,    @page),
          (can? :author,  @space),
          (can? :update,  @page),
          (can? :delete,  @page)
        ].to_json
      }
      api { get "/spec/#{@s.id}/#{@page.id}" }.body.should == [ true, false, false, false ]
    end

    it "as an editor" do
      @s.add_editor(@u2)
      app.get('/spec/:space_id/:page_id', auth: :user , :requires => [ :space, :page ]) {
        [
          (can? :read,    @page),
          (can? :author,  @space),
          (can? :update,  @page),
          (can? :delete,  @page)
        ].to_json
      }
      api { get "/spec/#{@s.id}/#{@page.id}" }.body.should == [ true, true, true, false ]
    end

    it "as an admin" do
      @s.add_admin(@u2)
      app.get('/spec/:space_id/:page_id', auth: :user , :requires => [ :space, :page ]) {
        [
          (can? :read,    @page),
          (can? :author,  @space),
          (can? :update,  @page),
          (can? :delete,  @page)
        ].to_json
      }
      api { get "/spec/#{@s.id}/#{@page.id}" }.body.should == [ true, true, true, true ]
    end
    it "as a creator" do
      sign_in(@u)
      app.get('/spec/:space_id/:page_id', auth: :user, :requires => [ :space, :page ]) {
        [
          (can? :read,    @page),
          (can? :author,  @space),
          (can? :update,  @page),
          (can? :delete,  @page)
        ].to_json
      }
      api { get "/spec/#{@s.id}/#{@page.id}" }.body.should == [ true, true, true, true ]
    end

  end

  describe "Folders" do
    before(:all) do
      fixture(:user)
      fixture(:another_user)
      @f = valid! fixture(:folder, { creator: @u, space: @s })
    end

    after(:all) do
      Fixtures.teardown
    end

    before do
      sign_in(@u2)
      cleanup_routes
    end

    it "as a member" do
      @s.add_member(@u2)
      app.get('/spec/:space_id/:folder_id', auth: :user, :requires => [ :space, :folder ]) {
        [
          (can? :read,    @folder),
          (can? :author,  @space),
          (can? :update,  @folder),
          (can? :delete,  @folder)
        ].to_json
      }
      api { get "/spec/#{@s.id}/#{@f.id}" }.body.should == [ true, false, false, false ]
    end

    it "as an editor" do
      @s.add_editor(@u2)
      app.get('/spec/:space_id/:folder_id', auth: :user, :requires => [ :space, :folder ]) {
        [
          (can? :read,    @folder),
          (can? :author,  @space),
          (can? :update,  @folder),
          (can? :delete,  @folder)
        ].to_json
      }
      api { get "/spec/#{@s.id}/#{@f.id}" }.body.should == [ true, true, true, false ]
    end

    it "as an admin" do
      @s.add_admin(@u2)
      app.get('/spec/:space_id/:folder_id', auth: :user, :requires => [ :space, :folder ]) {
        [
          (can? :read,    @folder),
          (can? :author,  @space),
          (can? :update,  @folder),
          (can? :delete,  @folder)
        ].to_json
      }
      api { get "/spec/#{@s.id}/#{@f.id}" }.body.should == [ true, true, true, true ]
    end

    it "as a creator" do
      sign_in(@u)
      app.get('/spec/:space_id/:folder_id', auth: :user, :requires => [ :space, :folder ]) {
        [
          (can? :read,    @folder),
          (can? :author,  @space),
          (can? :update,  @folder),
          (can? :delete,  @folder)
        ].to_json
      }
      api { get "/spec/#{@s.id}/#{@f.id}" }.body.should == [ true, true, true, true ]
    end
  end

  describe "Spaces" do
    before(:all) do
      fixture(:user)
      fixture(:another_user)
      @space = valid! fixture(:space, { creator: @u })
    end

    after(:all) do
      Fixtures.teardown
    end

    before do
      sign_in(@u2)
      cleanup_routes
    end

    it "as a member" do
      @space.add_member(@u2)
      app.get('/spec/:space_id', auth: :user, :requires => [ :space ]) {
        [
          (can? :read,    @space),
          (can? :create,  Space),
          (can? :update,  @space),
          (can? :delete,  @space)
        ].to_json
      }
      api { get "/spec/#{@space.id}" }.body.should == [ true, true, false, false ]
    end

    it "as an editor" do
      @space.add_editor(@u2)
      app.get('/spec/:space_id', auth: :user, :requires => [ :space ]) {
        [
          (can? :read,    @space),
          (can? :create,  Space),
          (can? :update,  @space),
          (can? :delete,  @space)
        ].to_json
      }
      api { get "/spec/#{@space.id}" }.body.should == [ true, true, false, false ]
    end

    it "as an admin" do
      @space.add_admin(@u2)
      u3 = valid! fixture(:some_user)
      u4 = valid! fixture(:some_user)
      u5 = valid! fixture(:some_user)
      u6 = valid! fixture(:some_user)
      @space.add_member(u3)
      @space.add_editor(u4)
      @space.add_admin(u5)

      sign_in(@u2)

      app.get('/spec/:space_id', auth: :user, :requires => [ :space ]) {
        member  = @space.users.get(params[:member_id])
        editor  = @space.users.get(params[:editor_id])
        admin   = @space.users.get(params[:admin_id])
        guest   = User.get(params[:guest_id])

        [
          (can? :read,    @space),
          (can? :create,  Space),
          (can? :update,  @space),
          (can? :update_meta,  @space),
          (can? :invite,  [ @space, guest, :member ]),
          (can? :invite,  [ @space, guest, :editor ]),
          (can? :invite,  [ @space, guest, :admin  ]),
          (can? :kick,    [ @space, member ]),
          (can? :kick,    [ @space, editor ]),
          (can? :kick,    [ @space, admin  ]),
          (can? :promote, [ @space, member, :editor ]),
          (can? :promote, [ @space, editor, :admin ]),
          (can? :demote,  [ @space, editor, :member ]),
          (can? :demote,  [ @space, admin, :member ]),
          (can? :delete,  @space)
        ].to_json
      }
      api {
        get "/spec/#{@space.id}", {
          member_id: u3.id,
          editor_id: u4.id,
          admin_id:  u5.id,
          guest_id:  u6.id
        }
      }.body.should ==
        [
          true,   # read
          true,   # create
          true,   # update
          false,  # update_meta
          true,   # invite member
          true,   # invite editor
          false,  # invite admin
          true,   # kick member
          true,   # kick editor
          false,  # kick admin
          true,   # promote member to editor
          false,  # promote editor to admin
          true,   # demote editor to member
          false,  # demote admin
          false,  # delete
        ]
    end

    it "as a creator" do
      sign_in(@u)
      u3 = valid! fixture(:some_user)
      u4 = valid! fixture(:some_user)
      u5 = valid! fixture(:some_user)
      u6 = valid! fixture(:some_user)
      @space.add_member(u3)
      @space.add_editor(u4)
      @space.add_admin(u5)

      app.get('/spec/:space_id', auth: :user, :requires => [ :space ]) {
        member  = @space.users.get(params[:member_id])
        editor  = @space.users.get(params[:editor_id])
        admin   = @space.users.get(params[:admin_id])
        guest   = User.get(params[:guest_id])

        [
          (can? :read,    @space),
          (can? :create,  Space),
          (can? :update,  @space),
          (can? :update_meta, @space),
          (can? :invite,  [ @space, guest, :member ]),
          (can? :invite,  [ @space, guest, :editor ]),
          (can? :invite,  [ @space, guest, :admin  ]),
          (can? :kick,    [ @space, member ]),
          (can? :kick,    [ @space, editor ]),
          (can? :kick,    [ @space, admin  ]),
          (can? :promote, [ @space, member, :editor ]),
          (can? :promote, [ @space, editor, :admin ]),
          (can? :demote,  [ @space, editor, :member ]),
          (can? :demote,  [ @space, admin, :member ]),
          (can? :delete,  @space)
        ].to_json
      }
      api {
        get "/spec/#{@space.id}", {
          member_id: u3.id,
          editor_id: u4.id,
          admin_id:  u5.id,
          guest_id:  u6.id
        }
      }.body.should ==
        [
          true,  # read
          true,  # create
          true,  # update
          true,  # update_meta
          true,  # invite member
          true,  # invite editor
          true,  # invite admin
          true,  # kick member
          true,  # kick editor
          true,  # kick admin
          true,  # promote member to editor
          true,  # promote editor to admin
          true,  # demote editor to member
          true,  # demote admin
          true,  # delete
        ]
    end # as a creator context

    it "as a guest" do
      sign_out

      some_space = valid! fixture(:space, { is_public: true })
      app.get('/spec/:space_id', auth: :guest, :requires => [ :space ]) {
        [
          (can? :read,    @space),
          (can? :browse,  @space),
          (can? :create,  Space),
          (can? :update,  @space),
          (can? :delete,  @space)
        ].to_json
      }
      api { get "/spec/#{some_space.id}" }.body.should == [ false, true, false, false, false ]
    end

  end # Spaces context
end