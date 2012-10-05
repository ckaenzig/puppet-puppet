class puppet::master::mongrel::plain inherits puppet::master::mongrel::standalone {
  # TODO: use a class parameter
  if (!$puppetmaster_default_path) {
    fail('You must provide a value for $puppetmaster_default_path')
  }

  case $::osfamily {
    /Debian|kFreeBSD/: {
      $context  = '/files/etc/default/puppetmaster' 
      $opts_key = 'DAEMON_OPTS'
    }

    'RedHat': {
      $context  = '/files/etc/sysconfig/puppetmaster' 
      $opts_key = 'PUPPETMASTER_EXTRA_OPTS'
    }

    default: { fail("Unknown OS family ${::osfamily}") }
  }

  $changes = $::operatingsystem ? {
    /Debian|Ubuntu|kFreeBSD/ => [
      'set PORT 18140',
      'set START yes',
      'set SERVERTYPE mongrel',
      "set PUPPETMASTERS ${nb_workers}",
      "set DAEMON_OPTS '\"--confdir=${puppetmaster_default_path} --ssl_client_header=HTTP_X_CLIENT_DN --ssl_client_verify_header=HTTP_X_CLIENT_VERIFY --bindaddress=0.0.0.0\"'",
    ],
    /RedHat|CentOS|Fedora/ => split(inline_template('
<%
vars=Array.new;
for i in 0..(nb_workers.to_i()-1);
  vars << ("set PUPPETMASTER_PORTS/" << (i+1).to_s() << " " << (base_port.to_i()+i).to_s());
end
%>
<%= "set PUPPETMASTER_EXTRA_OPTS \'\"--confdir=" << puppetmaster_default_path << " --sslclient_header=HTTP_X_CLIENT_DN --ssl_client_verify_header=HTTP_X_CLIENT_VERIFY --bindaddress=0.0.0.0\"\'@rm PUPPETMASTER_PORTS@" << vars.join("@") %>
'), '@'),
  }

  Augeas['configure puppetmaster startup variables'] {
    changes => $changes,
  }

}
