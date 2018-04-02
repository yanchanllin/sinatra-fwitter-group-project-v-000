require './config/environment'
require 'sinatra/base'
require 'rack-flash'
require 'pry'

class ApplicationController < Sinatra::Base
  enable :sessions
  use Rack::Flash
  configure do
    set :session_secret, "secret"
    set :public_folder, 'public'
    set :views, 'app/views'
  end

  get '/' do
    erb :index
  end

  get '/signup' do
    if is_logged_in?
      redirect to '/tweets'
    end

    erb :"/users/create_user"
  end

  post '/signup' do
    params.each do |label, input|
      if input.empty?
        flash[:new_user_error] = "Please enter a value for #{label}"
        redirect to '/signup'
      end
    end

    user = User.create(:username => params["username"], :email => params["email"], :password => params["password"])
    session[:user_id] = user.id

    redirect to '/tweets'
  end

  get '/login' do
    if is_logged_in?
      redirect to '/tweets'
    end

    erb :"/users/login"
  end

  post '/login' do
    user = User.find_by(:username => params["username"])

    if user && user.authenticate(params[:password])
      # binding.pry
      session[:user_id] = user.id
      redirect '/tweets'
    else
      # binding.pry
      flash[:login_error] = "Incorrect login. Please try again."
      redirect to '/login'
    end
  end

  get '/tweets' do
    if !is_logged_in?
      redirect to '/login'
    end
    @tweets = Tweet.all
    @user = current_user
    # binding.pry
    erb :'tweets/tweets'
  end

  get '/tweets/new' do
    if !is_logged_in?
      redirect to '/login'
    end
    erb :"/tweets/create_tweet"
  end

  post '/tweets' do
    user = current_user
    if params["content"].empty?
      flash[:empty_tweet] = "Please enter content for your tweet"
      redirect to '/tweets/new'
    end
    tweet = Tweet.create(:content => params["content"], :user_id => user.id)

    redirect to '/tweets'
  end

  get '/tweets/:id' do
    if !is_logged_in?
      redirect to '/login'
    end
    @tweet = Tweet.find(params[:id])
    erb :"tweets/show_tweet"
  end

  get '/tweets/:id/edit' do
    if !is_logged_in?
      redirect to '/login'
    end
    @tweet = Tweet.find(params[:id])
    if current_user.id != @tweet.user_id
      flash[:wrong_user_edit] = "Sorry you can only edit your own tweets"
      redirect to '/tweets'
    end
    erb :"tweets/edit_tweet"
  end

  patch '/tweets/:id' do
    tweet = Tweet.find(params[:id])
    if params["content"].empty?
      flash[:empty_tweet] = "Please enter content for your tweet"
      redirect to "/tweets/#{params[:id]}/edit"
    end
    tweet.update(:content => params["content"])
    tweet.save

    redirect to "/tweets/#{tweet.id}"
  end

  post '/tweets/:id/delete' do
    if !is_logged_in?
      redirect to '/login'
    end
    @tweet = Tweet.find(params[:id])
    if current_user.id != @tweet.user_id
      flash[:wrong_user] = "Sorry you can only delete your own tweets"
      redirect to '/tweets'
    end
    @tweet.delete
    redirect to '/tweets'
  end

  get '/users/:slug' do
    slug = params[:slug]
    @user = User.find_by_slug(slug)
    erb :"users/show"
  end

  get '/logout' do
    if is_logged_in?
      session.clear
      redirect to '/login'
    else
      redirect to '/'
    end
  end

  helpers do
     def is_logged_in?
       !!current_user
     end
     def current_user
       @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
     end
  end

end
