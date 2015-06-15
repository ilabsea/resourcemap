class RepeatsController < ApplicationController
  def index
    respond_to do |format|
      format.json { render json: Repeat.all, :root => false }
    end
  end
end
