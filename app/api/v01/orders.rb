class V01::Orders < Grape::API
  helpers do
    # Never trust parameters from the scary internet, only allow the white list through.
    def order_params
      p = ActionController::Parameters.new(params)
      p = p[:order] if p.key?(:order)
      p.permit(product_ids: [])
    end

    def authorize!
      ability = Ability.new(@current_user)
      error!('401 Unauthorized', 401) unless ability.can?(:manage, OrderArray)
    end
  end

  resource :order_arrays do
    segment '/:order_array_id' do

      resource :orders do
        desc "Return order_array's orders."
        get do
          present current_customer.order_arrays.find(params[:order_array_id]).orders.load, with: V01::Entities::Order
        end

        desc 'Return a order.'
        get ':id' do
          present current_customer.order_arrays.find(params[:order_array_id]).orders.find(params[:id]), with: V01::Entities::Order
        end

        desc 'Update a order.', {
          params: V01::Entities::Order.documentation.except(:id)
        }
        put ':id' do
          order = current_customer.order_arrays.find(params[:order_array_id]).orders.find(params[:id])
          p = order_params
          p[:product_ids] = p[:product_ids] || [] # Empty :product_ids if no parameter set, workaround, no way to send empty array through HTTP PUT
          order.update(p)
          order.save!
          present order, with: V01::Entities::Order
        end
      end
    end
  end
end
