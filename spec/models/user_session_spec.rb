require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'authlogic/test_case'

describe UserSession do
  fixtures :users

  before(:all) do
    activate_authlogic
    @charles = User.find_by_login 'charles'
  end

  it "checks to see that the Rubycas plugin is installed before persisting" do
    user_session = UserSession.new
    has_plugin = user_session.send :cas_defined?
    has_plugin.should == (CASClient::Frameworks::Rails::Filter.config.nil? ? false : true)
  end

  it "checks for existing user records before persisting" do
    controller.session[CASClient::Frameworks::Rails::Filter.client.username_session_key] = @charles.login
    user_session = UserSession.find
    user_session.user.login.should == @charles.login
  end

  it "checks for the existence of the CAS session key" do
    controller.session.delete CASClient::Frameworks::Rails::Filter.client.username_session_key
    user_session = UserSession.find
    user_session.should == nil
  end

  it "creates a user if none exists with the login column in CAS session" do
    controller.session[CASClient::Frameworks::Rails::Filter.client.username_session_key] = 'darwin'

    user_session = UserSession.find
    user_session.user.login.should == 'darwin'
  end

  it "throws an error if it cannot create a new user when none previously existed" do
     big_name = 'must explain to you how all this mistaken idea of denouncing pleasure and praising pain was born and I will give you a complete account of the system, and expound the actual teachings of the great explorer of the truth, the master-builder of human happiness. No one rejects, dislikes, or avoids pleasure itself, because it is pleasure, but because those who do not know how to pursue pleasure rationally encounter consequences that are extremely painful. Nor again is there anyone who loves or pursues or desires to obtain pain of itself, because it is pain, but because occasionally circumstances occur in which toil and pain can procure him some great pleasure. To take a trivial example, which of us ever undertakes laborious physical exercise, except to obtain some advantage from it? But who has any right to find fault with a man who chooses to enjoy a pleasure that has no annoying consequences, or one who avoids a pain that produces no resultant pleasure?'
    controller.session[CASClient::Frameworks::Rails::Filter.client.username_session_key] = big_name
    user_session = UserSession.find
    user_session.should == nil
  end

  it "looks up CAS users with nonstandard columns" do
    @user = users(:charles)
    controller.session[CASClient::Frameworks::Rails::Filter.client.username_session_key] = @user.email
    UserSession.cas_user_identifier = 'email'
    user_session = UserSession.find
    user_session.user.login.should == @user.email
  end
end
