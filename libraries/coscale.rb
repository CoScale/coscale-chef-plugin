#!/usr/bin/ruby
require 'net/http'
require 'net/https'
require 'uri'
require 'json'


# The module is used for creating and sending 
# events to CoScale API during client updates.

class Chef
  module Coscale

    # Authentication using the Access token to get a 
    # HTTPAuthentication token from the CoScale API.
    #
    # @param accesstoken [string] The accessToken is used to login to the API
    # @param url [string] The url we need to access in order to get the token
    # @return [string] The HttpAuthentication token
    def self._login(accesstoken, url)
      data = {'accessToken' => accesstoken}
      uri = URI(url)
      res = Net::HTTP.post_form(uri, data)
      if res.code != '200'
        raise ArgumentError, res.body
      end
      response = JSON.parse(res.body)
      return response['token']
    end

    # Create an event using the event name.
    #
    # @param name [string] The event name
    # @param token [string] The HTTPAuthentication token used for authentication
    # @param url [string] We create a POST request to this url to create an event
    # @return [string] Request if there was an error or the event id if the request succeed
    def self._eventpush(name, token, url)
      data = {'name'        => name,
              'description' => '',
              'type'        => '',
              'source'      => 'Chef'}
      headers = {'HTTPAuthorization' => token}

      uri = URI.parse(url)
      http = Net::HTTP.new(uri.host, uri.port)
      if url.start_with?('https')
        http.use_ssl = true
      end
      
      request = Net::HTTP::Post.new(uri.request_uri, initheader = headers)
      request.set_form_data(data)
      res = http.request(request)
      
      # if the response has status code 409(duplicate event)
      # the CoScale API sends the id of the event in the response;
      # the id can be taken from the response and used to send event data
      if res.code == '409' || res.code == '200'
        response = JSON.parse(res.body)
        return nil, response["id"]
      end
        return res, nil
    end

    # Push event data using message and timestamp.
    #
    # @param message [string] The actual message
    # @param timestamp [Fixnum] Unix timestamp in seconds
    # @param token [string] HTTPAuthentication token used for authentication
    # @param url [string] We create a POST request to this url to push event message
    # @return [string] Request response if the request failed or nil if succeed
    def self._eventdatapush(message, timestamp, token, url)
      data = {'message' => message,
              'timestamp' => timestamp,
              'subject' => 'subject',
              }
      headers = {'HTTPAuthorization' => token}

      uri = URI.parse(url)
      http = Net::HTTP.new(uri.host, uri.port)
      if url.start_with?('https')
        http.use_ssl = true
      end

      request = Net::HTTP::Post.new(uri.request_uri, initheader = headers)
      request.set_form_data(data)
      res = http.request(request)
      return res
    end

    # Deals with login, event creation and event data pushing.
    #
    # @param baseurl [string] The url used to create login url, post event url and post data url
    # @param accesstoken [string] The accessToken is used to login to the API
    # @param appid [stirng] The appid (uuid) used for API connection
    # @param event_name [string] The name of the event, this will appear in the CoScale interface
    # @param event_message [string] The message of the event, this will appear in the CoScale interface
    # @param event_timestamp [string] Unix timestamp in seconds
    # @return [Hash] Response with details about the event creation
    def self.event(baseurl, accesstoken, appid, event_name, event_message, timestamp=0)
      reply = {'name' 	 => event_name,
               'changes' => {},
               'result'  => false,
               'comment' => ''}

      baseurl = baseurl + 'api/v1/app/' + appid + '/'
      begin
        token = _login(accesstoken, baseurl + 'login/')
        err, event_id = _eventpush(event_name, token, url=baseurl + 'events/')
        if err != nil
          if err.code == '401'
            token = _login(accesstoken, baseurl + 'login/')
            err, event_id = _eventpush(name=event_name, token=token, url=baseurl + 'events/')
          end
          if !['401', nil].include? err.code
            reply['comment'] = err.body
            return reply
          end
        end
        url = baseurl + 'events/' + event_id.to_s + '/data/'
        err = _eventdatapush(event_message, timestamp, token, url=url)
        if err != nil
          if err.code == '401'
            token = _login(accesstoken, baseurl + 'login/')
            err = _eventdatapush(event_message, timestamp, token, url=url)
          end 
          if err.code != '200'
            reply['comment'] = err.body
            return reply
          end
        end
        reply['result'] = true
        reply['comment'] = 'Sent event: ' + event_name
        return reply
      rescue ArgumentError => err
        reply['comment'] = err
      rescue SocketError => err
        reply['comment'] = err
      end
      return reply
    end
  end
end
