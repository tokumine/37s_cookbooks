ssh_options[:keys] = [File.join(ENV["HOME"], ".ssh", "id_rsa")] 
set :user, ENV['USER']
set :use_sudo, false
set :gateway, "#{ENV['USER']}@gateway.37signals.com"

role "bc-app", "bc-01", "bc-02", "bc-03", "bc-04"
role "bp-app", "bp-01", "bp-02"
role "cf-app", "cf-01", "cf-02", "cf-03"
role "hr-app", "hr-01", "hr-02", "hr-app-08"
role "37s-app", "37s-app-01", "37s-app-02"
role "live", "live-02"
role "ob-app", "ob-app-01", "ob-app-02"
role "qb-app", "qb-01", "qb-02"
role "staging", "37id-staging", "bpmu-staging", "qb-staging", "web-staging", "bc-staging", "cf-staging", "mogile-staging", "hr-staging"
role "solr", "hr-solr-indexer", "hr-solr-searcher", "cf-solr-indexer", "cf-solr-searcher", "bc-solr-indexer", "bc-solr-02"
role "mogilefs", "mogilefs-01", "mogilefs-02", "mmm-mon"
role "bc-web", "bc-web-02", "bc-web-03", "bc-web-04", "bc-web-05"
role "noc", "noc", "noc-01"
role "memcache", "memcache-01", "memcache-02", "memcache-03", "memcache-04"
role "lbal", "lbal-01", "lbal-02"
role "kvm", "kvm01", "kvm02", "kvm03", "kvm04", "kvm05", "kvm06", "kvm07", "xen11", "xen12"
role "proxy", "proxy01", "proxy02"
role "dns", "dns-01", "dns-02"
role "utility", "bulk", "gateway", "build", "integrity"
role "mail", "mail-03", "mail-04"

desc "Find a slice"
task :find, :roles => :kvm do
  sudo "kvmtool list | grep #{ENV['NAME']}"
end
