define :virtual_machine do
  hostname = "#{@params[:name]}.#{@node[:internal_domain]}"
  config_dir = "#{params[:path]}/config"
  key_file = "#{config_dir}/client.pem"
  root_image = "#{params[:path]}/img/disk0.qcow2"

  execute "save_vm_config" do
    command "/usr/bin/virsh dumpxml #{params[:name]} > #{config_dir}/#{params[:name]}.xml"
    action :nothing
  end

  directory config_dir do
    owner "root"
    group "libvirtd"
    mode 00770
    recursive true
  end

  template "#{config_dir}/manifest.txt" do
    backup false
    owner "root"
    group "libvirtd"
    mode 00660
    source "manifest.txt.erb"
    variables :key_file => key_file
  end

  ruby_block "generate_client_config" do
    block do
      run_list = Chef::RunList.new
      params[:run_list].each do |item|
        run_list << item
      end
      
      node = Chef::Node.new
      node.name(hostname)
      node.run_list = run_list
      node.create
      
      client = Chef::ApiClient.new
      client.name(hostname)
      response = client.save(true, false)

      File.open(key_file, "w") do |key|
        key.puts response['private_key']
      end
    end

    not_if { File.exist?(root_image) }
  end

  file key_file do
    owner "root"
    group "libvirtd"
    mode 00660
  end

  execute "remove_client_pem" do
    command "rm -f #{key_file}"
    action :nothing
    only_if { File.exist?(key_file) }
  end

  execute "chown_root_image" do
    command "chown root:libvirtd #{root_image} && chmod 660 #{root_image}"
    action :nothing
  end

  execute "build_vm_image" do
    command <<-EOVM
/usr/bin/vmbuilder kvm ubuntu --suite=#{@params[:suite]} --flavour=virtual --arch=#{@params[:arch]} \
  --hostname=#{@params[:name]} --mem=#{@params[:memory]} --cpus=#{@params[:vcpus]} --mirror=#{@node[:apt_mirror]} \
  --dest=#{@params[:path]}/img --rootsize=#{@params[:root_size]} --swapsize=#{@params[:swap_size]} \
  --ip=#{@params[:external_ip]} --mask=#{@node[:networks][:ext][:netmask]} \
  --net=#{@node[:networks][:ext][:network]} --bcast=#{@node[:networks][:ext][:broadcast]} \
  --gw=#{@node[:networks][:ext][:gateway]} --dns=#{@node[:nameservers].first} --bridge=br0 \
  --addpkg=openssh-server --addpkg=acpid --addpkg=build-essential --addpkg=wget --addpkg=ntp --addpkg=syslog-ng \
  --user=signal --name='37signals Administrator' \
  --firstboot=/usr/local/share/kvm/files/chef-firstboot \
  --lang=en_US.UTF-8 \
  --templates=/usr/local/share/kvm/templates \
  --copy=#{config_dir}/manifest.txt \
  --execscript=/usr/local/share/kvm/scripts/postinstall.sh \
  --libvirt=qemu:///system --verbose --debug
EOVM

    notifies :run, resources(:execute => "save_vm_config")
    notifies :run, resources(:execute => "remove_client_pem")
    notifies :run, resources(:execute => "chown_root_image")

    creates root_image
  end
end
