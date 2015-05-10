requires 'Types::Tiny', '0.040';
requires 'Sub::Quote';
requires 'DBIx::Class';

on 'test' => sub {
  requires 'Test::more';
  requires 'DBD::SQLite';
};

on 'develop' => sub {
  recommends 'Test::Pod','1.14';
  recommends 'Test::Pod::Coverage', '1.04';
  recommends 'Test::EOL';
  recommends 'Test::Kwalitee';
  recommends 'Test::NoTabs';
  recommends 'Pod::Coverage::Moose';
};
