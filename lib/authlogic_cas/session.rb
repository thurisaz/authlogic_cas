module AuthlogicCas
  module Session
    def self.included(klass)
      klass.class_eval do
        extend Config
        include Methods
      end
    end
 
    module Config
      def cas_user_identifier(value = nil)
        rw_config :cas_user_identifier, value, 'login'
      end
      alias_method :cas_user_identifier=, :cas_user_identifier
    end
 
    module Methods
      def self.included(klass)
        session_tmp = "#{RAILS_ROOT}/tmp/sessions"
        FileUtils.mkdir_p session_tmp unless File.directory?(session_tmp)

        klass.class_eval do
          klass.persist.clear #eliminate any other callbacks, since they insist on intruding and causing trouble
          persist :persist_by_cas, :if => :authenticating_with_cas?
        end
      end

      #no credentials are passed in: the CAS server takes care of that and saving the session
      def credentials=(value)
        values = [:garbage]
        super
      end

      def persist_by_cas
        session_key = CASClient::Frameworks::Rails::Filter.client.username_session_key
        if controller.session.key?(session_key) && !controller.session[session_key].blank?
          record = search_for_record("find_by_#{UserSession.cas_user_identifier}", controller.session[session_key])

          if record.nil?
           #RELIES ON this method to securely validate that this user request stems from a real user
            record = User.new({:login => controller.session[session_key], User.crypted_password_field => 'ignore', User.password_salt_field => 'ignore'})

            if record.login.length > 255
              record = nil
            end
          end

          self.attempted_record = self.unauthorized_record = record
        end

        self.unauthorized_record.nil? ? false : true
      end

      def authenticating_with_cas?
        attempted_record.nil? && errors.empty? && cas_defined?
      end

      private

      #todo: validate that cas filters have run.  Authlogic controller adapter doesn't provide access to the filter_chain
      def cas_defined?
        defined?(CASClient::Frameworks::Rails::Filter) && !CASClient::Frameworks::Rails::Filter.config.nil?
      end
    end
  end
end
