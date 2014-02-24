class News < ActiveRecord::Base

  attr_accessible :long, :short, :title, :published, :published_time, :image, :notify, :use_disqus, as: :admin
  has_attached_file :image, :styles => { :medium => "300x300>", :thumb => "75x75>"}

  has_many :comments, as: :commentable
  attr_readonly :comments_count

  def publish
      self.published = true
      self.published_time = Time.now
      self.save
  end
  def self.published
    where{(published == true) & (published_time <= Time.now)}
  end
  rails_admin do

    field :title
    field :short
    field :notify
    field :use_disqus
    field :published
    field :published_time
    field :image
    field :long, :text do
      ckeditor true
    end
  end

  def self.announcement(time)
      time ||= Time.at(0)
      where{(notify ==true) & (published == true) & (published_time > my{time})}.order{published_time.asc}.first
  end
end
