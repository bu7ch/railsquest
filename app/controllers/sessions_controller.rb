class SessionsController < ApplicationController
  def create
    auth = request.env["omniauth.auth"]
    user = User.find_or_create_from_omniauth(auth)
    session[:user_id] = user.id
    redirect_to root_path, notice: "Connecté."
  end

  def destroy
    session[:user_id] = nil
    redirect_to root_path, notice: "Déconnecté."
  end

  def failure
    redirect_to root_path, alert: "Échec de la connexion GitHub."
  end
end
