require "authlogic_cas/session"
 
Authlogic::Session::Base.send(:include, AuthlogicCas::Session)
