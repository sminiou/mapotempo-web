class Admin::UsersController < ApplicationController
  load_and_authorize_resource :except => :create
  before_action :set_user, only: [:show, :edit, :update, :destroy]

  # GET /users
  # GET /users.json
  def index
    @users = User.where("admin IS NULL")
  end

  # GET /users/1
  # GET /users/1.json
  def show
  end

  # GET /users/new
  def new
    @user = User.new
    @customers = Customer.all
  end

  # GET /users/1/edit
  def edit
    @customers = Customer.all
  end

  # POST /users
  # POST /users.json
  def create
    @user = User.new(user_params)

    respond_to do |format|
      if @user.save
        format.html { redirect_to edit_customer_path(@user.customer), notice: t('activerecord.successful.messages.created', model: @user.class.model_name.human) }
        format.json { render action: 'show', status: :created, location: @user }
      else
        @customers = Customer.all
        format.html { render action: 'new' }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /users/1
  # PATCH/PUT /users/1.json
  def update
    respond_to do |format|
      if @user.update(user_params)
        format.html { redirect_to edit_customer_path(@user.customer), notice: t('activerecord.successful.messages.updated', model: @user.class.model_name.human) }
        format.json { head :no_content }
      else
        @customers = Customer.all
        format.html { render action: 'edit' }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /users/1
  # DELETE /users/1.json
  def destroy
    if !@user.admin
      @user.destroy
      respond_to do |format|
        format.html { redirect_to admin_users_path }
        format.json { head :no_content }
      end
    else
      respond_to do |format|
        format.html { redirect_to action: 'edit', status: :unprocessable_entity }
        format.json { render json: {}, status: :unprocessable_entity }
      end
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_user
      @user = User.find(params[:id] || params[:user_id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def user_params
      params.require(:user).permit(:email, :customer_id, :layer_id, :password, :password_confirmation)
    end
end