
require 'net/http'
require 'net/https'
require 'json'

CONFIG = { 'username' => '<your username>',
	   'password' => '<your password>',
	   'email_auth_code' => '<email authentication code (run without once to get this)>' }

class Steam
	BASE = "https://api.steampowered.com"
	VERSION = "v0001"
	OAUTH_CLIENT_ID = "DE45CD61"

	def initialize(hash)
		@username = hash['username']
		@password = hash['password']
		@email_auth_code = hash['email_auth_code']
	end

	def request(api, method, data, post=false)
		uri = URI.parse(BASE + "/" + api + "/" + method + "/" + VERSION)
		req = nil
		if (post) 
			req = Net::HTTP::Post.new(uri.request_uri);
			req.body = URI.encode_www_form(data)
		else
			uri.query = URI.encode_www_form(data)
			p data
			req = Net::HTTP::Get.new(uri.request_uri);
		end
		p uri.request_uri


		http = Net::HTTP.new(uri.hostname, uri.port)
		http.use_ssl = true;
		http.verify_mode = OpenSSL::SSL::VERIFY_NONE

		res = http.start() { |h|
			h.request(req);
		}
		p res.body
		return JSON.parse(res.body)
	end
	
	def request_auth(api, method, data={}, post=false)
		data = data.merge({:access_token => @access_token,
			    :steamid => @steam_id})
		request(api, method, data, post)
	end
	def request_umq(api, method, data={}, post=false)
		data = data.merge({:access_token => @access_token,
			    :umqid => 5})
		request(api, method, data, post)
	end


	def authenticate()
		
		login = request("ISteamOAuth2", "GetTokenWithCredentials",
                                {'client_id' => OAUTH_CLIENT_ID, 
				 'grant_type' => 'password', 
				 'username' => @username, 
				 'password' => @password, 
				 'x_emailauthcode' => @email_auth_code, 
				 'scope' => 'read_profile write_profile read_client write_client'}, true)
		@access_token = login['access_token']
		@webcookie = login['x_webcookie']
		@steam_id = login['x_steamid']
	end

	def friends
		return request_auth("ISteamUserOAuth", "GetFriendList")
	end
	def chat_logon
		return request_umq("ISteamWebUserPresenceOAuth", "Logon", {}, true)
	end
	def message(recipient, message)
		return request_umq("ISteamWebUserPresenceOAuth", "Message", {'type' => 'saytext',
									     'steamid_dst' => recipient,
									     'text' => message}, true)
	end
		
end

s = Steam.new(CONFIG)

p s.authenticate

p s.friends
p s.chat_logon	
s.message(<another steam user id to test>, "hello, im ruby")
