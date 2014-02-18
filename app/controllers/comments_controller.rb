class CommentsController < ApplicationController
  authorize_resource
  def index
    @comments = Comment.for_show_index.page(params[:page]).per(20)
  end
  def new
    @comment = Comment.new(:parent_id => params[:parent_id],
                           :commentable_id => params[:commentable_id],
                           :commentable_type => params[:commentable_type]
                          )
    @comment.profile = current_user.profile
    respond_to do |format|
      format.html
      format.js
    end
  end
  def create
    @comment = Comment.new(params[:comment])
    @comment.profile = current_user.profile
    @comment.save
    respond_to do |format|
      format.html do
        if @comment.errors.present?
          render :new
        else
          redirect_to(@comment.commentable)
        end
      end
      format.js
    end
  end

  def edit
    @comment = Comment.find(params[:id])
    authorize! :update, @comment
    respond_to do |format|
      format.html
      format.js
    end
  end

  def destroy
    @comment = Comment.find(params[:id])
    authorize! :destroy, @comment
    @comment.destroy
    flash[:notice] = "Deleted comment."
    respond_to do |format|
      format.html { redirect_to @comment.commentable }
      format.js
    end
  end

  def update
    @comment = Comment.find(params[:id])
    authorize! :update, @comment
    @comment.update_attributes(params[:comment])
    respond_to do |format|
      format.html do
        if @comment.errors.present?
          render :edit
        else
          redirect_to @comment.commentable
        end
      end
      format.js
    end
  end

end