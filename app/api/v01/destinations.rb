class V01::Destinations < Grape::API
  helpers do
    # Never trust parameters from the scary internet, only allow the white list through.
    def destination_params
      p = ActionController::Parameters.new(params)
      p = p[:destination] if p.key?(:destination)
      p.permit(:ref, :name, :street, :detail, :postalcode, :city, :lat, :lng, :quantity, :take_over, :open, :close, :comment, tag_ids: [])
    end

    def destinations_import_params
      p = ActionController::Parameters.new(params)
      p.permit(:replace, :file)
    end
  end

  resource :destinations, desc: "Operations about destinations. On url parameter, id can be a ref field value, then use 'ref:[value]' as id." do
    desc "Return customer's destinations."
    get do
      present current_customer.destinations.load, with: V01::Entities::Destination
    end

    desc 'Return a destination.'
    get ':id' do
      id = read_id(params[:id])
      present current_customer.destinations.where(id).first, with: V01::Entities::Destination
    end

    desc 'Create a destination.', {
      params: V01::Entities::Destination.documentation.except(:id)
    }
    post do
      destination = current_customer.destinations.build(destination_params)
      destination.save!
      current_customer.save!
      present destination, with: V01::Entities::Destination
    end

    desc 'Create destinations by upload a CSV file or by JSON', {
      params: V01::Entities::DestinationsImport.documentation
    }
    params do
      optional :destinations, type: Array, desc: "JSON content in mutual exclusion with CSV file upload"
    end
    put '' do
      if params['destinations']
        destinations_import = DestinationsImport.new
        destinations_import.assign_attributes({replace: params[:replace]})
        Importer.import_hash(destinations_import.replace, current_customer, params[:destinations])
        status 204
      else
        destinations_import = DestinationsImport.new
        destinations_import.assign_attributes({replace: params[:replace], file: params[:file]})
        if destinations_import.valid?
          Importer.import_csv(destinations_import.replace, current_customer, destinations_import.tempfile, destinations_import.name, synchronous=true)
          status 204
        else
          error!({error: destinations_import.errors.full_messages}, 422)
        end
      end
    end

    desc 'Update a destination.', {
      params: V01::Entities::Destination.documentation.except(:id)
    }
    put ':id' do
      id = read_id(params[:id])
      destination = current_customer.destinations.where(id).first
      destination.assign_attributes(destination_params)
      destination.save!
      destination.customer.save! if destination.customer
      present destination, with: V01::Entities::Destination
    end

    desc 'Destroy a destination.'
    delete ':id' do
      id = read_id(params[:id])
      current_customer.destinations.where(id).first.destroy
    end

    desc 'Geocode a destination.', {
      params: V01::Entities::Destination.documentation.except(:id)
    }
    patch 'geocode' do
      destination = Destination.new(destination_params)
      destination.geocode
      present destination, with: V01::Entities::Destination
    end

    if Mapotempo::Application.config.geocode_complete
      desc 'Auto completion on destination.', {
        params: V01::Entities::Destination.documentation.except(:id)
      }
      patch 'geocode_complete' do
        p = destination_params
        address_list = Geocode.complete(current_customer.stores[0].lat, current_customer.stores[0].lng, 40000, p[:street], p[:postalcode], p[:city])
        address_list = address_list.collect{ |i| {street: i[0], postalcode: i[1], city: i[2]} }
        address_list
      end
    end
  end
end
