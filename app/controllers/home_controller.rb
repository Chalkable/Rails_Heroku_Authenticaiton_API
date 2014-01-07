class HomeController < ApplicationController
  def index

    @mode = params[:mode]
    @code = params[:code]
    @show_plus = @mode == 'edit'

    #res = get_access_token(APP_CONFIG, @code)
    res = get_access_token

    @acs_token = res[:res]

    @announcement_app_id = params[:announcementapplicationid].to_i

    user_res = get_current_user(@acs_token['access_token'])

    @current_user = user_res[:res]

    @current_user_id = @current_user['id'].to_i



  end



  private

    def get_current_user(access_token)
      begin
        resp = RestClient.get("https://chalkable.com/User/Me.json", :authorization => "Bearer:" + access_token)
        parsed = JSON.parse(resp)['data']
        parsed[:is_teacher] = parsed['rolename'] == 'Teacher'
        return :res => parsed, :error => false
      rescue => e
        return :res => e, :error => true, :stack_trace => e.backtrace
      end
    end


  def get_access_token    # Get the access token
    begin
      args = {
          'client_id' => APP_CONFIG['client_id'],
          'client_secret' => APP_CONFIG['client_secret'],
          'scope' => "https://chalkable.com",
          'redirect_uri' => APP_CONFIG['redirect_uri'],
          'grant_type' => 'authorization_code',
          'code' => params[:code]
      }
      oauth_response = RestClient.post(
          "https://chalkable-access-control.accesscontrol.windows.net/v2/OAuth2-13",
          args
      )
    rescue => e
      return [400, "Something terrible has happened!"]
    end
    parsed_response = JSON.parse(oauth_response)
    asdf
    access_token = parsed_response['access_token']
    me = get_current_user(access_token)[:res]
    me['displayname'].to_s
    puts me.inspect
  end


end
