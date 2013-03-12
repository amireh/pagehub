describe Helpers::Preferences do
  include Helpers::Preferences

  def current_user() @user end

  context "Instance Methods" do
    it '#p with defaults' do
      p('app.pulses.runtime_preferences').should be_true
      p('app.pulses.runtime_preferencesxyzxyz').should be_false
    end

    it '#p with a scope' do
      valid! fixture(:user)
      p('skin', @user).should == 'light'
      @user.destroy
    end

    it '#checkify' do
      checkify('app.pulses.runtime_preferences') { |o| o == 1000 }.should match(/checked/)
      checkify('app.pulses.runtime_preferencesxyz').should == ''
      checkify { true }.should match(/checked/)
      checkify { false }.should == ''
    end

    it '#selectify' do
      selectify('app.pulses.runtime_preferences') { |o| o == 1000 }.should match(/selected/)
      selectify('app.pulses.runtime_preferencesxyz').should == ''
      selectify { true }.should match(/selected/)
      selectify { false }.should == ''
    end

    it '#disabilify' do
      disabilify('app.pulses.runtime_preferences') { |o| o == 1000 }.should match(/disabled/)
      disabilify('app.pulses.runtime_preferencesxyz').should == ''
      disabilify { true }.should match(/disabled/)
      disabilify { false }.should == ''
    end

  end
end