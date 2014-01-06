class HomeController < ApplicationController
  def index

    @mode = params[:mode]
    @code = params[:code]
    @show_plus = @mode == 'edit'

    res = get_access_token(APP_CONFIG, @code)

    @acs_token = res[:res]

    @announcement_app_id = params[:announcementapplicationid].to_i

    user_res = get_current_user(@acs_token['access_token'])

    @current_user = user_res[:res]

    @current_user_id = @current_user['id'].to_i



  end



  private
  def get_access_token(settings, code)
    unless session[:acs_token].nil?
      if session[:acs_token][:code] == code
        return :res => JSON.parse(session[:acs_token][:token]), :error => false
      end
    end

    begin
      @response = RestClient.post(
          settings['acs_url'],
          'client_id' => settings['client_id'],
          'client_secret' => settings['client_secret'],
          'scope' => settings['scope'],
          'redirect_uri' => settings['redirect_uri'],
          'grant_type' => 'authorization_code',
          'code' => code
      )
    rescue => e
      return :res => e, :error => true, :stack_trace => e.backtrace
    end
    session[:acs_token] = {:token => @response, :code => code}
    return :res => JSON.parse(@response), :error => false
    #return :res => "", :error => false
  end

  def get_current_user(access_token)
    begin
      @response = RestClient.get(APP_CONFIG['service_url'], :authorization => "Bearer:" + access_token)
      res = JSON.parse(@response)['data']
      res[:is_teacher] = res['rolename'] == 'Teacher'
      return :res => res, :error => false
    rescue => e
      return :res => e, :error => true, :stack_trace => e.backtrace
    end
    #return :res => {:id => 123, :rolename => 'Teacher', :is_teacher => true ,:displayname => "Ms. Rachel Harari"}, :error => false
  end


end
