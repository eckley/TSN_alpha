class TheSkyMap::MessagesController < TheSkyMap::ApplicationController

  respond_to :json

  def index
    page = params[:page].to_i || 1
    per_page = params[:per_page].to_i || 10
    @messages = current_user.profile.the_sky_map_player.messages.page(page).per(per_page).for_show
    render :json =>  @messages, :each_serializer => TheSkyMap::MessageIndexSerializer, meta: pagination_meta(@messages)
  end

  def update
    player = current_user.profile.the_sky_map_player
    @message = player.messages.find(params[:id])
    @message.update_attributes(params[:message].slice(:ack))
    PostToFaye.ack_msg(player.id,@message.id,player.unread_msg_count)
    render json:  @message, serializer: TheSkyMap::MessageIndexSerializer, root: 'message'
  end

  def show
    @message = current_user.profile.the_sky_map_player.messages.find(params[:id])
    render json:  @message, serializer: TheSkyMap::MessageIndexSerializer, root: 'message'
  end
end