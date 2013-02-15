module Fixtures
  
  class << self
    def [](type)
      @@fixtures ||= {}
      @@fixtures[type.to_sym].new
    end
    
    def register
      @@fixtures ||= {}
      # @@fixtures[type.to_sym] = klass
      constants.reject { |k| k == :Fixture }.each do |kname|
        @@fixtures[kname.to_s.gsub(/Fixture/, '').downcase.to_sym] = eval "Fixtures::#{kname.to_s}"
      end
    end
    
    def available_fixtures
      @@fixtures ||= {}
      @@fixtures.collect { |type,_| type }
    end
    
    def teardown
      User.destroy.should == true
      [ 
        User,
        Page,
        PublicPage,
        CarbonCopy,
        Revision,
        Folder,
        Space,
        SpaceUser,
        EmailVerification
      ].each do |r|
        unless r.count == 0
          raise "[ERROR] Cleanup: expected #{r} to contain 0 resources, but got #{r.count}"
        end
      end
    end
  end
  
  class Fixture
    attr_reader :params
    
    def cleanup
      raise "Must be implemented by child."
    end
    
    def build(params = {})
      raise "Must be implemented by child."
    end
    
    def salt
      PageHub::Helpers.tiny_salt
    end
    
    def accept(params, p = @params)
      params.each_pair { |k,v|
        next unless p.has_key?(k)
        
        if v.is_a?(Hash)
          accept(v, p)
          next
        end
        
        p[k] = v
      }
      p
    end
  end
  
  class UserFixture < Fixture
    attr_reader :password
    
    def build(params, cleanup = false)
      Fixtures.teardown if cleanup
      
      @password ||= 'verysalty123'
      
      @params = accept(params, {
        name:     'Mysterious Mocker',
        email:    'very@mysterious.com',
        provider: 'pagehub',
        password:               @password,
        password_confirmation:  @password
      })
      
      u,s,f = nil,nil,nil
      
      if u = User.create(@params)
        if s = u.default_space
          f = s.root_folder
        end
      end
      
      [ u, s, f ]
    end
  end
  
  class PageFixture < Fixture
    def build(p)
      Page.create(accept(p, {
        title: "Mocky page #{salt}",
        content: "Teehee.",
        creator: nil,
        browsable: false,
        folder:  nil        
      }))
    end
  end
  
  class FolderFixture < Fixture
    def build(p)
      Folder.create(accept(p, {
        title: "Mocky folder #{salt}",
        browsable: false,
        space: nil,
        folder: nil,
        creator: nil
      }))
    end
  end
  
  class SpaceFixture < Fixture
    def build(p)
      Space.create(accept(p, {
        title: "The Zoo",
        brief: "Where all monkeys meet.",
        is_public: false,
        creator: nil
      }))
    end
  end
end

Fixtures.register
puts "Available fixtures: #{Fixtures.available_fixtures}"

# resource mock
def fixture(resource, o = {})
  case resource
  when :user
    # Fixtures[:user].build(o, true)
    # @u, @s, @f = *create_user(o, cleanup)
    @u, @s, @f = *Fixtures[:user].build(o, true)
    @user, @space, @root = @u, @s, @f
    @u.saved?
  when :another_user
    # @u2, @s2, @f2 = create_user({ email: "more@mysterious" }, false)
    @u2, @s2, @f2 = *Fixtures[:user].build({ email: "more@mysterious.com" }.merge(o))
    @user2, @space2, @root2 = @u2, @s2, @f2
    @u2.saved?    
  when :folder
    Fixtures[:folder].build({
      creator: @u,
      space: @s,
      folder: @f
    }.merge(o))
  when :page
    Fixtures[:page].build({
      creator: @u,
      folder:  @f
    }.merge(o))
  when :space
    Fixtures[:space].build({
      creator: @u
    }.merge(o))
  when :space_with_users
    s = Fixtures[:space].build({
      creator: @u
    }.merge(o))
    
    (SpaceUser::Flags - [:creator]).each do |role|
      u, _, _ = *Fixtures[:user].build({ email: "#{PageHub::Helpers.tiny_salt}@foobar.com" })
      s.send("add_#{role}", u)
    end
    
    s
  end
end

def invalid!(r)
  r.saved?.should be_false
  r
end

def valid!(r)
  r.saved?.should be_true
  r
end

