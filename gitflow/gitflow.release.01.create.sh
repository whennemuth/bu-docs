# Create the upstream, downstream and local repositories
cd "`dirname $0`"
sh -v gitflow.release.02.create.upstream.sh
sh -v gitflow.release.03.create.downstream.sh
sh -v gitflow.release.04.create.local.sh