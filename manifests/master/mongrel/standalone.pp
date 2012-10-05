class puppet::master::mongrel::standalone inherits puppet::master {

  # TODO: make mongrel count configurable

  $mongrel = $::operatingsystem ? {
    /Debian|Ubuntu|kFreeBSD/ => 'mongrel',
    /RedHat|CentOS|Fedora/   => 'rubygem-mongrel',
  }

  $nb_workers = $puppet_master_mongrel_standalone_nbworkers ? {
    '' => '4',
    default => $puppet_master_mongrel_standalone_nbworkers,
  }

  $base_port = 18140

  package {'mongrel':
    ensure => present,
    name   => $mongrel,
  }

  service {'puppetmaster':
    ensure    => running,
    hasstatus => true,
    enable    => true,
    require   => Package['mongrel'],
  }

  $context = $::operatingsystem ? {
    /Debian|Ubuntu|kFreeBSD/ => '/files/etc/default/puppetmaster',
    /RedHat|CentOS|Fedora/   => '/files/etc/sysconfig/puppetmaster',
  }

  $changes = $::operatingsystem ? {
    /Debian|Ubuntu|kFreeBSD/ => [
      'set PORT 18140',
      'set START yes',
      'set SERVERTYPE mongrel',
      "set PUPPETMASTERS ${nb_workers}",
    ],
    /RedHat|CentOS|Fedora/ => split(inline_template('
<%
vars=Array.new;
for i in 0..(nb_workers.to_i()-1);
  vars << ("set PUPPETMASTER_PORTS/" << (i+1).to_s() << " " << (base_port.to_i()+i).to_s());
end
%>
<%= "set PUPPETMASTER_EXTRA_OPTS \'\"--servertype=mongrel\"\'@rm PUPPETMASTER_PORTS@" << vars.join("@") %>
'), '@'),
  }

  augeas {'configure puppetmaster startup variables':
    context => $context,
    changes => $changes,
    notify  => Service['puppetmaster'],
  }

}
