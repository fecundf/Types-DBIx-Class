requires 'perl', '5.010';
requires 'Type::Tiny', '0.040';
requires 'Sub::Quote';
requires 'DBIx::Class';

on 'test' => sub {
  requires 'Test::More', '1.001010'; # For "use ok"
  requires 'DBD::SQLite';
  requires 'SQL::Translator', '0.11018'
};

on 'develop' => sub {
  recommends 'Test::Pod','1.14';
  recommends 'Test::Pod::Coverage', '1.04';
  recommends 'Test::EOL';
  recommends 'Test::Kwalitee';
  recommends 'Test::NoTabs';
  recommends 'Pod::Coverage::Moose';
};
