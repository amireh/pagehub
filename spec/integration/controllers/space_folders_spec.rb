describe "Space folders" do
  before(:all) do
    fixture(:user)
  end

  after(:all) do
    Fixtures.teardown
  end

  before do
    sign_in
  end

  context "as a space editor" do

    it "i get a folder" do
      f = valid! fixture(:folder)
      expect { api_call get "/spaces/#{@s.id}/folders/#{f.id}" }.to succeed
    end

    it "i create a folder" do
      expect {
        api_call post "/spaces/#{@s.id}/folders", {
          title:      "Some Folder 1"
        }
      }.to succeed
    end

    it "i create a nested folder" do
      expect {
        api_call post "/spaces/#{@s.id}/folders", {
          title:      "Some Folder 2"
        }
      }.to succeed

      expect {
        api_call post "/spaces/#{@s.id}/folders", {
          title:      "Some Folder 2",
          parent_id:  @s.refresh.folders.last.id
        }
      }.to succeed
    end

    it "i update a folder" do
      f = valid! fixture(:folder)

      rc = api_call put "/spaces/#{@s.id}/folders/#{f.id}", {
        title: "dom dom"
      }

      rc.should succeed(200)
      rc.body["folder"]["title"].should == 'dom dom'
    end

    context "killing things" do
      before do
        fixture(:user)
      end

      after(:all) do
        fixture(:user)
      end

      it "i delete a folder" do
        f = valid! fixture(:folder)

        expect {
          api { delete "/spaces/#{@s.id}/folders/#{f.id}" }
        }.to succeed(200)
      end

      it "i delete the root folder" do
        expect {
          api { delete "/spaces/#{@s.id}/folders/#{@f.id}" }
        }.to succeed(200)
        @s.refresh.folders.count.should == 0
      end
    end

    it "i re-arrange a folder" do
      f   = valid! fixture(:folder)
      f2  = valid! fixture(:folder)

      rc = api_call put "/spaces/#{@s.id}/folders/#{f.id}", {
        parent_id: f2.id
      }

      rc.should succeed(200)
      rc.body["folder"]["parent"]["id"].to_i.should == f2.id
    end

    it "i re-arrange a folder into itself" do
      f   = valid! fixture(:folder)

      rc = api_call put "/spaces/#{@s.id}/folders/#{f.id}", {
        parent_id: f.id
      }

      rc.should fail(400, 'itself')
    end

    it "i re-arrange a folder into outer space" do
      fixture(:another_user)
      f   = valid! fixture(:folder)
      f2  = valid! fixture(:folder, { creator: @u2, space: @s2, folder: @s2.root_folder })

      rc = api_call put "/spaces/#{@s.id}/folders/#{f.id}", {
        parent_id: f2.id
      }

      rc.should fail(400, 'No such parent')
    end

    it "i re-arrange a folder into a child of it" do
      f   = valid! fixture(:folder)
      f2  = valid! fixture(:folder, { folder: f })

      rc = api_call put "/spaces/#{@s.id}/folders/#{f.id}", {
        parent_id: f2.id
      }

      rc.should fail(400, 'cannot become its child')
    end
  end

end