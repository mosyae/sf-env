servers=[
{
  :hostname => "sensu",
  :ip => "192.168.100.100",
  :box => "centos/7",
  :ram => 2048,
  :cpu => 2,
  :provisions => ["sensu.sh"]
},
{
  :hostname => "sf-mngdn1",
  :ip => "192.168.100.11",
  :box => "centos/7",
  :ram => 3072,
  :cpu => 2,
  :provisions => ["mgn.sh"]
},
{
  :hostname => "sf-mngdn2",
  :ip => "192.168.100.12",
  :box => "centos/7",
  :ram => 2048,
  :cpu => 2,
  :provisions => ["mgn.sh"]
},
{
  :hostname => "sf-mngdn3",
  :ip => "192.168.100.13",
  :box => "centos/7",
  :ram => 5120,
  :cpu => 2,
  :provisions => ["mgn.sh"]
}
]

Vagrant.configure("2") do |config|
  servers.each do |machine|
    config.vm.define machine[:hostname] do |node|
        machine [:provisions].each do |script|
           node.vm.provision :shell, :path => script
        end
      node.vm.box = machine[:box]
      node.vm.hostname = machine[:hostname]
      node.vm.network "private_network", ip: machine[:ip]
	  node.vm.boot_timeout = 1200
      node.vm.provider "virtualbox" do |vb|
        vb.memory = machine[:ram]
        vb.cpus = machine[:cpu]
      end
    end
  end
end
