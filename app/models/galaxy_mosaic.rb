class GalaxyMosaic < ActiveRecord::Base
  require 'RMagick'
  include ActionView::Helpers::UrlHelper
  attr_accessible :display, :galaxy_hash, :options
  serialize :galaxy_hash, Hash
  serialize :options, Hash
  has_attached_file :image, :styles => {:thumb => "300" }
  validates_attachment_content_type :image, :content_type => /\Aimage\/.*\Z/
  scope :for_show, where{display == true}
  def self.new_with_defaults
    gm = self.new
    gm.options[:cols] = 5
    gm.options[:rows] = 3
    gm
  end
  def generate_hash
    galaxies = Galaxy.completed.last(self.options[:cols] * self.options[:rows])
    g_hash = {}
    galaxies.each do |galaxy|
      g_hash[galaxy.galaxy_id] = Galaxy.parameter_image_options.sample
    end
    self.galaxy_hash = g_hash
    return g_hash
  end
  def galaxy_ids
    self.galaxy_hash.keys
  end
  def galaxies
    Galaxy.where{galaxy_id.in my{self.galaxy_ids}}
  end
  def user_ids
    ids = GalaxyUser.where{galaxy_id.in my{self.galaxy_ids}}.pluck(:userid)
    ids.uniq
  end
  def profiles
    boinc_ids = self.user_ids
    return Profile.joins{general_stats_item.boinc_stats_item}.where{boinc_stats_items.boinc_id.in boinc_ids}
  end
  def profiles_for_show
    profiles.select_name
  end
  def url
    Rails.application.routes.url_helpers.galaxy_mosaic_url(self, host: APP_CONFIG['site_host'])
  end
  def set_info
    ids = self.user_ids
    number_of_users = ids.count
    self.options[:number_of_users] = number_of_users
    info_lines = []
    self.save if self.new_record?
    info_lines << "The data in this image was generated by the work of computers donated by "
    info_lines << "#{number_of_users} amazing users from theSkyNet POGS!"
    info_lines << "For more information head to www.theSkyNet.org/galaxy_mosaics/#{self.id}"
    info_text = info_lines.join("\n")
    self.options[:info_text] = info_text
  end
  def notify_users
    profiles = self.profiles
    link_to_mosaic = link_to("Galaxy Mosaic, #{self.id}", Rails.application.routes.url_helpers.galaxy_mosaic_path(self))

    #add a time line entry for the user
    TimelineEntry.post_to profiles, {
        more: '',
        more_aggregate: '',
        subject: "was part of #{link_to_mosaic}",
        subject_aggregate: "was part of many #{self.class.to_s.pluralize}",
        aggregate_type: "galaxy_mosaic",
        aggregate_type_2: self.id,
        aggregate_text: "%profile_name% was part of a new #{link_to_mosaic} <br />",
    }

    #send notifications to users
    subject = "You have contributed to a new Galaxy Mosaic"
    body = "Thank You! <br /> Your computers have contributed to the galaxies featured in #{link_to_mosaic}. <br /> Cheers and happy computing! <br /> theSkyNet"
    profile_ids = profiles.map(&:id)
    ProfileNotification.notify_all_id_array(profile_ids,subject,body,self,false)
  end
  def build_image
    if self.image.exists?
      self.image = nil
      self.save
    end
    self.set_info if self.options[:info_text_line_1].nil?
    self.generate_hash if self.galaxy_hash == {}

    new_image = self.generate_mosaic_image
    tmp_img_file = Tempfile.new(['tmp_mosaic_image', '.png'])

    new_image.write(tmp_img_file.path)
    self.image = tmp_img_file

    self.save

    tmp_img_file.close
    tmp_img_file.unlink
    new_image.destroy!
  end
  def qr_image(size=10,level = :h)
    qr_svg = RQRCode.render_qrcode( self.url, :svg, {:size => size, :level => level})
    img = Magick::Image::from_blob(qr_svg)
    img.first
  end
  def generate_galaxy_image(gal_x,gal_y,gal_font_size, galaxy, param)
    galaxy_image_url = galaxy.parameter_image_url(param)
    urlimage = open(galaxy_image_url)
    galaxy_image = Magick::ImageList.new.from_blob(urlimage.read)

    #scale and crop to dim
    galaxy_image.resize_to_fit!(gal_x)

    #add text to image
    text = "#{galaxy.name[0..15]} (#{param})"
    draw = Magick::Draw.new
    draw.fill = 'White'
    draw.font_family = 'helvetica'
    draw.pointsize = gal_font_size.to_i
    draw.gravity = Magick::SouthGravity
    draw.annotate(galaxy_image, 0,0,0,10, text) {
      self.stroke = 'black'
      self.stroke_width = 3
    }
    draw.annotate(galaxy_image, 0,0,0,10, text) {
      self.stroke = 'none'
    }
    return galaxy_image
  end
  def generate_mosaic_image(dim = 1500)
    #set dimensions
    cols = self.options[:cols]
    rows = self.options[:rows]
    dim_x = dim_y = dim
    gal_x = gal_y = dim/cols
    logo_x = dim
    logo_y = dim/5
    logo_x_pos = 0
    logo_y_pos = gal_y * rows
    info_x = (dim * 5/6).to_i
    info_y = dim / 6
    info_x_pos = 0
    info_y_pos = logo_y_pos + logo_y - 1
    qr_out_x = dim - info_x
    qr_out_y = info_y
    qr_padding_x = qr_out_x * 0.1
    qr_padding_y = qr_padding_x
    qr_in_white_x = qr_out_x - (qr_padding_x)
    qr_in_white_y = qr_out_y - (qr_padding_y)
    qr_in_x = qr_out_x - (qr_padding_x * 2)
    qr_in_y = qr_out_y - (qr_padding_y * 2)
    qr_out_pos_x = info_x
    qr_out_pos_y = info_y_pos
    qr_in_white_pos_x = qr_out_pos_x
    qr_in_white_pos_y = qr_out_pos_y
    qr_in_pos_x = qr_out_pos_x + qr_padding_x/2
    qr_in_pos_y = qr_out_pos_y + qr_padding_y/2

    #set font_sizes
    base_font_size = dim/1500
    gal_font_size = 25 * base_font_size
    info_font_size = 33 * base_font_size
    info_font_spacing  = info_font_size / 3

    #new image
    image_list = Magick::ImageList.new
    page = Magick::Rectangle.new(0,0,0,0)

    #insert galaxy images
    count = 0
    self.galaxies.each do |galaxy|
      #load parameter image for galaxy
      puts "loading image #{count} #{galaxy.name}:"
      galaxy_image = generate_galaxy_image(gal_x,gal_y,gal_font_size, galaxy, self.galaxy_hash[galaxy.galaxy_id])

      #add to list
      image_list << galaxy_image.cur_image
      #update position information
      x_cor = (count % cols).to_i * gal_x
      y_cor = (count / cols).to_i * gal_y
      page.x = x_cor
      page.y = y_cor
      image_list.page = page
      count = count + 1
    end

    #add logo
    logo_file_name = Rails.root.join('app','assets','images','logo_for_mosaic.png')
    logo_image = Magick::ImageList.new(logo_file_name)
    image_list << logo_image.resize_to_fit(logo_x,logo_y)
    page.x = logo_x_pos
    page.y = logo_y_pos
    image_list.page = page

    #add info text
    info_text_image = Magick::Image.new(info_x,info_y) { self.background_color = "black" }
    self.draw_font_with_outline(info_text_image,self.options[:info_text],{pointsize: info_font_size, gravity: (Magick::CenterGravity), interline_spacing: info_font_spacing})

    image_list << info_text_image
    page.x = info_x_pos
    page.y = info_y_pos
    image_list.page = page

    #add bg for qr code
    qr_bq_image = Magick::Image.new(qr_out_x,qr_out_y) { self.background_color = "black" }
    image_list << qr_bq_image
    page.x = qr_out_pos_x
    page.y = qr_out_pos_y
    image_list.page = page
    qr_bq_image = Magick::Image.new(qr_in_white_x,qr_in_white_y) { self.background_color = "white" }
    image_list << qr_bq_image
    page.x = qr_in_white_pos_x
    page.y = qr_in_white_pos_y
    image_list.page = page

    #add qr code
    qr_code = self.qr_image(5)
    qr_code.resize_to_fit!(qr_in_x)
    image_list << qr_code
    page.x = qr_in_pos_x
    page.y = qr_in_pos_y
    image_list.page = page

    #generate_mosaic
    image_list.background_color = 'black'
    mosaic = image_list.mosaic

    #add gridlines
    draw = Magick::Draw.new
    draw.stroke('grey')
    draw.stroke_width(1)
    draw.fill_opacity(0)
    #add cols
    (0..(cols-1)).each do |col|
      draw.line(col*gal_x,0,col*gal_x,rows*gal_y)
    end
    final_pos = (cols*gal_x) - 1
    draw.line(final_pos,0,final_pos,rows*gal_y)
    #add rows
    (0..(rows)).each do |row|
      draw.line(0,row*gal_y,cols*gal_x,row*gal_y)
    end
    draw.draw(mosaic)
    mosaic.format = 'png'
    #and done
    return mosaic
  end
  def draw_font_with_outline(image,text,opts = {})
    draw = Magick::Draw.new
    draw_text = "#{text}"
    draw.fill = 'White'
    draw.font_family = 'helvetica'
    draw.pointsize= 25

    draw.gravity = Magick::SouthGravity
    opts.slice(:fill,:font_family,:pointsize,:gravity).each do |k,v|
      draw.send("#{k}=",v)
    end
    offset = opts[:offset] || 10
    space = opts[:interline_spacing] || 10

    draw.stroke = 'black'
    draw.stroke_width = 3
    draw.interline_spacing(space.to_i)
    draw.text(0,0, draw_text)
    draw.stroke = 'none'
    draw.text(0,0, draw_text)
    draw.draw(image)
  end

end
