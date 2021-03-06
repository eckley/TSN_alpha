class MiscController < ApplicationController
  def advent
    params[:snow] ||= 'true'
    if params["day"]
      @current_day = params["day"].to_i
    else
      start_day = Time.parse('13th, December 2013')
      now = Time.now
      @current_day = ((now - start_day)/1.day).ceil
    end

    if params["last"]
      @last_day = params["last"].to_i
    elsif user_signed_in?
      @last_day = current_user.profile.advent_last_day
      @last_day ||= 0
      @last_day = [@last_day,@current_day].min
    else
      @last_day = 0
    end

    if params["update_last_day"]
      if user_signed_in?
        new_day = params["update_last_day"].to_i
        if new_day >= 0 && new_day <= @current_day
          if @current_day == 3
            t = Trophy.find 137
            t.award_to_profiles current_user.profile
          end
          current_user.profile.advent_last_day = new_day
          current_user.profile.save
          @last_day = new_day
        end
      else
        redirect_to new_user_session_path
        return
      end
    end

    render :advent, layout: false
  end

  def advent_subscribe
    if user_signed_in?
      if params[:add] == 'true'
        current_user.profile.advent_notify = true
        current_user.profile.save
        redirect_to advent_misc_path, notice: "Success, you are now subscribed to receive notices for theSkyNet Christmas countdown."
      else
        current_user.profile.advent_notify = false
        current_user.profile.save
        redirect_to advent_misc_path, notice: "Success, you are now unsubscribed from receiving notices for theSkyNet Christmas countdown."
      end
    else
      redirect_to root_url, notice: "Sorry you need to be logged in to do that."
    end
  end
  def site_map

  end

  def sf_demo_data
    params[:footnotes] = 'false'
    render :sf_demo_data, {layout: false, format: :json}
  end

  def sourcefinder_demo
    params[:footnotes] = 'false'
    render :sourcefinder_demo
  end

  def robots
    render :robots, {layout: false, format: :text}
  end
end