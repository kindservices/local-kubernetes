# just an alias for convenience - this will install kind, argo, and kube apply argo
install: getArgoPwd
# ensures docker is running
ensureDocker:
	source argo.sh && ensureDocker
# installs Kind
installKind: ensureDocker
	source argo.sh && installKind
# installs argo on k8s (assumes/uses kubectl)
installArgo: installKind
	source argo.sh && installArgo
kubeApplyArgo: installArgo
	source argo.sh && kubeApplyArgo
# captures the argo admin pwd in MY_ARGO_PWD
getArgoPwd: kubeApplyArgo
	source argo.sh && getArgoPwd

# login to argo. This isn't chained to any of the install stuff, as
# 1) we'll do this quite often and want it separate and fast, and
# 2) the install can take a bit to finish, and I didn't want to put in a bunch of
#    ugly sleep / wait junk
login: portForward 
	source argo.sh && login
# kubectl port-forward 8080 to argo 443
portForward:
	source argo.sh && portForward
deleteArgo:
	source argo.sh && deleteArgo
setPwd:
	source argo.sh && setPwd
installGuestbook: install
	source argo.sh && installGuestbook
getGuestbook: 
	source argo.sh && getGuestbook
syncGuestbook: 
	source argo.sh && syncGuestbook
# make setAutoSync APP=foo
setAutoSync:
	source argo.sh && setAutoSync
# beastMode is our cheeky term for all the unsafe dev settings, such as
# auto-deleting resources
# make setAutoSync APP=foo
beastMode:
	source argo.sh && beastMode
