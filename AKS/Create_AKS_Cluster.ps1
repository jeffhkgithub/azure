$RGNAME="Your Resource Group"
$K8SVERSION="Recommend using N-2 version"
$CLUSTERNAME="AKS1"

az aks create -n $CLUSTERNAME -g $RGNAME '
--kubernetes-version $K8SVERSION '
--enable-managed-identity '
--generate-ssh-keys '
--node-count 3 '
--no-wait
