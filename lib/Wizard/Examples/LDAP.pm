# -*- perl -*-

use Socket ();
use Wizard ();
use Wizard::State ();
use Wizard::SaveAble();
use Wizard::Examples::LDAP::Config ();

package Wizard::Examples::LDAP;

@Wizard::Examples::LDAP::ISA = qw(Wizard::State);
$Wizard::Examples::LDAP::VERSION = '0.1004';

sub init {
    my $self = shift; 
    my $item = $self->{'prefs'} || die "Missing prefs";
    my $admin = { 'ldap-admin-dn' => $item->{'ldap-prefs-adminDN'},
		  'ldap-admin-password' => $item->{'ldap-prefs-adminPassword'} };
    ($item, $admin);
}

sub Action_Reset {
    my($self, $wiz) = @_;

    # Load prefs, if required.
    unless ($self->{'prefs'}) {
	my $cfg = $Wizard::Examples::LDAP::Config::config;
	my $file = $cfg->{'ldap-prefs-file'};
	$self->{'prefs'} = Wizard::SaveAble->new('file' => $file, 'load' => 1);
    }
    $self->Store($wiz);

    # Return the initial menu.
    (['Wizard::Elem::Title', 'value' => 'LDAP Wizard Menu '],
     ['Wizard::Elem::Submit', 'value' => 'User Menu',
      'name' => 'Wizard::Examples::LDAP::User::Action_Reset',
      'id' => 1],
     ['Wizard::Elem::Submit', 'value' => 'Net Menu',
      'name' => 'Wizard::Examples::LDAP::Net::Action_Reset',
      'id' => 2],
     ['Wizard::Elem::BR'],
     ['Wizard::Elem::Submit', 'value' => 'LDAP Wizard preferences',
      'name' => 'Action_Preferences',
      'id' => 3],
     ['Wizard::Elem::BR'],
     ['Wizard::Elem::Submit', 'value' => 'Exit LDAP Wizard',
      'id' => 99]);
}

sub Action_Preferences {
    my($self, $wiz) = @_;
    my ($prefs, $admin)  = $self->init();

    # Return a list of input elements.
    (['Wizard::Elem::Title', 'value' => 'LDAP Wizard Preferences'],
     ['Wizard::Elem::Text', 'name' => 'ldap-prefs-serverip',
      'value' => $prefs->{'ldap-prefs-serverip'},
      'descr' => 'Server DNS name or IP Adress of the LDAP Server'],
     ['Wizard::Elem::Text', 'name' => 'ldap-prefs-serverport',
      'value' => $prefs->{'ldap-prefs-serverport'},
      'descr' => 'Server Port of the LDAP Server (default LDAP port on 0)'],
     ['Wizard::Elem::Text', 'name' => 'ldap-prefs-adminDN',
      'value' => $prefs->{'ldap-prefs-adminDN'},
      'descr' => 'Distinguished name of the admin object we bind as ' .
                 'to the server'],
     ['Wizard::Elem::Text', 'name' => 'ldap-prefs-adminPassword',
      'value' => $prefs->{'ldap-prefs-adminPassword'},
      'descr' => 'Password of the admin object'],
     ['Wizard::Elem::Text', 'name' => 'ldap-prefs-nextuid',
      'value' => $prefs->{'ldap-prefs-nextuid'} || '500',
      'descr' => 'Next UID that will be assigned (increased automatically'],
     ['Wizard::Elem::Text', 'name' => 'ldap-prefs-gid',
      'value' => $prefs->{'ldap-prefs-gid'} || '500',
      'descr' => 'Group ID of the group the users will belong to'],
     ['Wizard::Elem::Text', 'name' => 'ldap-prefs-home',
      'value' => $prefs->{'ldap-prefs-home'} || '/home',
      'descr' => 'Homedir prefix'],
     ['Wizard::Elem::Text', 'name' => 'ldap-prefs-userbase',
      'value' => $prefs->{'ldap-prefs-userbase'} || 'dc=ispsoft, c=de',
      'descr' => 'LDAP base for user administration'],
     ['Wizard::Elem::Text', 'name' => 'ldap-prefs-netbase',
      'value' => $prefs->{'ldap-prefs-netbase'} || 'dc=ispsoft, c=de',
      'descr' => 'LDAP base for net administration'],
     ['Wizard::Elem::Text', 'name' => 'ldap-prefs-domain',
      'value' => $prefs->{'ldap-prefs-domain'} || '',
      'descr' => 'Default domain for user administration'],
     ['Wizard::Elem::Text', 'name' => 'ldap-prefs-prefschange',
      'value' => $prefs->{'ldap-prefs-prefschange'} || '',
      'descr' => 'Shell command after the prefs have been changed'],
     ['Wizard::Elem::Text', 'name' => 'ldap-prefs-hostchange',
      'value' => $prefs->{'ldap-prefs-hostchange'} || '',
      'descr' => 'Shell command after Hosts have been changed'],
     ['Wizard::Elem::Text', 'name' => 'ldap-prefs-netchange',
      'value' => $prefs->{'ldap-prefs-netchange'} || '',
      'descr' => 'Shell command after Nets have been changed'],
     ['Wizard::Elem::Text', 'name' => 'ldap-prefs-userchange-new',
      'value' => $prefs->{'ldap-prefs-userchange-new'} || '',
      'descr' => 'Shell command after an user has been created'],
     ['Wizard::Elem::Text', 'name' => 'ldap-prefs-userchange-modify',
      'value' => $prefs->{'ldap-prefs-userchange-modify'} || '',
      'descr' => 'Shell command after an user has been modified'],
     ['Wizard::Elem::Text', 'name' => 'ldap-prefs-userchange-delete',
      'value' => $prefs->{'ldap-prefs-userchange-delete'} || '',
      'descr' => 'Shell command after an user has been deleted'],
     ['Wizard::Elem::Submit', 'name' => 'Action_PreferencesSave',
      'value' => 'Save these settings', 'id' => 1],
     ['Wizard::Elem::Submit', 'name' => 'Action_PreferencesReset',
      'value' => 'Reset this form', 'id' => 98],
     ['Wizard::Elem::Submit', 'name' => 'Action_Reset',
      'value' => 'Return to top menu', 'id' => 99]);
}


#
# universal method, that is supposed to be used by subclasses
#
sub ItemList {
    my($self, $prefs, $admin, $base, $key) = @_;

    my $ldap = Net::LDAP->new($prefs->{'ldap-prefs-serverip'},
			      (($prefs->{'ldap-prefs-serverport'} >0) ?
			       (port => $prefs->{'ldap-prefs-serverport'}) : ()));
    die "Could not create LDAP object, maybe connecting is currently not "
	. "possible , probable cause: $@" 
	    unless ref($ldap);
    $ldap->bind(dn      => $admin->{'prefs-admin-dn'},
		password => $admin->{'prefs-admin-password'})
	|| die "Cannot bind to LDAP server $@";
    my $mesg = $ldap->search(base => $base,
			     filter => $key . '=*',
			     scope => 1);
    die "Following error occured while searching for $base: code=" . $mesg->code
	. ", error=" . $mesg->error  if $mesg->code;

    my @items = map { ($_->get($key)) } $mesg->entries;
    $ldap->unbind();
    wantarray ? @items : $mesg;
}


sub Action_PreferencesSave {
    my($self, $wiz) = @_;
    my ($prefs, $admin) = $self->init();
    foreach my $opt ($wiz->param()) {
	$prefs->{$opt} = $wiz->param($opt) 
	    if (($opt =~ /^ldap\-prefs/) && (defined($wiz->param($opt))));
    }

    my $errors = '';
    my $ip = $prefs->{'ldap-prefs-serverip'} 
        or ($errors .= "Missing Server IP or DNS name.\n");
    my $adminDN = $prefs->{'ldap-prefs-adminDN'}
        or ($errors .= "Missing admin DN.\n");
    my $port = $prefs->{'ldap-prefs-serverport'};
    my $uid = $prefs->{'ldap-prefs-nextuid'};
    my $gid = $prefs->{'ldap-prefs-gid'};
    my $home = $prefs->{'ldap-prefs-home'};
    if($ip) {
	unless(Socket::inet_aton($ip)) {
	    $errors .= "Unresolveable server DNS name $ip.\n";
	}
    }
    $port = 0 if $port eq '';
    $errors .= "Invalid port $port.\n" unless $port =~ /^[\d]*$/;
    $errors .= "Invalid UID $uid" unless $uid =~ /^[\d]+$/;
    $errors .= "Invalid GID $gid" unless $gid =~ /^[\d]+$/;
    if ($home =~ /^((\/[^\/]+)+)\/?$/) {
	$prefs->{'ldap-prefs-home'} = $home = $1;
    } else {
	$errors .= "Invalid home $home";
    }
    die $errors if $errors;
    $prefs->Modified(1);
    $self->Store($wiz, 1);
    $self->OnChange('prefs');
    $self->Action_Reset($wiz);
}

sub Action_PreferencesReset {
    my($self, $wiz) = @_;
    $self->Action_Reset($wiz);
    $self->Action_Preferences($wiz);
}

sub OnChange {
    my $self = shift; my $topic = shift;
    my $mode = shift || '';
    my $subst = shift || {};
    my($prefs) = $self->init();
    my $cmd = $prefs->{'ldap-prefs-' . $topic . 'change' . $mode};
    my ($k, $s);
    while(($k, $s) = each %$subst) {
	$cmd =~ s/\$$k/$s/g;
    }
    my $file = $cmd; $file =~ s/\ .*//g;
    system($cmd) if(-f $file);
}




