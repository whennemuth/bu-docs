alias bye='eval `ssh-agent -k` && exit'

alias versions='cat pom.xml | grep -P "(<coeus\-api\-all\.version)|(<coeus\-s2sgen\.version)|(<rice\.version)|(<schemaspy\.version)|(<version>[a-zA-Z\d\.\-]+</version>)"'

alias bastion='source /c/whennemuth/documentation/bu/aws/ssh/bastion.sh'

alias up='cd ..'

alias upp='cd ../..'

alias uppp='cd ../../..'

alias bld='mvn clean compile source:jar javadoc:jar install -Dgrm.off=true'

alias blde='mvn clean compile source:jar javadoc:jar install -e -Dgrm.off=true'

alias bldo='mvn clean compile source:jar javadoc:jar install -Poracle -Dgrm.off=true'

alias taillog="logfile=\"$(eval 'sudo ls -lat /home/kc/kuali-logs/ | grep -P "localhost\." | head -1' | rev | cut -d' ' -f1 | rev)\"; eval 'sudo tail /home/kc/kuali-logs/$logfile -f -n 2000'"

alias cleanrmi='DANGLING=$(docker images --filter dangling=true -q); if [ -n "$DANGLING" ]; then docker rmi -f $DANGLING; else echo "No images to remove!"; fi'

alias cleanvol='DANGLING=$(docker volume ls -qf dangling=true); if [ -n "$DANGLING" ]; then docker volume rm $DANGLING; else echo "No volumes to remove!"; fi'

alias cleanall='cleanrmi && cleanvol'
