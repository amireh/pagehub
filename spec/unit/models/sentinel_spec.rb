# $VERBOSE=true
describe Sentinel do
  def cleanup()
    Object.constants.select { |c| c.to_s =~ /Victim/ }.each { |c|
      Object.send(:remove_const, c.to_sym)
    }
  end
  
  before do
    class Victim
      attr_accessor :reason
      
      def hunt(reason = '')
        @reason = reason
        kill
      end
      
      def kill
        "Ah, shit."
      end
      
      include Sentinel
    end
    
    class MethodVictim < Victim
      def justicar
        reason =~ /fun/
      end
      
      guard :kill, with: :justicar
    end
    
    class InheritedMethodVictim < MethodVictim
    end
  end
  
  after do
    cleanup
  end
  
  it "should scope guards per class" do
    class Victim1 < Victim
      guard :hunt do end
    end
    
    class GrandVictim < Victim1
      guard :kill do end
    end
    
    class Victim2 < Victim     
      def guardian
      end
      
      guard :hunt do end
      guard :kill, with: :guardian
    end
    
    Victim1.guards_for(:hunt).length.should == 1
    Victim1.guards_for(:kill).length.should == 0
    Victim2.guard_map.length.should == 2
    GrandVictim.guards_for(:kill).length.should == 1
  end
  
  it "should inherit guards" do
    class ParentVictim < Victim
      guard :hunt do
        puts "parent"
      end
    end
    
    class ChildVictim < ParentVictim      
      guard :hunt do
        puts 'child'
      end
    end
      
    ChildVictim.guards_for(:hunt).length.should == 2

    ParentVictim.stub!(:puts)
    ParentVictim.should_receive(:puts).with('parent')
    ParentVictim.new.hunt('')

    ChildVictim.stub!(:puts)
    ChildVictim.should_receive(:puts).with('child')
    ParentVictim.should_receive(:puts).with('parent')
    ChildVictim.new.hunt('')
  end
  
  it "should guard multiple methods" do
    class Victim
      guard [ :hunt, :kill ] do |_, m, *__|
        puts "From #{m}"
      end
    end
    
    Victim.guards_for(:hunt).length.should == 1
    Victim.guards_for(:kill).length.should == 1
    Victim.stub!(:puts)
    Victim.should_receive(:puts).with('From hunt')
    Victim.new.hunt
    Victim.should_receive(:puts).with('From kill')
    Victim.new.kill
  end
  
  it "should respect the failure guards" do
    class Victim
      guard :hunt do |*_|
        false
      end
      
      guard :hunt, stage: :on_failure do |*_|
        puts "blown up"
      end
    end
    
    Victim.stub!(:puts)
    Victim.should_receive(:puts).with('blown up')
    Victim.new.hunt
  end
  
  it "should take precedence over parent's guards" do
    class ParentVictim < Victim
      guard :hunt do
        raise "parent"
      end
    end
    
    class ChildVictim < ParentVictim
      guard :hunt do
        raise 'child'
      end
    end
      
    ChildVictim.guards_for(:hunt).length.should == 2
    expect { ChildVictim.new.hunt('justice') }.to raise_error(RuntimeError, 'child')
  end
  
  context "Pre-emptive guards" do
    it "should guard using a block" do
      class ProcVictim < Victim
        guard :kill do |v, *args|
          v.reason =~ /justice/
        end
      end
      
      ProcVictim.new.hunt('for justice!').should == 'Ah, shit.'
      ProcVictim.new.hunt('for fun').should == false
    end
    
    it "should guard using a defined method" do
      MethodVictim.new.hunt('for fun').should == 'Ah, shit.'
      MethodVictim.new.hunt('for justice!').should == false      
    end

    it "should guard using an inherited method" do
      MethodVictim.guards_for(:kill).length.should == 1
      InheritedMethodVictim.guards_for(:kill).length.should == 1
      InheritedMethodVictim.new.hunt('for fun').should == 'Ah, shit.'
      InheritedMethodVictim.new.hunt('for justice!').should == false
    end
            
    it "should use guards across the inheritance chain" do
      class InheritedMethodVictim < MethodVictim
        guard :kill do |*a| raise RuntimeError, 'adooken' end
      end
      
      InheritedMethodVictim.guards_for(:kill).length.should == 2
    end
  end

  it "should whine if guardian target doesn't exist" do
    expect {
      class Victim
        guard :foobar do end
      end
    }.to raise_error(ArgumentError, /No such instance method/)
  end
  
  it "should whine if guardian target is a class method" do
    expect {
      class Victim
        def self.foobar
        end
        
        guard :foobar do end
      end
    }.to raise_error(ArgumentError, /No such instance method/)
  end
  
  it "should whine if guardian is a non-existent method" do
    expect {
      class Victim
        guard :hunt, :with => :foobar
      end
    }.to raise_error(ArgumentError, /No such guardian method/)
  end
    
  it "should whine if guardian stage is invalid" do
    expect {
      class Victim
        guard :hunt, :stage => :never do
        end
      end
    }.to raise_error(ArgumentError, /method stage must be/)
  end
  
  
end