class mcollective::user inherits mcollective
{
  
  ## Create user
  group { 'mcollective':
    ensure => present,
  }

  user { 'mcollective':
    ensure   => present,
    gid      => 'mcollective',
    managehome => false,
  }

}