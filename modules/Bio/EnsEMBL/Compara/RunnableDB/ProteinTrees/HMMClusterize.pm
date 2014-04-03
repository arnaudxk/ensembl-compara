=head1 LICENSE

Copyright [1999-2014] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

# POD documentation - main docs before the code

=pod 

=head1 NAME

Bio::EnsEMBL::Compara::RunnableDB::ProteinTrees::HMMClusterize

=cut

=head1 CONTACT

Please email comments or questions to the public Ensembl
developers list at <http://lists.ensembl.org/mailman/listinfo/dev>.

Questions may also be sent to the Ensembl help desk at
<http://www.ensembl.org/Help/Contact>.

=cut

=head1 APPENDIX

The rest of the documentation details each of the object methods.
Internal methods are usually preceded with a _

=cut

package Bio::EnsEMBL::Compara::RunnableDB::ProteinTrees::HMMClusterize;

use strict;
use warnings;

use Data::Dumper;

use base ('Bio::EnsEMBL::Compara::RunnableDB::GeneTrees::StoreClusters');

sub param_defaults {
    return {
            'sort_clusters'         => 1,
            'immediate_dataflow'    => 1,
            'member_type'           => 'protein',
    };
}


sub run {
    my $self = shift @_;
    $self->load_hmmer_classifications();
}


sub write_output {
    my $self = shift @_;
    $self->store_clusterset('default', $self->param('allclusters'));
}

##########################################
#
# internal methods
#
##########################################

sub load_hmmer_classifications {
    my ($self) = @_;

    my %allclusters = ();
    $self->param('allclusters', \%allclusters);

    # Get statement handler to query all hmm classifications from 'hmm_annot' table
    my $sth  = $self->compara_dba->get_HMMAnnotAdaptor->fetch_all_hmm_annot();
    $sth->execute();
    while (my $res = $sth->fetchrow_arrayref){
        push @{$allclusters{$res->[1]}{members}}, $res->[0];
    }
    $sth->finish;

    for my $model_name (keys %allclusters) {
        ## we filter out clusters singleton clusters
        if (scalar keys %{$allclusters{$model_name}{members}} == 1) {
            delete $allclusters{$model_name};
        } else {
            # If it is not a singleton, we add the name of the model to store in the db
            print STDERR Dumper $allclusters{$model_name};
            $allclusters{$model_name}{model_name} = $model_name;
        }
    }
}

1;
