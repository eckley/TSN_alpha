class Sub::GridsController < Sub::ApplicationController

  respond_to :json

  def index

    x_min = params[:x_min] || 0
    x_max = params[:x_max] || 2
    y_min = params[:y_min] || 0
    y_max = params[:y_max] || 2
    z_min = params[:z_min] || 0
    z_max = params[:z_max] || 2

    grids = Sub::Grid.
        where{(z >= z_min) & (z <= z_max)}.
        where{(y >= y_min) & (y <= y_max)}.
        where{(x >= x_min) & (x <= x_max)}.
        order([:z,:y,:x])


    respond_with grids

  end

end
