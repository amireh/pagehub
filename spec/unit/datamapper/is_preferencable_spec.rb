describe DataMapper::Is::Preferencable do
  it "should accept defaults" do
    class Foo
      include DataMapper::Resource
      
      is :preferencable, {}, { 'foo' => 'bar' }
    end
    
    f = Foo.new
    f.p('foo').should == 'bar'
  end
  
  describe "Options" do
    it ":on" do
      class Bar
        include DataMapper::Resource
        
        is :preferencable, { on: :foobar }, { 'foo' => 'bar' }
      end
      
      expect { Bar.new.foobar }.not_to raise_error
    end
  end
  
  describe "Instance methods" do
    before do
      class Foo
        include DataMapper::Resource
        
        is :preferencable
      end
      
      @r = Foo.new
    end
    
    it ".p[]" do
      @r.p['foo']['bar'] = 5
      @r.p['foo']['bar'].should == 5
      @r.p['foo'] = 10
      @r.p['foo'].should == 10
      @r.p['zoo']['bar'].should == {}
    end
    
    it ".is_on?" do
      @r.p['foo'] = 10
      @r.is_on?('foo').should be_true
      
      expect { @r.is_on?('foo.bar') }.to raise_error
      
      @r.is_on?('x.y').should be_false
      @r.p['x']['y'] = false
      @r.is_on?('x.y').should be_false
    end
    
  end
end