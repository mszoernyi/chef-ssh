packages = case node[:platform]
  when "centos","redhat","fedora","scientific"
    %w{openssh-clients openssh}
  when "arch"
    %w{openssh}
  else
    %w{openssh-client openssh-server}
  end
  
packages.each do |pkg|
  package pkg
end

nodes = search(:node, "keys_ssh:[* TO *]")

template "/etc/ssh/ssh_known_hosts" do
  source "known_hosts.erb"
  owner "root"
  group "root"
  mode "0644"
  variables :nodes => nodes
end

node.set[:ssh][:server][:matches] = {}

%w(ssh sshd).each do |f|
  template "/etc/ssh/#{f}_config" do
    source "#{f}_config.erb"
    owner "root"
    group "root"
    mode "0644"
  end
end

service "ssh" do
  case node[:platform]
  when "centos","redhat","fedora","arch","scientific"
    service_name "sshd"
  else
    service_name "ssh"
  end
  supports value_for_platform(
    "debian" => { "default" => [ :restart, :reload, :status ] },
    "ubuntu" => {
      "8.04" => [ :restart, :reload ],
      "default" => [ :restart, :reload, :status ]
    },
    "centos" => { "default" => [ :restart, :reload, :status ] },
    "redhat" => { "default" => [ :restart, :reload, :status ] },
    "fedora" => { "default" => [ :restart, :reload, :status ] },
    "scientific" => { "default" => [ :restart, :reload, :status ] },
    "arch" => { "default" => [ :restart ] },
    "default" => { "default" => [:restart, :reload ] }
  )
  action [ :enable, :start ]
end

execute "root-ssh-key" do
  command "ssh-keygen -f /root/.ssh/id_rsa -N ''"
  creates "/root/.ssh/id_rsa"
end

# TODO: refactor
#package "app-admin/denyhosts"

# cookbook_file "/etc/denyhosts.conf" do
#   source "denyhosts.conf"
#   owner "root"
#   group "root"
#   mode "0640"
#   notifies :restart, "service[denyhosts]"
# end
# 
# allowed_hosts = search(:node, "ipaddress:[* TO *]").map do |n| n[:ipaddress] end.sort
# 
# file "/var/lib/denyhosts/allowed-hosts" do
#   content allowed_hosts.join("\n")
#   owner "root"
#   group "root"
#   mode "0644"
# end
# 
# service "denyhosts" do
#   action [:enable, :start]
# end
# 
# cookbook_file "/etc/logrotate.d/denyhosts" do
#   source "denyhosts.logrotate"
#   owner "root"
#   group "root"
#   mode "0644"
# end
