class Chef::Recipe
    include Chef::Coscale
end

ruby_block "send event" do
    block do
        Chef::Coscale.event(
            # Authentication info
            accesstoken='',
            appid='',

            # Event information
            event_name='Category of the event',
            event_message='Custom message',
            event_timestamp=0, # Now

            # URL to push event to
            baseurl='https://api.coscale.com/'
            )
    end
end
