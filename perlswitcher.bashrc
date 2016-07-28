# Perlswitcher
# Switch between system Perl + local::lib and user Perl

: <<=cut
=pod

=head1 NAME

   Perlswitcher - Switch between system Perl + local::lib and user Perl

=head1 SYNOPSIS

    $ perlinfo
    Currently using system Perl: /usr/bin/perl: (revision 5 version 14 subversion 2)
    PERL5LIB: /var/www/perl5/lib/perl5/x86_64-linux-gnu-thread-multi:/var/www/perl5/lib/perl5
    $ perlbrew list
      perl-5.16.3
      perl-5.18.4
      perl-5.20.2
    $ perlswitch perl-5.18.4
    Switching to user Perl /var/www/perl5/perlbrew/perls/perl-5.18.4/bin/perl...
    Using user Perl (site_perl) instead of local::lib...
    $ perlbrew list
      perl-5.16.3
    * perl-5.18.4
      perl-5.20.2
    $ perlinfo
    Currently using user Perl: /home/www/perl5/perlbrew/perls/perl-5.18.4/bin/perl: (revision 5 version 18 subversion 4)
    PERL5LIB is empty
    $ perlswitch
    Going back to system Perl...
    Using system Perl with local::lib...
    $ perlinfo
    Currently using system Perl: /usr/bin/perl: (revision 5 version 14 subversion 2)
    PERL5LIB: /var/www/perl5/lib/perl5/x86_64-linux-gnu-thread-multi:/var/www/perl5/lib/perl5

=head1 DESCRIPTION

This is a cheap script to switch between system Perl with local::lib
and user Perl (installed by Perlbrew) without local::lib.
Environment variables are set so that cpanm always knows
where to install packages (local::lib or user Perl).
Nothing will be installed system-wide, no root permissions are required.

=head1 INSTALLATION

Install Perlbrew (L<http://perlbrew.pl/>).

    $ mkdir ~/perl5/userperls

Copy this script to ~/perl5/userperls/bashrc

    $ echo '. ~/perl5/userperls/bashrc' >>~/.bashrc

Add symlinks for directories to be prepended to $PATH.
Their names must begin with "path-".

    $ cd ~/perl5/userperls/
    $ ln -s ~/perl5/bin path-bin
    $ ln -s ~/perl5/perlbrew/bin path-perlbrew-bin

=head1 UNINSTALLATION

Remove this script from your C<~/.bashrc>.

Delete the C<userperls> directory.

=head1 BUGS

Probably a few. Not much time went into writing this thing.

=head1 AUTHOR

Philip Seeger

=cut

# Check environment
if [ ! -d "$HOME/perl5/userperls" ]; then
    echo "PERLSWITCHER ERROR: Directory not found: perl5/userperls" >&2
    exit 1
fi

# Remember old PATH
if [ -z "$PERLSWITCHER_OLD_PATH" ]; then
    PERLSWITCHER_OLD_PATH="$PATH"
fi

# Reset PATH
function _perlswitcher_clear_path
{
    if [ -n "$PERLSWITCHER_OLD_PATH" ]; then
        # Restore old PATH
        PATH="$PERLSWITCHER_OLD_PATH"
    else
        # Remove *perl* from PATH (fallback)
        local dirs_old
        local dirs_new
        declare -a dirs_old
        declare -a dirs_new
        IFS=':' read -ra dirs_old <<< "$PATH"
        for i in "${dirs_old[@]}"; do
            # Skip directory if path contains "perl"
            [[ $(echo "$i" | grep -i perl) ]] && continue
            dirs_new+=("$i")
        done
        dirs_new=($(printf "%s\n" "${dirs_new[@]}" | sort -u))
        PATH=""
        for i in "${dirs_new[@]}"; do
            [[ ! -z "$PATH" ]] && PATH="$PATH:"
            PATH="$PATH$i"
        done
    fi
}
_perlswitcher_clear_path

# Locate system Perl
if [ -z "$PERLSWITCHER_SYSTEM_PERL" ]; then
    PERLSWITCHER_SYSTEM_PERL=$(/usr/bin/which perl)
    if [ $? -ne 0 ]; then
        echo "PERLSWITCHER ERROR: System Perl not found" >&2
        exit 1
    fi
fi
if [ ! -x "$PERLSWITCHER_SYSTEM_PERL" ]; then
    echo "PERLSWITCHER ERROR: System Perl not valid" >&2
    exit 1
fi

# Extend PATH by adding configured directories
# They're prepended because Perl related binaries 
# should be preferred over old system binaries.
function _perlswitcher_extend_path
{
    local dir
    local dir_dst
    for dir in $HOME/perl5/userperls/path*; do
        [ -e "$dir" ] || continue
        dir_dst=$(readlink -f "$dir")
        if [ -d "$dir_dst" ]; then
            PATH="$dir_dst:$PATH"
        else
            echo "PERLSWITCHER ERROR: Additional PATH dir not found: $dir" >&2
            continue
        fi
    done
}
_perlswitcher_extend_path

# Set environment for Perl
function _perlswitcher_set_env
{
    # User Perl
    local USER_PERL
    local USER_PERL_NAME
    USER_PERL=$HOME/perl5/userperls/perl
    if [[ -e "$USER_PERL" ]]; then
        USER_PERL=$(readlink -f "$USER_PERL")
    fi
    USER_PERL_NAME=$(echo "$USER_PERL" | \
        grep -Eo '/[^/]+/bin/perl' | \
        cut -f2 -d'/')

    # Switch
    if [ -x "$USER_PERL" ]; then
        # Use user Perl only
        echo "Using user Perl (site_perl) instead of local::lib..."

        # Unset local::lib vars
        unset PERL_MB_OPT
        unset PERL_MM_OPT
        unset PERL_CPANM_OPT
        unset PERL5LIB
        unset PERL_LOCAL_LIB_ROOT

        # Trick perlbrew
        export PERLBREW_PERL=$USER_PERL_NAME

        # Add user perl to PATH
        local USER_PERL_DIR
        USER_PERL_DIR=$(dirname "$USER_PERL")
        PATH="$USER_PERL_DIR:$PATH"

    else
        # Use system Perl + local::lib
        echo "Using system Perl with local::lib..."

        # Un-trick perlbrew
        unset PERLBREW_PERL

        # Enable local::lib
        eval "$($PERLSWITCHER_SYSTEM_PERL -I$HOME/perl5/lib/perl5 -Mlocal::lib)"
        export PERL_CPANM_OPT="--local-lib=$HOME/perl5"

    fi
}
_perlswitcher_set_env

# Version info function
function perlinfo
{
    local USER_PERL=$HOME/perl5/userperls/perl
    USER_PERL=$(readlink -f "$USER_PERL")
    local INFO
    if [[ -x "$USER_PERL" ]]; then
        INFO=$($USER_PERL -V | head -n 1 | grep -o '(.*)')
        echo "Currently using user Perl: $USER_PERL: $INFO"
    else
        INFO=$($PERLSWITCHER_SYSTEM_PERL -V | head -n 1 | grep -o '(.*)')
        echo "Currently using system Perl: $(which perl): $INFO"
    fi
    if [[ -z "$PERL5LIB" ]]; then
        echo "PERL5LIB is empty"
    else
        echo "PERL5LIB: $PERL5LIB"
    fi
}

# Switch helper function
function perlswitch
{
    # Find specified target Perl
    local NEW_PERL="$1"
    if [ -z "$NEW_PERL" ]; then
        : # System Perl
    elif [ ! -e "$NEW_PERL" ]; then
        if [ -d "$HOME/perl5/perlbrew/perls/$NEW_PERL/bin/" ]; then
            NEW_PERL="$HOME/perl5/perlbrew/perls/$NEW_PERL/bin/perl"
        elif [ -f "$HOME/perl5/userperls/$NEW_PERL" ]; then
            NEW_PERL="$HOME/perl5/userperls/$NEW_PERL"
        fi
    fi

    # Switch
    local USER_PERL=$HOME/perl5/userperls/perl
    if [ -x "$NEW_PERL" ]; then
        # User Perl
        echo "Switching to user Perl $NEW_PERL..."

        # Update link
        [[ -L "$USER_PERL" ]] && unlink $USER_PERL
        ln -sf "$NEW_PERL" "$HOME/perl5/userperls/perl"

        # Reset PATH
        _perlswitcher_clear_path

        # Extend PATH by adding configured directories
        _perlswitcher_extend_path

        # Set environment for Perl
        _perlswitcher_set_env

    elif [ -z "$NEW_PERL" ]; then
        # System Perl
        echo "Going back to system Perl..."

        # Update link
        [[ -L "$USER_PERL" ]] && unlink $USER_PERL

        # Reset PATH
        _perlswitcher_clear_path

        # Set environment for Perl
        _perlswitcher_set_env

    else
        echo "New Perl not found: $NEW_PERL" >&2
        echo "Brewed Perls:" >&2
        ls $HOME/perl5/perlbrew/perls/ >&2
    fi
}



