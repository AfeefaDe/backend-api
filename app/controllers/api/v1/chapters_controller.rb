require 'http'

class Api::V1::ChaptersController < ApplicationController

  include DeviseTokenAuth::Concerns::SetUserByToken
  include NoCaching
  include ChaptersApi

  respond_to :json

  # before_action :authenticate_api_v1_user!

  rescue_from ActiveRecord::RecordNotFound do
    head :not_found
  end

  rescue_from ActiveRecord::RecordInvalid do
    head :unprocessable_entity
  end

  def initialize
    super
  end

  def index
    response = HTTP.get(base_path)
    render status: response.status, json: response.body.to_s
  end

  def show
    response = HTTP.get("#{base_path}/#{params[:id]}")
    render status: response.status, json: response.body.to_s
  end

  def create
    response =
      HTTP.post(base_path,
        headers: { 'Content-Type' => 'application/json' },
        body: params.permit!.to_json)
    if 201 == response.status
      chapter = JSON.parse(response.body.to_s)
      config =
        ChapterConfig.new(
          chapter_id: chapter['id'],
          creator_id: current_api_v1_user.id,
          last_modifier_id: current_api_v1_user.id,
          active: true)
      if config.save
        area_config = AreaChapterConfig.new(area: current_api_v1_user.area, chapter_config_id: config.id)
        if area_config.save
          render status: response.status, json: chapter
          return
        end
      end
    end
    # TODO: Handle errors!
    render status: :unprocessable_entity
  end

  def update
    response =
      HTTP.patch("#{base_path}/#{params[:id]}",
        headers: { 'Content-Type' => 'application/json' },
        body: params.permit!.to_json)
    if 200 == response.status
      config = ChapterConfig.find_by(chapter_id: params[:id])
      # TODO: Should we update the area on chapter update?
      if config.update(last_modifier_id: current_api_v1_user.id)
        render status: response.status, json: response.body.to_s
        return
      end
    end
    # TODO: Handle errors!
    render status: :unprocessable_entity
  end

  def destroy
    response = HTTP.delete("#{base_path}/#{params[:id]}")
    render status: response.status, json: response.body.to_s
  end

end
