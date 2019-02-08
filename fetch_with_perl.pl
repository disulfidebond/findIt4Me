#!/usr/bin/perl

use strict;
use warnings;
use LWP::UserAgent;

my $base = 'https://www.uniprot.org';
my $tool = 'uploadlists';

my $f = $ARGV[0];
open (my $fh, "<", $f) or die "no argument was passed to this script!\n";

my $db_xref = $ARGV[1];
# if ($db_xref eq "") {
if (not defined $db_xref) {
  print "## No database name provided!\n";
  $db_xref = 'P_REFSEQ_AC';
}

my $dbName = '';
my %h = (
  EMBL_ID => 'EMBL-GeneBank',
  EMBL => 'EMBL-GeneBank_CDS-region',
  P_ENTREZGENEID => 'Entrez-Gene',
  P_GI => 'GI-number',
  EMBL_ID => 'EMBL-GeneBank',
  REFSEQ_NT_ID => 'Refseq-nucleotide',
  P_REFSEQ_AC => 'Refseq-protein',
  ENSEMBL_ID => 'Ensembl-ID',
  ENSEMBL_PRO_ID => 'Ensembl-Protein-ID',
  ENSEMBL_TRS_ID => 'Ensembl-Transcript-ID',
  GENENAME => 'GeneName-Identifier'
);

if (exists $h{$db_xref}) {
  my $s = $h{$db_xref};
  $dbName = $s;
}
else {
  $dbName = 'Other DB';
}

my @a;
while (<$fh>) {
  chomp;
  push @a, $_;
}
my $q = join ' ', @a;

print "Using $dbName\n";

my $params = {
  from => 'ACC',
  to => $db_xref,
  format => 'tab', # tab == whitespace
  query => $q
};

my $contact = ''; # Please set a contact email address here to help us debug in case of problems (see https://www.uniprot.org/help/privacy).
my $agent = LWP::UserAgent->new(agent => "libwww-perl $contact");
push @{$agent->requests_redirectable}, 'POST';

my $response = $agent->post("$base/$tool/", $params);

while (my $wait = $response->header('Retry-After')) {
  print STDERR "Waiting ($wait)...\n";
  sleep $wait;
  $response = $agent->get($response->base);
}

$response->is_success ?
  print $response->content :
  die 'Failed, got ' . $response->status_line .
    ' for ' . $response->request->uri . "\n";
