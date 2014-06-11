class Reminders::Plugin < Plugin

	collection_tab '/reminder_tab'

  schedule \
    every: "1m",
    class: "ReminderTask",
    queue: 'reminder_queue'

	routes {
		resources :collections do
			resources :reminders do
        post :set_status, :on => :member
      end
		end

    match 'get_time_zone' => "reminders#get_time_zone"
	}
end
