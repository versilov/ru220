# encoding: utf-8

class SessionsController < ApplicationController
  skip_before_filter :authorize
  
  def new
  end

  def create
    if user = User.authenticate(params[:login], params[:password])
      session[:user_id] = user.id
      redirect_to admin_url
    else
      redirect_to login_url, :alert => 'Неверный логин/пароль'
    end
  end

  def destroy
    session[:user_id] = nil
    redirect_to new_order_url, :notice => 'Пользователь вышел'
  end

end
