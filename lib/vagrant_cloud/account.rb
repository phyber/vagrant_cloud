module VagrantCloud

  class Account

    attr_accessor :username
    attr_accessor :access_token

    # @param [String] username
    # @param [String] access_token
    def initialize(username, access_token)
      @username = username
      @access_token = access_token
    end

    # @param [String] name
    # @param [Hash]
    # @return [Box]
    def get_box(name, data = nil)
      Box.new(self, name, data)
    end

    # @param [String] name
    # @param [String] description
    # @param [TrueClass, FalseClass] is_private
    # @return [Box]
    def create_box(name, description = nil, is_private = false)
      params = {:name => name}
      params[:description] = description if description
      params[:short_description] = description if description
      params[:is_private] = is_private
      data = request('post', '/boxes', {:box => params})
      get_box(name, data)
    end

    # @param [String] name
    # @param [String] description
    # @param [TrueClass, FalseClass] is_private
    # @return [Box]
    def ensure_box(name, description = nil, is_private = nil)
      begin
        box = get_box(name)
        box.data
      rescue RestClient::ResourceNotFound => e
        box = create_box(name, description, is_private)
      end

      updated_description = (!description.nil? && (description != box.description || description != box.description_short))
      updated_private = (!is_private.nil? && (is_private != box.private))
      if updated_description || updated_private
        box.update(description, is_private)
      end

      box
    end

    # @param [String] method
    # @param [String] path
    # @param [Hash] params
    # @return [Hash]
    def request(method, path, params = {})
      params[:access_token] = access_token
      result = RestClient::Request.execute(
        :method => method,
        :url => url_base + path,
        :payload => params,
        :ssl_version => 'TLSv1'
      )
      result = JSON.parse(result)
      errors = result['errors']
      raise(RuntimeError, "Vagrant Cloud returned error: #{errors}") if errors
      result
    end

    private

    # @return [String]
    def url_base
      'https://vagrantcloud.com/api/v1'
    end

  end
end
