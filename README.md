# color-block-gitops

The GitOps repo behind the live demo in *Commit to Production* (AWS Student Community Day).

Argo CD watches `k8s/` on `main`. Change the `COLOR` env var in [`k8s/deployment.yaml`](k8s/deployment.yaml),
push, and Argo CD rolls the new color out to every pod on Amazon EKS. Nothing else deploys to the cluster.

```
k8s/          what runs in the cluster (Deployment, Service, nginx template)
argocd/       the Argo CD Application (auto-sync, prune, self-heal)
infra/        Terraform: VPC, EKS, AWS Load Balancer Controller, Argo CD and this app
.github/      manifest validation on every push
```

## Try it yourself

Needs Terraform ≥ 1.6, the AWS CLI (logged in) and kubectl.

```bash
cd infra
terraform init
terraform apply            # VPC + EKS + Argo CD + this app, about 15–20 min
aws eks update-kubeconfig --name scd --region ap-south-1

# edit COLOR in k8s/deployment.yaml, commit, push, then watch:
kubectl -n demo get pods -w
terraform output -raw website_url | bash    # the website's public NLB URL
terraform output -raw argocd_url | bash     # Argo CD UI (self-signed cert; user admin)

terraform destroy          # deletes the NLBs first, then everything else (EKS bills by the hour)
```

Want to see self-heal? Change the cluster by hand and watch Argo CD put it back:

```bash
kubectl -n demo scale deploy/color-block --replicas=2
```

Rollback is `git revert`.
