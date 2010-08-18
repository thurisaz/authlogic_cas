module AuthlogicCas
  module Session
    def self.included(klass)
      klass.class_eval do
        include Methods
      end
    end

    module Methods
      def self.included(klass)
        klass.class_eval do
          persist.reject{|cb| [:persist_by_params,:persist_by_session,:persist_by_http_auth].include?(cb.method)}
          persist :persist_by_cas, :if => :authenticating_with_cas?
        end
      end

      # no credentials are passed in: the CAS server takes care of that and saving the session
      # def credentials=(value)
      #   values = [:garbage]
      #   super
      # end

      def persist_by_cas
        session_key = CASClient::Frameworks::Rails::Filter.client.username_session_key

        unless controller.session[session_key].blank?
          self.attempted_record = search_for_record("find_by_#{klass.login_field}", controller.session[session_key])
        end
        !self.attempted_record.nil?
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
