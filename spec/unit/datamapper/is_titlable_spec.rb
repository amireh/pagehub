describe DataMapper::Is::Preferencable do
  describe "Options" do
    it ":property" do
      class Bar
        include DataMapper::Resource

        is :titlable, { property: :foobar }
      end

      expect { Bar.new.foobar }.not_to raise_error
    end

    it ":sanitizer" do
      class Car
        include DataMapper::Resource

        is :titlable, { sanitizer: 'sane' }
      end

      expect { Car.new.sane_title }.not_to raise_error
    end
  end

  describe "Instance methods" do
    before(:all) do
      class Foo
        include DataMapper::Resource

        is :titlable
      end
    end

    before do
      @r = Foo.new
    end

    it "#build_sane_title_if_applicable" do
      @r.title                = 'gone wild'
      @r.valid?
      @r.pretty_title.should == 'gone-wild'
    end

  end
end