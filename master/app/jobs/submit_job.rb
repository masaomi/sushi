class SubmitJob < ApplicationJob
  queue_as :default

  def perform(params)
    class_name = params[:class_name]
    require class_name
    sushi_app = eval(class_name).new
    sushi_app.logger = logger
    sushi_app.sushi_server = eval(SushiFabric::Application.config.sushi_server_class).new
    sushi_app.user = params[:user]
    sushi_app.next_dataset_name = params[:next_dataset_name]
    sushi_app.next_dataset_comment = params[:next_dataset_comment]
    sushi_app.params['sushi_app'] = class_name
    params[:parameters].each do |key, value|
      sushi_app.params[key] = if sushi_app.params.data_type(key) == String
                                       value
                                     else
                                       eval(value)
                                     end
    end
    sushi_app.project = params[:project]
    sushi_app.dataset_sushi_id = params[:data_set_id]
    sushi_app.current_user = params[:current_user]
    sushi_app.off_bfabric_registration = params[:off_bfabric_registration]
    if params[:submit_type] == "Submit"
      sushi_app.run
    elsif params[:submit_type] == "MockRun"
      sushi_app.mock_run
    end

    MakeWholeTreeJob.perform_later(params[:project_id])
  end
end
