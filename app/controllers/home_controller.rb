class HomeController < ApplicationController

  after_action :allow_iframe

  def index

    # get url params from chalkable iframe
    @mode = params[:mode]
    @code = params[:code]

    get_access_token(@code)

    # get the current application mode:
    # 'edit' = teacher creating / preparing application in a New Item
    # 'view' = student viewing the application in a New Item (where they will do the work)
    # 'myview' = viewing the application in My Apps
    # 'gradingview' = teacher viewing student output

    # initialize the Javascript callback in our application view to activate the "Attach" button
    @show_plus = @mode == 'edit'

    # get the unique id of this assignment with the app attached (should be used to save / read appropriate data)
    @announcement_application_id = params[:announcementapplicationid].to_i

    # get the student id of the current student's assignment (if viewing it as a teacher in the 'view' mode)
    @student_id = params[:studentid]

    if params.has_key?(:studentid)
      get_student_info(@student_id, @access_token)
    end

  end

  def get_student_info(id, token)

    begin
      student_info_url = 'https://chalkable.com/Student/Info.json'
      student_response = HTTParty.get(student_info_url,
                                      :query => { :id => id  },
                                      :headers => { "Authorization" => "Bearer:" + token})

      @student = JSON.parse(student_response.to_json)['data']
     # @user = res['displayname'].to_s



      return @student, :error => false
    rescue => e
      return :res => e, :error => true, :stack_trace => e.backtrace
    end
  end

  private

  def allow_iframe
    response.headers.except! 'X-Frame-Options'
  end

  # Get the access token
  def get_access_token(oauth_code_from_chalkable)

    unless session[:acs_token].nil?
      if session[:acs_token][:code] == oauth_code_from_chalkable
        return :res => JSON.parse(session[:acs_token][:token]), :error => false
      end
    end

    begin
      options =   { :body => {
          :code => oauth_code_from_chalkable,
          :client_id => 'http://localhost:3000/',
          :client_secret => '944e320f8a494538b8988f2b305e35c4fc8ed02028694407943a5bf25539798c6d253361ee99465aa81b42d0a002ab5e01f1c27e90c8499aaf6ea89c1b7c4fb1',
          :scope => 'https://chalkable.com',
          :redirect_uri => 'http://localhost:3000/',
          :grant_type => 'authorization_code'
      }}
      oauth_response = HTTParty.post(
          'https://chalkable-access-control.accesscontrol.windows.net/v2/OAuth2-13',
          options
      )
    rescue => e
      return [400, "Oh no, something terrible has happened!"]
    end

    parsed_response = JSON.parse(oauth_response.to_json)
    @access_token = parsed_response["access_token"]

    session[:acs_token] = {:token => @access_token, :code => @code}
    get_current_user(@access_token)

  end

  def get_current_user(access_token)
    begin
      @response = RestClient.get(APP_CONFIG['service_url'], :authorization => "Bearer:" + access_token)
      @user = JSON.parse(@response)['data']
      res[:is_teacher] = res['rolename'] == 'Teacher'
      #@user = res['displayname'].to_s
      return :res => res, :error => false
    rescue => e
      return :res => e, :error => true, :stack_trace => e.backtrace
    end
  end

end
