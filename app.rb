require 'json'
require 'sinatra'
require 'sinatra/reloader'
require 'sinatra/namespace'
require_relative 'route_methods/biggestbass'
require_relative 'route_methods/user'
require_relative 'route_methods/html'
require_relative 'route_methods/log'
# require rack
# require_relative 'secrets'

# set port and binding
set :bind, '0.0.0.0'
set :port, 8080
set :sessions, :expire_after => 1800

# presets - load classes
before do
  @html = HTML.new
  @bb = BiggestBass.new
  @log = Log.new
end

# Endpoints
get '/biggestbass' do
  redirect '/biggestbass/members' if session[:userid]
  @user_session_status = @html.login_button if session[:userid].nil?
  @title = "Biggest Bass Leaderboard"
  @bb_table = @bb.sort_by_weight
  erb :biggestbass
end

get '/biggestbass/members' do
  redirect '/biggestbass' if session[:userid].nil?
  if session[:userid]
    @user_session_status = @html.logout_button(session[:userid])
    @submit_weight = @html.submit_weight_button(session[:userid])
  end
  @title = "Biggest Bass Leaderboard"
  @bb_table = @bb.sort_by_weight
  @bb_history = @bb.history_table
  erb :biggestbass_members
end

post '/biggestbass/sessions' do
  @user = User.new(params['username'], params['password'])
  if @user.authorized?
    session[:userid] = @user.name
    @log.log_action(session[:userid], 'Logged in successfully')
    redirect '/biggestbass/members'
  else
    @log.log_action(params['username'], 'Login failed')
    redirect '/unauthorized'
  end
end

post '/biggestbass/submit' do
  redirect '/unauthorized' if session[:userid].nil?
  if params['upgrade_weight'].to_s.empty?
    @log.log_action(session[:userid], 'Attempted to submit an upgrade with an empty field')
    redirect '/biggestbass/submission_failed'
  elsif params['upgrade_weight'].match(/[A-Za-z]/)
    @log.log_action(session[:userid], 'Attempted to submit an upgrade with letter characters in the field')
    redirect '/biggestbass/submission_failed'
  elsif !@bb.entry_fee_paid?(session[:userid], '$120')
    @log.log_action(session[:userid], 'Attempted to submit a weight upgrade but failed due to entry fee not paid')
    redirect '/biggestbass/submission_failed'
  elsif params['upgrade_weight'].to_s.match(/\d{1,2}\-\d{1,2}/)
    upgrade_weight = params['upgrade_weight']
    @log.log_action(session[:userid], "Submitted an upgrade for #{params['fish_type']} @ #{params['upgrade_weight']}")
  elsif params['upgrade_weight'].to_s.match(/\d{1,2}\.\d{1,2}/)
    upgrade_weight = @bb.convert_decimal_to_lbs_oz(params['upgrade_weight'])
    @log.log_action(session[:userid], "Submitted an upgrade for #{params['fish_type']} @ #{upgrade_weight}")
  end
  @bb.update_bass_weight(@log.get_datetime, session[:userid], params['fish_type'], upgrade_weight)
  redirect '/biggestbass/members'
end

get '/biggestbass/submission_failed' do
  redirect '/unauthorized' if session[:userid].nil?
  @message = @html.weight_upgrade_submission_failed
  erb :biggestbass_submission_failed
end

get '/change_password_ui' do
  redirect '/unauthorized' if session[:userid].nil?
  @log.log_action(session[:userid], 'Is attempting to change his/her password')
  erb :change_password_ui
end

post '/change_password' do
  redirect '/unauthorized' if session[:userid].nil?
  @user = User.new(session[:userid], params['old_password'])
  if !params['old_password'].match(/\w/) || !@user.authorized?
    @error_msg = @html.old_password_incorrect
    @log.log_action(session[:userid], "Tried changing password but received: Error => Old password does NOT match")
    erb :change_password_ui
  elsif !params['new_password'].match(/\w/) || !params['new_password2'].match(/\w/) || params['new_password'] != params['new_password2']
    @error_msg = @html.new_passwords_not_match
    @log.log_action(session[:userid], "Tried changing password but received: Error => New passwords do NOT match and/or field(s) are empty")
    erb :change_password_ui
  elsif params['new_password'] == params['old_password']
    @error_msg = @html.new_password_match_old
    @log.log_action(session[:userid], "Tried changing password but received: Error => New password matches old password")
    erb :change_password_ui
  else
    @user.change_password(params['new_password'])
    @log.log_action(session[:userid], 'Changed password successfully')
    session[:userid] = nil
    erb :password_change_successful
  end
end

get '/unauthorized' do
  @message = 'Invalid username / password'
  erb :unauthorized
end

get '/logout' do
  @log.log_action(session[:userid], 'Logged out successfully')
  session[:userid] = nil
  redirect '/biggestbass'
end
