# --
# Copyright (C) 2001-2015 OTRS AG, http://otrs.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

use strict;
use warnings;
use utf8;

use vars (qw($Self));

# get needed objects
my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

# configure auth backend to db
$ConfigObject->Set(
    Key   => 'AuthBackend',
    Value => 'DB',
);

# no additional auth backends
for my $Count ( 1 .. 10 ) {

    $ConfigObject->Set(
        Key   => "AuthBackend$Count",
        Value => '',
    );
}

# disable email checks to create new user
$ConfigObject->Set(
    Key   => 'CheckEmailAddresses',
    Value => 0,
);

my $TestUserID;

my $UserRand1 = 'example-user' . int rand 1000000;

my $UserObject = $Kernel::OM->Get('Kernel::System::User');

# add test user
$TestUserID = $UserObject->UserAdd(
    UserFirstname => 'Firstname Test1',
    UserLastname  => 'Lastname Test1',
    UserLogin     => $UserRand1,
    UserEmail     => $UserRand1 . '@example.com',
    ValidID       => 1,
    ChangeUserID  => 1,
) || die "Could not create test user";

my @Tests = (
    {
        Password   => 'simple',
        AuthResult => $UserRand1,
    },
    {
        Password   => 'very long password line which is unusual',
        AuthResult => $UserRand1,
    },
    {
        Password   => 'Переводчик',
        AuthResult => $UserRand1,
    },
    {
        Password   => 'كل ما تحب معرفته عن',
        AuthResult => $UserRand1,
    },
    {
        Password   => ' ',
        AuthResult => $UserRand1,
    },
    {
        Password   => "\n",
        AuthResult => $UserRand1,
    },
    {
        Password   => "\t",
        AuthResult => $UserRand1,
    },
    {
        Password   => "a" x 64,     # max length for plain
        AuthResult => $UserRand1,
    },

    # SQL security tests
    {
        Password   => "'UNION'",
        AuthResult => $UserRand1,
    },
    {
        Password   => "';",
        AuthResult => $UserRand1,
    },
);

for my $CryptType (qw(plain crypt apr1 md5 sha1 sha2 bcrypt)) {

    # make sure that the customer user objects gets recreated for each loop.
    $Kernel::OM->ObjectsDiscard(
        Objects => [
            'Kernel::System::User',
            'Kernel::System::Auth',
        ],
    );

    $ConfigObject->Set(
        Key   => "AuthModule::DB::CryptType",
        Value => $CryptType
    );

    my $UserObject = $Kernel::OM->Get('Kernel::System::User');
    my $AuthObject = $Kernel::OM->Get('Kernel::System::Auth');

    TEST:
    for my $Test (@Tests) {

        my $PasswordSet = $UserObject->SetPassword(
            UserLogin => $UserRand1,
            PW        => $Test->{Password},
        );

        if ( $CryptType eq 'plain' && $Test->{PlainFail} ) {
            $Self->False(
                $PasswordSet,
                "Password set"
            );
            next TEST;
        }

        $Self->True(
            $PasswordSet,
            "Password set"
        );

        my $AuthResult = $AuthObject->Auth(
            User => $UserRand1,
            Pw   => $Test->{Password},
        );

        $Self->Is(
            $AuthResult,
            $Test->{AuthResult},
            "CryptType $CryptType Password '$Test->{Password}'",
        );

        $AuthResult = $AuthObject->Auth(
            User => $UserRand1,
            Pw   => $Test->{Password},
        );

        $Self->Is(
            $AuthResult,
            $Test->{AuthResult},
            "CryptType $CryptType Password '$Test->{Password}' (cached)",
        );

        $AuthResult = $AuthObject->Auth(
            User => $UserRand1,
            Pw   => 'wrong_pw',
        );

        $Self->False(
            $AuthResult,
            "CryptType $CryptType Password '$Test->{Password}' (wrong password)",
        );

        $AuthResult = $AuthObject->Auth(
            User => 'non_existing_user_id',
            Pw   => $Test->{Password},
        );

        $Self->False(
            $AuthResult,
            "CryptType $CryptType Password '$Test->{Password}' (wrong user)",
        );
    }
}

$TestUserID = $UserObject->UserUpdate(
    UserID        => $TestUserID,
    UserFirstname => 'Firstname Test1',
    UserLastname  => 'Lastname Test1',
    UserLogin     => $UserRand1,
    UserEmail     => $UserRand1 . '@example.com',
    ValidID       => 2,
    ChangeUserID  => 1,
) || die "Could not invalidate test user";

1;
