# Argo
The makefile here serves as a kind of executable set of convenience functions for installing argo on k8s.

This assumes we've got a `kubectl` pointing at an exiting cluster.

See [readme](../README.md) to see how to create a k8s cluster locally or in the cloud.


The last step exposes the Argo API with a public IP so we can use the Argo CLI or UI. 

You can find the IP in:
 * Azure: in the Azure portal under ![Resource Group -> Your Kube Cluster -> Services and Ingresses](../docs/img/servicesAndIngress.png)
 * AWS: *TODO*
 * GCP: *TODO*


Note, instead of patching the LoadBalancer, you can set up argo using [this ingress controller](./ingress/README.md)


### 1) Connect Argo with your github repository
Next we'll connect Argo with our GitHub repository.

(We'll use the Argo UI, though could equally use the argo command-line)

To do this, we'll create a new key pair, adding the public key to github and the private key to argo CD.

See [github instructions](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account), which is basically:
- run `ssh-keygen -t ed25519 -C your@email.com`
- copy the public key (e.g. `pbcopy < id_rsa_ed25519.pub`) and add that to your github account

Now capture the *private* key for Argo:
```
pbcopy < id_rsa_ed25519
```

With this *private* key in hand, use the Argo UI, go to *Settings* (the cog item on the left), select *Repositories*, then select *CONNECT REPO USING SSH* (button top left) and follow the instructions:
![add repo](./docs/img/argoUIConnectUsingSSH.jpg)

You will need to copy the *private* key from the id_rsa file we created earlier and specify the "*.git" ssh URL for our repository:
![add repo](./docs/img/argoAddRepository.png)

Which should successfully connect:
![connected](./docs/img/argoConnectedRepo.png)

We're now ready to add some applications!!

### 2) Create a new kubernetes application from the repo

We'll now create a new kubernetes application from our repository (which, for this tutorial, is THIS repository).

Note:
If we wanted to, we could use our own image from our own container registry, as if created from our CI pipeline. See faking continuous integration [here](./docs/fakingContinousIntegration.md)

Our kubernetes application is in our [helloworld](helloworld) directory for this application, so we'll use that *path*.

We'll use the ArgoCD command line (log in using `argocd login [ID]` with 'admin' user and our $ARGO_PWD password)

The command for creating a new application called "helloworld" (the application name must be lowercase) which watches the 'helloworld' path is:
```
argocd app create helloworld \
  --repo git@github.com:nimbleapproach/argo-demo.git \
  --path helloworld \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace default \
  --sync-policy auto
```

We can check the state of our app within the UI or with `argocd app get helloworld`

There should also be a new workload in our AKS cluster in Portal named *helloworld*

If you used the image as above hopefully it is showing as LoadBalancer with a public IP (for testing purposes) with *Services and Ingresses* in Portal, clicking on it should open the helloworld page. 
If there isn't a load balancer we can patch it as we did for the argo server

We can now do things like change the number of replicas in the deployment yaml and see the app is out of sync if we do `argocd app get helloworld` or in the UI, if we are syncing manually you can then do `argocd app sync helloworld` or use the button in the UI, you would hopefully then see this change reflected in Portal.

Note this is one of many, many ways to deploy via Argo (helm charts etc.) that aren't explored here!

### 3) Add github webhook for Argo
Argo will check the repository it is attached to every 3 minutes. If we want it to sync in a more timely manner, then we will need to configure a webhook on the repository feeding Argo. 
The instructions to do so are [here](https://argo-cd.readthedocs.io/en/stable/operator-manual/webhook/) 



[back](./README.md)