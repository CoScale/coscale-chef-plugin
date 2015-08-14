class Chef::Recipe
    include Chef::Coscale
end

ruby_block "send event" do
    block do
        Chef::Coscale.event(
            baseurl='http://api.qa.coscale.com/',                   # Specify the required ``baseurl`` parameter.
            accesstoken='ba6e6bca-189a-4d4f-a73f-e97f7363f7ca',     # Specify the required ``accesstoken`` parameter.
            appid='00005af2-23f3-4ae1-82a8-360c949c6d1c',           # Specify the required ``appid`` parameter.
            event_name='Software updates',                          # Specify the required ``event_name`` parameter.
            event_message='Updating Nginx',                         # Specify the required ``event_message`` parameter.
            event_timestamp=0)                                      # Specify the required ``event_timestamp`` parameter.
    end
end
