# lots of stuff taken from https://github.com/yzhang/omniauth/commit/eafc5ff8115bcc7d62c461d4774658979dd0a48e

require 'omniauth-oauth2'

module OmniAuth
  module Strategies
    class Renren < OmniAuth::Strategies::OAuth2
      option :client_options, {
        :authorize_url => 'http://graph.renren.com/oauth/authorize',
        :token_url => 'http://graph.renren.com/oauth/token',
        :site => 'http://graph.renren.com/'
      }
      def request_phase
        super
      end

      uid { raw_info['uid'] }

      info do
        {
          "uid" => @access_token.params['user'], 
          "gender"=> (raw_info['gender'] == '0' ? 'Male' : 'Female'), 
          "image"=>raw_info['logo50'],
          'name' => raw_info['name'],
          'urls' => {
            'Kaixin' => "http://www.kaixin001.com/"
          }
        }
      end
      
      def signed_params
        params = {}
        params[:api_key] = client.id
        params[:method] = 'users.getInfo'
        params[:call_id] = Time.now.to_i
        params[:format] = 'json'
        params[:v] = '1.0'
        params[:uids] = session_key['user']['id']
        params[:session_key] = session_key['renren_token']['session_key']
        params[:sig] = Digest::MD5.hexdigest(params.map{|k,v| "#{k}=#{v}"}.sort.join + client.secret)
        puts 
        puts params.inspect
        params
      end

      def session_key
        puts @access_token.inspect
        @session_key ||= MultiJson.decode(@access_token.get('/renren_api/session_key'))
      end

      def request_phase
        options[:scope] ||= 'publish_feed'
        super
      end

      def raw_info
        @raw_info ||= MultiJson.decode(Net::HTTP.post_form(URI.parse('http://api.renren.com/restserver.do'), signed_params).body)[0]
        puts @raw_info.inspect
        @raw_info
      rescue ::Errno::ETIMEDOUT
        raise ::Timeout::Error
      end
    end
  end
end
