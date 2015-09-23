require "restforce"
require "restforce_mock/sandbox"

module RestforceMock
  class Client

    include ::Restforce::Concerns::API
    include RestforceMock::Sandbox

    def api_patch(url, attrs)
      url=~/sobjects\/(.+)\/(.+)/
      object=$1
      id=$2
      validate_presence!(object, id)
      update_object(object, id, attrs)
    end

    def api_post(url, attrs)
      url=~/sobjects\/(.+)/
      sobject = $1
      id = SecureRandom.urlsafe_base64(13) #duplicates possible
      validate_requires!(sobject, attrs)
      add_object(sobject, id, attrs)
      return Body.new(id)
    end

    def validate_requires!(sobject, attrs)
      return unless RestforceMock.configuration.schema_file

      object_schema = schema[sobject]
      required = object_schema.select{|k,v|!v[:nillable]}.collect{|k,v|k}

      missing = required - attrs.keys
      if missing.length > 0
        raise Faraday::Error::ResourceNotFound.new(
          "REQUIRED_FIELD_MISSING: Required fields are missing: #{missing}")
      end
    end

    def validate_presence!(object, id)
      unless RestforceMock::Sandbox.storage[object][id]
        msg = "Provided external ID field does not exist or is not accessible: #{id}"
        raise Faraday::Error::ResourceNotFound.new(msg)
      end
    end

    private

    def schema
      RestforceMock::SchemaManager.new.load_schema(RestforceMock.configuration.schema_file)
    end

    class Body
      def initialize(id)
        @body = {'id' => id}
      end

      def body
        @body
      end
    end
  end
end
