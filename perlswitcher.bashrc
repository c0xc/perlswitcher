# Perlswitcher
# Switch between system perl + local::lib and user perl

LS=/bin/ls
WHICH=/usr/bin/which
READLINK=/bin/readlink
SYSTEM_PERL=/usr/bin/perl

: <<=cut
=pod

=head1 NAME

   Perlswitcher - Switch between system perl + local::lib and user perl

=head1 SYNOPSIS

    $ perlinfo
    currently using system perl: /usr/bin/perl: (revision 5 version 14 subversion 2)
    PERL5LIB: /var/www/perl5/lib/perl5/x86_64-linux-gnu-thread-multi:/var/www/perl5/lib/perl5
    $ perlbrew list
      perl-5.16.3
      perl-5.18.4
      perl-5.20.2
    $ perlswitch perl-5.18.4
    Setting new perl /var/www/perl5/perlbrew/perls/perl-5.18.4/bin/perl...
    Using user perl (site_perl) instead of local::lib
    $ perlbrew list
      perl-5.16.3
    * perl-5.18.4
      perl-5.20.2
    $ perlinfo
    currently using user perl: /home/www/perl5/perlbrew/perls/perl-5.18.4/bin/perl: (revision 5 version 18 subversion 4)
    PERL5LIB is empty
    $ perlswitch
    going back to system perl...
    Setting up local::lib ... OK
    $ perlinfo
    currently using system perl: /usr/bin/perl: (revision 5 version 14 subversion 2)
    PERL5LIB: /var/www/perl5/lib/perl5/x86_64-linux-gnu-thread-multi:/var/www/perl5/lib/perl5

=head1 DESCRIPTION

This is a cheap script to switch between system perl with local::lib
and user perl (installed by Perlbrew) without local::lib.
Environment variables are set so that cpanm always knows
where to install (local::lib or user perl).
Nothing will be installed system-wide, no root permissions are required.

=head1 INSTALLATION

Install Perlbrew (L<http://perlbrew.pl/>).

mkdir ~/perl5/userperls

Copy this script to ~/perl5/userperls/bashrc

echo '. ~/perl5/userperls/bashrc' >>~/.bashrc

=head1 BUGS

Probably a few. Not much time went into writing this thing.

=head1 AUTHOR

Philip Seeger

=cut

echo -ne "Cleaning PATH for perl..."

# Remove *perl* from PATH
declare -a dirs_old
declare -a dirs_new
IFS=':' read -ra dirs_old <<< "$PATH"
for i in "${dirs_old[@]}"; do
    [[ $(echo "$i" | grep -i perl) ]] && continue
    dirs_new+=("$i")
done
unset dirs_old
#tr ' ' '\n' <<< "${dirs_new[@]}" | sort -u | tr '\n' ' '
dirs_new=($(printf "%s\n" "${dirs_new[@]}" | sort -u))
PATH=""
for i in "${dirs_new[@]}"; do
    [[ ! -z "$PATH" ]] && PATH="$PATH:"
    PATH="$PATH$i"
done
unset dirs_new

for i in {1..25}; do echo -ne "\b"; done
for i in {1..25}; do echo -ne " "; done
for i in {1..25}; do echo -ne "\b"; done

# Add additional perl dirs back to PATH
for dir in ~/perl5/userperls/path*; do
    dir_dst=$($READLINK -f "$dir")
    if [[ -d "$dir_dst" ]]; then
        #echo "Adding $dir ($dir_dst) to PATH"
        PATH="$dir_dst:$PATH"
    else
        echo Additional PATH dir not found: $dir
        continue
    fi
done

# Find system perl
#SYSTEM_PERL=$($WHICH perl) # NO

# Find user perl
USER_PERL=~/perl5/userperls/perl
if [[ -e "$USER_PERL" ]]; then
    USER_PERL=$(readlink -f "$USER_PERL")
fi
USER_PERL_NAME=$(echo "$USER_PERL" | grep -Eo '/[^/]+/bin/perl' | cut -f2 -d'/')

# Switch
if [[ -x "$USER_PERL" ]]; then
    # Use user perl only

    # Clearing local::lib vars
    echo 'Using user perl (site_perl) instead of local::lib'
    unset PERL_MB_OPT
    unset PERL_MM_OPT
    unset PERL_CPANM_OPT
    unset PERL5LIB
    unset PERL_LOCAL_LIB_ROOT

    # Trick perlbrew
    export PERLBREW_PERL=$USER_PERL_NAME

    # Add user perl to PATH
    USER_PERL_DIR=$(dirname "$USER_PERL")
    export PATH="$USER_PERL_DIR:$PATH"
else
    # Use system perl + local::lib

    # Enable local::lib
    echo -n "Setting up local::lib ... "
    eval $($SYSTEM_PERL -I ~/perl5/lib/perl5/ -Mlocal::lib) && echo OK || echo ERROR
    export PERL_CPANM_OPT="--local-lib=~/perl5"

    # Un-trick perlbrew
    unset PERLBREW_PERL
fi

# Version Info Helper
function perlinfo
{
    SYSTEM_PERL=$(which perl)
    USER_PERL=~/perl5/userperls/perl
    USER_PERL=$(readlink -f "$USER_PERL")
    if [[ -x "$USER_PERL" ]]; then
        INFO=$($USER_PERL -V | head -n 1 | grep -o '(.*)')
        echo "currently using user perl: $USER_PERL: $INFO"
    else
        INFO=$($SYSTEM_PERL -V | head -n 1 | grep -o '(.*)')
        echo "currently using system perl: $(which perl): $INFO"
    fi
    if [[ -z "$PERL5LIB" ]]; then
        echo PERL5LIB is empty
    else
        echo "PERL5LIB: $PERL5LIB"
    fi
}

# Switch Helper
function perlswitch
{
    NEW_PERL=$1
    if [[ ! -e "$NEW_PERL" ]]; then
        if [[ -d "$HOME/perl5/perlbrew/perls/$NEW_PERL/bin/" ]]; then
            NEW_PERL="$HOME/perl5/perlbrew/perls/$NEW_PERL/bin/perl"
        elif [[ -f "$HOME/perl5/userperls/$NEW_PERL" ]]; then
            NEW_PERL="$HOME/perl5/userperls/$NEW_PERL"
        fi
    fi
    if [[ -z "$NEW_PERL" ]]; then
        echo going back to system perl...
        USER_PERL=$HOME/perl5/userperls/perl
        [[ -L "$USER_PERL" ]] && unlink $USER_PERL
        SCRIPT=$HOME/perl5/userperls/bashrc
        source $SCRIPT # Not in subshell!
    elif [[ -x "$NEW_PERL" ]]; then
        echo Setting new perl $NEW_PERL...
        [[ -L "$USER_PERL" ]] && unlink $USER_PERL
        ln -sf "$NEW_PERL" "$HOME/perl5/userperls/perl"
        SCRIPT=$HOME/perl5/userperls/bashrc
        source $SCRIPT # Not in subshell!
    else
        echo "new perl not found: $NEW_PERL"
    fi
}

