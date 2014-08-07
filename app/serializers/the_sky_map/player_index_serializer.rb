class TheSkyMap::PlayerIndexSerializer < ActiveModel::Serializer
  attributes :id, :name, :rank, :total_score, :profile_id
  def name
    object.profile.name
  end
end