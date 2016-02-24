cd "`dirname $0`"
sh gitflow.release.01.create.sh
sh gitflow.release.05.update.sh
sh -v gitflow.release.08.advance.upstream.sh
sh -v gitflow.release.09.merge.upstream.sh